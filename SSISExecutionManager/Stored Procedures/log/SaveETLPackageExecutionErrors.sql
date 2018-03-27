﻿CREATE PROCEDURE [log].SaveETLPackageExecutionErrors @ETLBatchExecutionId              INT,
                                                     @ErrorsRequiringNotificationCount INT OUT,
                                                     @ETLPackagesRequiringRestartCount INT OUT
AS
    --Insert unexpected terminations
    INSERT INTO [log].ETLPackageExecutionError
                ([SSISDBExecutionId]
                 ,[SSISDBEventMessageId]
                 ,[ETLBatchExecutionId]
				 ,[ETLPackageGroupId]
                 ,[ETLPackageId]
                 ,[ErrorDateTime]
                 ,[ErrorMessage]
                 ,[ETLPackageExecutionErrorTypeId])
    SELECT
      e.execution_id             AS [SSISDBExecutionId]
      ,NULL                      AS [SSISDBEventMessageId]
      ,ebe.[ETLBatchExecutionId] AS [ETLBatchExecutionId]
	  ,ebe.ETLPackageGroupId	 AS [ETLPackageGroupId]
      ,p.ETLPackageId            AS [ETLPackageId]
      ,e.end_time                AS [ErrorDateTime]
      ,'Unexpected termination'  AS [ErrorMessage]
      ,2                         AS [ETLPackageExecutionErrorTypeId] --Unexpected termination	 
    FROM
      [$(SSISDB)].[catalog].[executions] e
      JOIN ctl.ETLBatchSSISDBExecutions ebe
        ON e.execution_id = ebe.SSISDBExecutionId
      JOIN [cfg].ETLPackage p
        ON e.folder_name = p.SSISDBFolderName
           AND e.project_name = p.SSISDBProjectName
           AND e.package_name = p.SSISDBPackageName
    WHERE
      ebe.[ETLBatchExecutionId] = @ETLBatchExecutionId
      AND [status] = 6
      AND p.ETLPackageId NOT IN (SELECT
                                   ETLPackageId
                                 FROM
                                   [log].ETLPackageExecutionError
                                 WHERE
                                  ETLPackageExecutionErrorTypeId = 2
                                  AND [ETLBatchExecutionId] = @ETLBatchExecutionId);

    --Insert or update packages stats based on SSISDB errors
    MERGE [log].ETLPackageExecutionError AS Target
    USING (SELECT
             err.[SSISDBExecutionId]
             ,err.[EventMessageId]
             ,err.[ETLBatchExecutionId]
			 ,err.[ETLPackageGroupId]
             ,err.[ETLPackageId]
             ,err.[ErrorDateTime]
             ,err.[ErrorMessage]
             ,1 AS [ETLPackageExecutionErrorTypeId] --SSISDB
           FROM
             dbo.[func_GetETLPackageExecutionErrorsForBatchExecution](@ETLBatchExecutionId) err) AS source ([SSISDBExecutionId], [SSISDBEventMessageId], [ETLBatchExecutionId], [ETLPackageGroupId], [ETLPackageId], [ErrorDateTime], [ErrorMessage], [ETLPackageExecutionErrorTypeId])
    ON target.[SSISDBEventMessageId] = source.[SSISDBEventMessageId]
       AND target.ETLPackageId = source.ETLPackageId
    WHEN Matched THEN
      UPDATE SET [SSISDBExecutionId] = source.[SSISDBExecutionId]
                 ,[SSISDBEventMessageId] = source.[SSISDBEventMessageId]
                 ,[ETLBatchExecutionId] = source.[ETLBatchExecutionId]
				 ,[ETLPackageGroupId] = source.[ETLPackageGroupId]
                 ,[ETLPackageId] = source.ETLPackageId
                 ,[ErrorDateTime] = source.[ErrorDateTime]
                 ,[ErrorMessage] = source.[ErrorMessage]
                 ,[ETLPackageExecutionErrorTypeId] = source.[ETLPackageExecutionErrorTypeId]
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT ([SSISDBExecutionId]
              ,[SSISDBEventMessageId]
              ,[ETLBatchExecutionId]
			  ,[ETLPackageGroupId]
              ,[ETLPackageId]
              ,[ErrorDateTime]
              ,[ErrorMessage]
              ,[ETLPackageExecutionErrorTypeId])
      VALUES(source.[SSISDBExecutionId]
             ,source.[SSISDBEventMessageId]
             ,source.[ETLBatchExecutionId]
			 ,source.[ETLPackageGroupId]
             ,source.ETLPackageId
             ,source.[ErrorDateTime]
             ,source.[ErrorMessage]
             ,source.[ETLPackageExecutionErrorTypeId]);

    --If a package that has a failure logged is still in a failed state then mark it as Ready For Execution and decrease the Remaining Retry Attempts by one
    --ToDo: make this sql statement more straightforward
    UPDATE pepgep
    SET    [RemainingRetryAttemptsDefault] = IIF(IIF(pp.ETLPackageId IS NOT NULL, pepgep.[RemainingRetryAttemptsDefault], epgep.[RemainingRetryAttemptsDefault]) > 0, IIF(pp.ETLPackageId IS NOT NULL, pepgep.[RemainingRetryAttemptsDefault], epgep.[RemainingRetryAttemptsDefault]) - 1, 0)
           ,ReadyForExecutionInd = IIF(IIF(pp.ETLPackageId IS NOT NULL, pepgep.[RemainingRetryAttemptsDefault], epgep.[RemainingRetryAttemptsDefault]) - 1 > 0, 1, 0)
    FROM   [log].[ETLPackageExecutionError] e
           JOIN [cfg].ETLPackageGroup_ETLPackage epgep
             ON e.ETLPackageId = epgep.ETLPackageId
                AND e.ETLPackageGroupId = epgep.ETLPackageGroupId
           JOIN [cfg].ETLPackage p
             ON epgep.ETLPackageId = p.ETLPackageId
           CROSS APPLY [dbo].[func_GetETLPackageExecutionStatusesFromSSISDB] (e.SSISDBExecutionId) s
           LEFT JOIN [cfg].ETLPackage pp
                  ON p.EntryPointETLPackageId = pp.ETLPackageId
           JOIN [cfg].ETLPackageGroup_ETLPackage pepgep
             ON pepgep.ETLPackageId = ISNULL(pp.ETLPackageId, p.ETLPackageId)
                AND e.ETLPackageGroupId = pepgep.ETLPackageGroupId
    WHERE
      ETLBatchExecutionId = @ETLBatchExecutionId
      AND epgep.[RemainingRetryAttemptsDefault] > 0
      AND pepgep.ETLPackageId = ISNULL(pp.ETLPackageId, s.ETLPackageId)
      AND s.ETLPackageExecutionStatusId = 1
	  AND [dbo].[func_IsETLPackageRunning] (p.SSISDBFolderName, p.SSISDBProjectName, p.SSISDBPackageName) = 0;

    SET @ErrorsRequiringNotificationCount = (SELECT
                                               COUNT(*)
                                             FROM
                                               [log].ETLPackageExecutionError
                                             WHERE
                                              EmailNotificationSentDateTime IS NULL
                                              AND [ETLBatchExecutionId] = @ETLBatchExecutionId)
    SET @ETLPackagesRequiringRestartCount = (SELECT
                                               COUNT(*)
                                             FROM
                                               [log].ETLPackageExecutionError
                                             WHERE
                                              ETLPackageRestartDateTime IS NULL
                                              AND [ETLBatchExecutionId] = @ETLBatchExecutionId)

    RETURN 0 
