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
                 ,epgep.ETLPackageGroupId
                 ,epgep.ReadyForExecutionInd
                 ,epgep.[IgnoreForBatchCompleteDefaultInd]
                 ,ISNULL(exe.ExecutionId, em.ExecutionId) AS ExecutionId --Executables aren't logged until complete so if none found, check the event_messages table.
               FROM
                 [ctl].[ETLBatchExecution] eb
                 JOIN [cfg].[ETLBatch_ETLPackageGroup] epeps
                   ON eb.[ETLBatchId] = epeps.[ETLBatchId]
                 JOIN [cfg].[ETLPackageGroup_ETLPackage] epgep
                   ON epeps.ETLPackageGroupId = epgep.ETLPackageGroupId
                 JOIN [cfg].ETLPackage ep
                   ON epgep.ETLPackageId = ep.ETLPackageId
                 OUTER APPLY (SELECT TOP 1
                                e.execution_id AS ExecutionId
                              FROM
                                [$(SSISDB)].catalog.executables e
                                INNER JOIN (SELECT
                                              [ETLBatchExecutionId]
                                              ,ETLPackageId
                                              ,MAX(SSISDBExecutionId) AS SSISDBExecutionId
                                            FROM
                                              ctl.ETLBatchSSISDBExecutions
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
                                   ctl.ETLBatchSSISDBExecutions a
                                   JOIN [cfg].ETLPackage b
                                     ON a.ETLPackageId = b.ETLPackageId
                                 WHERE
                                  [ETLBatchExecutionId] = @ETLBatchExecutionId
                                  AND ep.SSISDBPackageName = b.SSISDBPackageName
                                 GROUP  BY
                                  [ETLBatchExecutionId]
                                  ,a.ETLPackageId) ebse
                                INNER JOIN [$(SSISDB)].internal.event_messages em
                                        ON ebse.SSISDBExecutionId = em.operation_id
                              ORDER  BY
                               ExecutionId DESC) em
               WHERE
                eb.ETLBatchExecutionId = @ETLBatchExecutionId
                AND epgep.EnabledInd = 1
                AND epeps.EnabledInd = 1
                AND ( ExecuteSundayInd = Iif(eb.DayOfWeekName = 'Sunday', 1, NULL)
                       OR ExecuteMondayInd = Iif(eb.DayOfWeekName = 'Monday', 1, NULL)
                       OR ExecuteTuesdayInd = Iif(eb.DayOfWeekName = 'Tuesday', 1, NULL)
                       OR ExecuteWednesdayInd = Iif(eb.DayOfWeekName = 'Wednesday', 1, NULL)
                       OR ExecuteThursdayInd = Iif(eb.DayOfWeekName = 'Thursday', 1, NULL)
                       OR ExecuteFridayInd = Iif(eb.DayOfWeekName = 'Friday', 1, NULL)
                       OR ExecuteSaturdayInd = Iif(eb.DayOfWeekName = 'Saturday', 1, NULL) )
                AND ( DAY(eb.StartDateTime) = epgep.ExecuteNDayOfMonth
                       OR epgep.ExecuteNDayOfMonth = 0 ))
      SELECT
         pkg.ETLBatchId                           AS ETLBatchId
         ,pkg.ETLPackageId                        AS ETLPackageId
         ,pkg.ETLPackageGroupId
         ,pkg.ReadyForExecutionInd                AS ReadyForExecutionInd
         ,pes.StartDateTime                       AS StartDateTime
         ,pes.EndDateTime                         AS EndDateTime
         ,pes.ETLExecutionStatusId                AS ETLExecutionStatusId
         ,pes.SSISDBExecutionId                   AS SSISDBExecutionId
         ,pes.MissingSSISDBExecutablesEntryInd    AS MissingSSISDBExecutablesEntryInd
         ,pkg.[IgnoreForBatchCompleteDefaultInd]  AS IgnoreForBatchCompleteInd
         ,CASE
            WHEN pes.ETLPackageExecutionStatusId = 0 THEN 0 --Succeeded make this first case so that other scenarios don't override it
            WHEN epd.DependenciesNotMetCount > 0
                  OR pepd.DependenciesNotMetCount > 0
                  OR pg.DependenciesNotMetCount > 0 THEN 6 --waiting on dependencies
            WHEN pesprnt.ETLPackageExecutionStatusId = 5
                 AND pes.ETLPackageExecutionStatusId IS NULL THEN 10 --Waiting to be called by Parent (the parent is running but the child is not)
            WHEN ( epd.DependenciesNotMetCount = 0
                   AND pes.ETLPackageExecutionStatusId IS NULL )
                  OR ( pepd.DependenciesNotMetCount = 0
                       AND pes.ETLPackageExecutionStatusId IS NULL ) THEN 8 --ready to execute
            WHEN pesprnt.ETLPackageExecutionStatusId = 1
                 AND pes.ETLPackageExecutionStatusId IS NULL THEN 11
            ELSE Isnull(pes.ETLPackageExecutionStatusId, 7)
          END                                     AS ETLPackageExecutionStatusId
         ,Isnull(epd.DependenciesNotMetCount, 0)
          + Isnull(pepd.DependenciesNotMetCount, 0)
          + Isnull(pg.DependenciesNotMetCount, 0) AS DependenciesNotMetCount
       FROM
         pkg
         OUTER APPLY dbo.func_GetETLPackageExecutionStatusesFromSSISDB(pkg.ExecutionId) pes
         LEFT JOIN pkg prnt
                ON pkg.EntryPointETLPackageId = prnt.ETLPackageId
         OUTER APPLY dbo.func_GetETLPackageExecutionStatusesFromSSISDB(prnt.ExecutionId) pesprnt
         LEFT JOIN (SELECT
                      d.ETLPackageId
                      ,SUM(Iif(Isnull(pesbep.ETLPackageExecutionStatusId, -1) NOT IN ( 0, 2 ), 1, 0)) AS DependenciesNotMetCount
                    FROM
                      [cfg].[ETLPackage_ETLPackageDependency] d
                      JOIN pkg bep
                        ON d.DependedOnETLPackageId = bep.ETLPackageId
                      OUTER APPLY dbo.func_GetETLPackageExecutionStatusesFromSSISDB(bep.ExecutionId) pesbep
                    GROUP  BY
                     d.ETLPackageId) epd
                ON pkg.ETLPackageId = epd.ETLPackageId
         LEFT JOIN (SELECT
                      d.ETLPackageId
                      ,SUM(Iif(Isnull(pesbep.ETLPackageExecutionStatusId, -1) NOT IN ( 0, 2 ), 1, 0)) AS DependenciesNotMetCount
                    FROM
                      [cfg].[ETLPackage_ETLPackageDependency] d
                      JOIN pkg bep
                        ON d.DependedOnETLPackageId = bep.ETLPackageId
                      OUTER APPLY dbo.func_GetETLPackageExecutionStatusesFromSSISDB(bep.ExecutionId) pesbep
                    GROUP  BY
                     d.ETLPackageId) pepd
                ON prnt.ETLPackageId = pepd.ETLPackageId
         LEFT JOIN (SELECT
                      ep.ETLPackageId
                      ,bbg.ETLBatchId
                      ,SUM(Iif(Isnull(pesbep.ETLPackageExecutionStatusId, -1) NOT IN ( 0, 2 ), 1, 0)) AS DependenciesNotMetCount
                    FROM
                      [cfg].ETLPackage ep
                      JOIN [cfg].ETLPackageGroup_ETLPackage bg
                        ON ep.ETLPackageId = bg.ETLPackageId
                      JOIN [cfg].ETLPackageGroup epg
                        ON bg.ETLPackageGroupId = epg.ETLPackageGroupId
                      JOIN [cfg].ETLBatch_ETLPackageGroup bbg
                        ON epg.ETLPackageGroupId = bbg.ETLPackageGroupId
                      JOIN [cfg].ETLPackageGroup_ETLPackageGroupDependency bgd
                        ON epg.ETLPackageGroupId = bgd.ETLPackageGroupId
                      JOIN [cfg].ETLPackageGroup epgd
                        ON bgd.DependedOnETLPackageGroupId = epgd.ETLPackageGroupId
                      JOIN [cfg].ETLPackageGroup_ETLPackage pgepd
                        ON epgd.ETLPackageGroupId = pgepd.ETLPackageGroupId
                      JOIN [pkg] bep
                        ON pgepd.ETLPackageId = bep.ETLPackageId
                      OUTER APPLY dbo.func_GetETLPackageExecutionStatusesFromSSISDB(bep.ExecutionId) pesbep
                    GROUP  BY
                     ep.ETLPackageId
                     ,bbg.ETLBatchId) pg
                ON pkg.ETLPackageId = pg.ETLPackageId
                   AND pkg.ETLBatchId = pg.ETLBatchId
       WHERE
        ( pes.ETLPackageId = pkg.ETLPackageId
           OR pes.ETLPackageId IS NULL )
        AND ( pesprnt.ETLPackageId = prnt.ETLPackageId
               OR pesprnt.ETLPackageId IS NULL )) 
