CREATE PROCEDURE ctl.[InsertETLBatchSSISDBExecution] @ETLBatchId        INT,
                                                     @SSISDBExecutionId BIGINT,
                                                     @ETLPackageId      INT
AS
  BEGIN
      INSERT INTO ctl.ETLBatchSSISDBExecutions
                  ([ETLBatchExecutionId]
                   ,SSISDBExecutionId
                   ,ETLPackageId)
      VALUES      (@ETLBatchId
                   ,@SSISDBExecutionId
                   ,@ETLPackageId)

      RETURN 0
  END 
