CREATE PROCEDURE ctl.[InsertETLBatchSSISDBExecution] @ETLBatchId        INT,
                                                     @SSISDBExecutionId BIGINT,
                                                     @ETLPackageId      INT
AS
  BEGIN
      INSERT INTO ctl.ETLBatchSSISDBExecutions
                  (ETLBatchId
                   ,SSISDBExecutionId
                   ,ETLPackageId)
      VALUES      (@ETLBatchId
                   ,@SSISDBExecutionId
                   ,@ETLPackageId)

      RETURN 0
  END 
