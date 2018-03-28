CREATE PROCEDURE [rpt].[GetETLPackageExecutionErrors] @ETLBatchExecutionId INT = NULL,
                                                      @SSISDBExecutionId   BIGINT = NULL
AS
    SELECT
      [ETLBatchExecutionId]
      ,[SSISDBExecutionId]
      ,[SSISDBProjectName]
      ,[SSISDBPackageName]
      ,[SSISDBEventMessageId]
      ,[ErrorDateTime]
      ,[ErrorMessage]
      ,[EmailNotificationSentDateTime]
      ,[ETLPackageRestartDateTime]
    FROM
      [rpt].[ETLPackageExecutionErrors] err
    WHERE
      ( [ETLBatchExecutionId] = @ETLBatchExecutionId
         OR @ETLBatchExecutionId IS NULL )
      AND ( [SSISDBExecutionId] = @SSISDBExecutionId
             OR @SSISDBExecutionId IS NULL )

    RETURN 0 
