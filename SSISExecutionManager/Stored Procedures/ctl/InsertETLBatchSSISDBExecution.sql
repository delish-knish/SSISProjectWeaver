CREATE PROCEDURE ctl.[InsertETLBatchSSISDBExecution] @ETLBatchExecutionId INT,
                                                     @SSISDBExecutionId   BIGINT,
                                                     @ETLPackageId        INT
AS
  BEGIN
      INSERT INTO ctl.ETLBatchSSISDBExecutions
                  ([ETLBatchExecutionId]
                  ,SSISDBExecutionId
                  ,ETLPackageId)
      VALUES      (@ETLBatchExecutionId
                  ,@SSISDBExecutionId
                  ,@ETLPackageId)

      RETURN 0
  END 
