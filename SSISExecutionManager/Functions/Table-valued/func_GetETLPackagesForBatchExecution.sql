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
                 --,pes.ETLPackageFirstErrorMessage
                 --,pes.ETLPackageLastMessage
                 ,pes.SSISDBExecutionId
                 ,pes.MissingSSISDBExecutablesEntryInd
				 ,bp.PhaseExecutionOrderNo
               FROM
                 [ctl].ETLPackage ep WITH (NOLOCK)
                 CROSS JOIN (SELECT
                               [ETLBatchId]
                               ,DayOfWeekName
                               ,StartDateTime
                               ,EndDateTime
                               ,ETLBatchStatusId
                             FROM
                               [ctl].[ETLBatchExecution] WITH (NOLOCK)
                             WHERE
                              [ETLBatchExecutionId] = @ETLBatchExecutionId) eb
				JOIN (SELECT 
							epeps.[ETLBatchId]
							,ebpspep.ETLPackageId
							,epeps.PhaseExecutionOrderNo
						FROM
							ctl.[ETLBatchPhase_ETLPackage] ebpspep 
							JOIN ctl.[ETLBatch_ETLBatchPhase] epeps
								ON ebpspep.[ETLBatchPhaseId] = epeps.ETLBatchPhaseId
						WHERE
							ebpspep.EnabledInd = 1) bp ON
						ep.ETLPackageId = bp.ETLPackageId
						AND eb.[ETLBatchId] = bp.[ETLBatchId]
                 --Get the last execution id of the package during the batch. Executables aren't logged until complete so if none found, check the event_messages table.
                 OUTER APPLY (SELECT TOP 1
                                *
                              FROM
                                (SELECT TOP 1
                                   e.execution_id AS ExecutionId
                                   ,1             AS PriorityRank
                                 FROM
                                   [$(SSISDB)].catalog.executables e WITH (NOLOCK)
                                   JOIN [$(SSISDB)].catalog.executable_statistics es WITH (NOLOCK)
                                     ON e.executable_id = es.executable_id
                                        AND e.execution_id = es.execution_id
                                   JOIN (SELECT
                                           [ETLBatchExecutionId]
                                           ,ETLPackageId
                                           ,MAX(SSISDBExecutionId) AS SSISDBExecutionId
                                         FROM
                                           ctl.ETLBatchSSISDBExecutions WITH (NOLOCK)
                                         GROUP  BY
                                          [ETLBatchExecutionId]
                                          ,ETLPackageId) ebse
                                     ON e.execution_id = ebse.SSISDBExecutionId
                                 WHERE
                                   ep.SSISDBPackageName = e.package_name
                                   AND e.package_path = '\Package'
                                   AND ebse.[ETLBatchExecutionId] = @ETLBatchExecutionId

                                 UNION ALL
                                 SELECT TOP 1
                                   em.operation_id AS ExecutionId
                                   ,2              AS PriorityRank
                                 FROM
                                   [$(SSISDB)].catalog.event_messages em WITH (NOLOCK)
                                   JOIN (SELECT
                                           [ETLBatchExecutionId]
                                           ,ETLPackageId
                                           ,MAX(SSISDBExecutionId) AS SSISDBExecutionId
                                         FROM
                                           ctl.ETLBatchSSISDBExecutions WITH (NOLOCK)
                                         GROUP  BY
                                          [ETLBatchExecutionId]
                                          ,ETLPackageId) ebse
                                     ON em.operation_id = ebse.SSISDBExecutionId
                                 WHERE
                                   ep.SSISDBPackageName = em.package_name
                                   AND ebse.[ETLBatchExecutionId] = @ETLBatchExecutionId
                                 ORDER  BY
                                   PriorityRank ASC
                                   ,ExecutionId DESC) t) ex
                 OUTER APPLY dbo.func_GetETLPackageExecutionStatusesFromSSISDB(ex.ExecutionId) pes
               WHERE
                ( pes.ETLPackageId = ep.ETLPackageId
                   OR pes.ETLPackageId IS NULL )
                AND ep.EnabledInd = 1
                AND (  ExecuteSundayInd = IIF(eb.DayOfWeekName = 'Sunday', 1, NULL)
					   OR  ExecuteMondayInd = IIF(eb.DayOfWeekName = 'Monday', 1, NULL)
                       OR  ExecuteTuesdayInd = IIF(eb.DayOfWeekName = 'Tuesday', 1, NULL)
                       OR  ExecuteWednesdayInd = IIF(eb.DayOfWeekName = 'Wednesday', 1, NULL)
                       OR  ExecuteThursdayInd = IIF(eb.DayOfWeekName = 'Thursday', 1, NULL)
                       OR  ExecuteFridayInd = IIF(eb.DayOfWeekName = 'Friday', 1, NULL)
                       OR  ExecuteSaturdayInd = IIF(eb.DayOfWeekName = 'Saturday', 1, NULL)))
      SELECT
         pkg.ETLBatchId							 AS ETLBatchId
		 ,pkg.PhaseExecutionOrderNo			     AS PhaseExecutionOrderNo
		 ,pkg.ETLPackageId                       AS ETLPackageId
         ,pkg.StartDateTime                      AS StartDateTime
         ,pkg.EndDateTime                        AS EndDateTime
         ,pkg.ETLExecutionStatusId               AS ETLExecutionStatusId
         --,pkg.ETLPackageFirstErrorMessage        AS ETLPackageFirstErrorMessage
         --,pkg.ETLPackageLastMessage              AS ETLPackageLastMessage
         ,pkg.SSISDBExecutionId                  AS SSISDBExecutionId
         ,pkg.MissingSSISDBExecutablesEntryInd   AS MissingSSISDBExecutablesEntryInd
         ,CASE
            WHEN pkg.ETLPackageExecutionStatusId = 0 THEN 0 --Succeeded make this first case so that other scenarios don't override it
            WHEN epd.DependenciesNotMetCount > 0
                  OR pepd.DependenciesNotMetCount > 0 THEN 6 --waiting on dependencies
            WHEN prnt.ETLPackageExecutionStatusId = 5
                 AND pkg.ETLPackageExecutionStatusId IS NULL THEN 10 --Waiting to be called by Parent (the parent is running but the child is not)
            WHEN ( epd.DependenciesNotMetCount = 0
                   AND pkg.ETLPackageExecutionStatusId IS NULL )
                  OR ( pepd.DependenciesNotMetCount = 0
                       AND pkg.ETLPackageExecutionStatusId IS NULL ) THEN 8 --ready to execute

            WHEN prnt.ETLPackageExecutionStatusId = 1
                 AND pkg.ETLPackageExecutionStatusId IS NULL THEN 11
            ELSE ISNULL(pkg.ETLPackageExecutionStatusId, 7)
          END                                    AS ETLPackageExecutionStatusId
         ,ISNULL(epd.TotalDependencyCount, 0)    AS TotalDependencyCount
         ,ISNULL(epd.DependenciesMetCount, 0)    AS DependenciesMetCount
         ,ISNULL(epd.DependenciesNotMetCount, 0) AS DependenciesNotMetCount
         ,ISNULL(epd.DependenciesFailedCount, 0) AS DependenciesFailedCount
       FROM
         pkg
         LEFT JOIN pkg prnt
                ON pkg.EntryPointETLPackageId = prnt.ETLPackageId
         LEFT JOIN (SELECT
                      d.ETLPackageId
                      ,COUNT(DISTINCT d.DependedOnETLPackageId)                                    AS TotalDependencyCount
                      ,SUM(IIF(ISNULL(bep.ETLPackageExecutionStatusId, -1) IN ( 0, 2 ), 1, 0))     AS DependenciesMetCount
                      ,SUM(IIF(ISNULL(bep.ETLPackageExecutionStatusId, -1) NOT IN ( 0, 2 ), 1, 0)) AS DependenciesNotMetCount
                      ,SUM(IIF(ISNULL(bep.ETLPackageExecutionStatusId, -1) IN ( 1, 4 ), 1, 0))     AS DependenciesFailedCount
                    FROM
                      [ctl].[ETLPackage_ETLPackageDependency] d WITH (NOLOCK)
                      JOIN pkg bep
                        ON d.DependedOnETLPackageId = bep.ETLPackageId
                    GROUP  BY
                     d.ETLPackageId) epd
                ON pkg.ETLPackageId = epd.ETLPackageId
         LEFT JOIN (SELECT
                      d.ETLPackageId
                      ,COUNT(DISTINCT d.DependedOnETLPackageId)                                    AS TotalDependencyCount
                      ,SUM(IIF(ISNULL(bep.ETLPackageExecutionStatusId, -1) IN ( 0, 2 ), 1, 0))     AS DependenciesMetCount
                      ,SUM(IIF(ISNULL(bep.ETLPackageExecutionStatusId, -1) NOT IN ( 0, 2 ), 1, 0)) AS DependenciesNotMetCount
                      ,SUM(IIF(ISNULL(bep.ETLPackageExecutionStatusId, -1) IN ( 1, 4 ), 1, 0))     AS DependenciesFailedCount
                    FROM
                      [ctl].[ETLPackage_ETLPackageDependency] d WITH (NOLOCK)
                      JOIN pkg bep
                        ON d.DependedOnETLPackageId = bep.ETLPackageId
                    GROUP  BY
                     d.ETLPackageId) pepd
                ON prnt.ETLPackageId = pepd.ETLPackageId) 
