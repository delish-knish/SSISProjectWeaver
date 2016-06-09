CREATE FUNCTION [dbo].[func_GetETLPackageExecutionErrorsForBatch] (@ETLBatchId INT)
RETURNS TABLE
AS
    RETURN
      (SELECT
         ebe.[ETLBatchId]                                AS [ETLBatchId]
         ,ISNULL(err.[ETLPackageId], ebe.[ETLPackageId]) AS [ETLPackageId]
         ,ebe.[SSISDBExecutionId]                        AS [SSISDBExecutionId]
         ,err.[EventMessageId]                           AS [EventMessageId]
         ,err.[ErrorDateTime]                            AS [ErrorDateTime]
         ,err.[ErrorMessage]                             AS [ErrorMessage]
       FROM
         ctl.ETLBatchSSISDBExecutions ebe
         CROSS APPLY dbo.func_GetETLPackageExecutionErrorsFromSSISDB(ebe.SSISDBExecutionId) err
       WHERE
        ebe.ETLBatchId = @ETLBatchId) 
