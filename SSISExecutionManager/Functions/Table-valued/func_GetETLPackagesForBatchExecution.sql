CREATE FUNCTION [dbo].[func_GetETLPackagesForBatchExecution] (@ETLBatchExecutionId INT)
RETURNS TABLE
AS
    --This TVF is intended to return all packages that are part of the batch, not just entry-point packages.
    RETURN (
      WITH pkg
           AS (SELECT
                 eb.ETLBatchId
                ,eb.ETLBatchStatusId
                ,ep.ETLPackageId
                ,ep.EntryPointETLPackageId
                ,pes.StartDateTime
                ,pes.EndDateTime
                ,pes.ETLExecutionStatusId
                ,pes.ETLPackageExecutionStatusId
                ,pes.SSISDBExecutionId
                ,pes.MissingSSISDBExecutablesEntryInd
				,ebpspep.IgnoreForBatchCompleteInd
               FROM
                 [ctl].[ETLBatchExecution] eb WITH (NOLOCK)
                 JOIN ctl.[ETLBatch_ETLPackageGroup] epeps WITH (NOLOCK)
                   ON eb.[ETLBatchId] = epeps.[ETLBatchId]
                 JOIN ctl.[ETLPackageGroup_ETLPackage] ebpspep WITH (NOLOCK)
                   ON epeps.ETLPackageGroupId = ebpspep.ETLPackageGroupId
                 JOIN [ctl].ETLPackage ep WITH (NOLOCK)
                   ON ebpspep.ETLPackageId = ep.ETLPackageId
                 OUTER APPLY (SELECT TOP 1
                                e.execution_id AS ExecutionId
                              FROM
                                [$(SSISDB)].catalog.executables e WITH (NOLOCK)
                                INNER JOIN (SELECT
                                              [ETLBatchExecutionId]
                                             ,ETLPackageId
                                             ,MAX(SSISDBExecutionId) AS SSISDBExecutionId
                                            FROM
                                              ctl.ETLBatchSSISDBExecutions WITH (NOLOCK)
                                            WHERE
                                             [ETLBatchExecutionId] = @ETLBatchExecutionId
                                            GROUP  BY
                                             [ETLBatchExecutionId]
                                             ,ETLPackageId) ebse
                                        ON e.execution_id = ebse.SSISDBExecutionId
                              WHERE
                               ep.SSISDBPackageName = e.package_name
                               AND e.package_path = '\Package'
                              ORDER  BY
                               ExecutionId DESC) exe
                 OUTER APPLY (SELECT TOP 1
                                em.operation_id AS ExecutionId
                              FROM
                                (SELECT
                                   [ETLBatchExecutionId]
                                  ,a.ETLPackageId
                                  ,MAX(SSISDBExecutionId) AS SSISDBExecutionId
                                 FROM
                                   ctl.ETLBatchSSISDBExecutions a WITH (NOLOCK)
                                   JOIN ctl.ETLPackage b
                                     ON a.ETLPackageId = b.ETLPackageId
                                 WHERE
                                  [ETLBatchExecutionId] = @ETLBatchExecutionId
                                  AND ep.SSISDBPackageName = b.SSISDBPackageName
                                 GROUP  BY
                                  [ETLBatchExecutionId]
                                  ,a.ETLPackageId) ebse
                                INNER JOIN [$(SSISDB)].internal.event_messages em WITH (NOLOCK)
                                        ON ebse.SSISDBExecutionId = em.operation_id
                              ORDER  BY
                               ExecutionId DESC) em
				 --Executables aren't logged until complete so if none found, check the event_messages table.
                 OUTER APPLY dbo.func_GetETLPackageExecutionStatusesFromSSISDB(ISNULL(exe.ExecutionId, em.ExecutionId)) pes
               WHERE
                eb.ETLBatchExecutionId = @ETLBatchExecutionId
				AND ep.EnabledInd = 1
				AND ebpspep.EnabledInd = 1
				AND epeps.EnabledInd = 1
                AND (pes.ETLPackageId = ep.ETLPackageId
                      OR pes.ETLPackageId IS NULL)
                
                AND (ExecuteSundayInd = Iif(eb.DayOfWeekName = 'Sunday', 1, NULL)
                      OR ExecuteMondayInd = Iif(eb.DayOfWeekName = 'Monday', 1, NULL)
                      OR ExecuteTuesdayInd = Iif(eb.DayOfWeekName = 'Tuesday', 1, NULL)
                      OR ExecuteWednesdayInd = Iif(eb.DayOfWeekName = 'Wednesday', 1, NULL)
                      OR ExecuteThursdayInd = Iif(eb.DayOfWeekName = 'Thursday', 1, NULL)
                      OR ExecuteFridayInd = Iif(eb.DayOfWeekName = 'Friday', 1, NULL)
                      OR ExecuteSaturdayInd = Iif(eb.DayOfWeekName = 'Saturday', 1, NULL))) --select * from pkg
      SELECT
         pkg.ETLBatchId                           AS ETLBatchId
        ,pkg.ETLPackageId                         AS ETLPackageId
        ,pkg.StartDateTime                        AS StartDateTime
        ,pkg.EndDateTime                          AS EndDateTime
        ,pkg.ETLExecutionStatusId                 AS ETLExecutionStatusId
        ,pkg.SSISDBExecutionId                    AS SSISDBExecutionId
        ,pkg.MissingSSISDBExecutablesEntryInd     AS MissingSSISDBExecutablesEntryInd
		,pkg.IgnoreForBatchCompleteInd			  AS IgnoreForBatchCompleteInd
        ,CASE
            WHEN pkg.ETLPackageExecutionStatusId = 0 THEN 0 --Succeeded make this first case so that other scenarios don't override it
            WHEN epd.DependenciesNotMetCount > 0
                  OR pepd.DependenciesNotMetCount > 0
                  OR pg.DependenciesNotMetCount > 0 THEN 6 --waiting on dependencies
            WHEN prnt.ETLPackageExecutionStatusId = 5
                 AND pkg.ETLPackageExecutionStatusId IS NULL THEN 10 --Waiting to be called by Parent (the parent is running but the child is not)
            WHEN (epd.DependenciesNotMetCount = 0
                  AND pkg.ETLPackageExecutionStatusId IS NULL)
                  OR (pepd.DependenciesNotMetCount = 0
                      AND pkg.ETLPackageExecutionStatusId IS NULL) THEN 8 --ready to execute
            WHEN prnt.ETLPackageExecutionStatusId = 1
                 AND pkg.ETLPackageExecutionStatusId IS NULL THEN 11
            ELSE Isnull(pkg.ETLPackageExecutionStatusId, 7)
          END                                     AS ETLPackageExecutionStatusId
        ,Isnull(epd.DependenciesNotMetCount, 0) + Isnull(pepd.DependenciesNotMetCount, 0)
          + Isnull(pg.DependenciesNotMetCount, 0) AS DependenciesNotMetCount
       FROM
         pkg
         LEFT JOIN pkg prnt
                ON pkg.EntryPointETLPackageId = prnt.ETLPackageId
         LEFT JOIN (SELECT
                      d.ETLPackageId
                     ,SUM(Iif(Isnull(bep.ETLPackageExecutionStatusId, -1) NOT IN (0, 2), 1, 0)) AS DependenciesNotMetCount
                    FROM
                      [ctl].[ETLPackage_ETLPackageDependency] d WITH (NOLOCK)
                      JOIN pkg bep
                        ON d.DependedOnETLPackageId = bep.ETLPackageId
                    GROUP  BY
                     d.ETLPackageId) epd
                ON pkg.ETLPackageId = epd.ETLPackageId
         LEFT JOIN (SELECT
                      d.ETLPackageId
                     ,SUM(Iif(Isnull(bep.ETLPackageExecutionStatusId, -1) NOT IN (0, 2), 1, 0)) AS DependenciesNotMetCount
                    FROM
                      [ctl].[ETLPackage_ETLPackageDependency] d WITH (NOLOCK)
                      JOIN pkg bep
                        ON d.DependedOnETLPackageId = bep.ETLPackageId
                    GROUP  BY
                     d.ETLPackageId) pepd
                ON prnt.ETLPackageId = pepd.ETLPackageId
         LEFT JOIN (SELECT
                           ep.ETLPackageId
                          ,bbg.ETLBatchId
                          ,SUM(Iif(Isnull(bep.ETLPackageExecutionStatusId, -1) NOT IN (0, 2), 1, 0)) AS DependenciesNotMetCount
                         FROM
                           ctl.ETLPackage ep
                           JOIN [ctl].ETLPackageGroup_ETLPackage bg
                             ON ep.ETLPackageId = bg.ETLPackageId
                           JOIN [ctl].ETLPackageGroup epg
                             ON bg.ETLPackageGroupId = epg.ETLPackageGroupId
                           JOIN [ctl].ETLBatch_ETLPackageGroup bbg
                             ON epg.ETLPackageGroupId = bbg.ETLPackageGroupId
                           JOIN [ctl].ETLPackageGroup_ETLPackageGroupDependency bgd
                             ON epg.ETLPackageGroupId = bgd.ETLPackageGroupId
                           JOIN [ctl].ETLPackageGroup epgd
                             ON bgd.DependedOnETLPackageGroupId = epgd.ETLPackageGroupId
                           JOIN [ctl].ETLPackageGroup_ETLPackage pgepd
                             ON epgd.ETLPackageGroupId = pgepd.ETLPackageGroupId
                           JOIN [pkg] bep
                             ON pgepd.ETLPackageId = bep.ETLPackageId
                         GROUP  BY
                          ep.ETLPackageId
                          ,bbg.ETLBatchId) pg
                     ON pkg.ETLPackageId = pg.ETLPackageId
                        AND pkg.ETLBatchId = pg.ETLBatchId) 
