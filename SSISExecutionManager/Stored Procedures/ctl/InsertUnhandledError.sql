CREATE PROCEDURE [ctl].[InsertUnhandledError] @ETLBatchId   INT,
                                              @ErrorMessage VARCHAR(MAX)
AS
    INSERT INTO [log].ETLPackageExecutionError
                ([SSISDBExecutionId]
                 ,[SSISDBEventMessageId]
                 ,[ETLBatchId]
                 ,[ETLPackageId]
                 ,[ErrorDateTime]
                 ,[ErrorMessage]
                 ,[ETLPackageExecutionErrorTypeId])
    SELECT
      NULL           AS [SSISDBExecutionId]
      ,NULL          AS [SSISDBEventMessageId]
      ,@ETLBatchId   AS [ETLBatchId]
      ,0             AS [ETLPackageId]
      ,GETDATE()     AS [ErrorDateTime]
      ,@ErrorMessage AS [ErrorMessage]
      ,3             AS [ETLPackageExecutionErrorTypeId] --Unhandled Exception	 

    RETURN 0 
