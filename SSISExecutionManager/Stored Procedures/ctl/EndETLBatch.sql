CREATE PROCEDURE [ctl].[EndETLBatch] @ETLBatchId       INT,
                                     @ETLBatchStatusId INT
AS
    UPDATE ctl.ETLBatch
    SET    ETLBatchStatusId = @ETLBatchStatusId
           ,EndDateTime = GETDATE()
           ,LastUpdatedDate = GETDATE()
           ,LastUpdatedUser = SUSER_SNAME()
    WHERE
      ETLBatchId = @ETLBatchId

    RETURN 0 
