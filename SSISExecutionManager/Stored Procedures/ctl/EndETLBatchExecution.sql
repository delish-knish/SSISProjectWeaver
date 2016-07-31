CREATE PROCEDURE [ctl].[EndETLBatchExecution] @ETLBatchExecutionId	INT,
                                     @ETLBatchStatusId		INT
AS
    UPDATE ctl.[ETLBatchExecution]
    SET    ETLBatchStatusId = @ETLBatchStatusId
           ,EndDateTime = GETDATE()
           ,LastUpdatedDate = GETDATE()
           ,LastUpdatedUser = SUSER_SNAME()
    WHERE
      [ETLBatchExecutionId] = @ETLBatchExecutionId

    RETURN 0 
