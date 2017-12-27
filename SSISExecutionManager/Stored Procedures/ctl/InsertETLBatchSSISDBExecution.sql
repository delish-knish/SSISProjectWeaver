CREATE PROCEDURE ctl.[InsertETLBatchSSISDBExecution] @ETLBatchExecutionId INT,
                                                     @SSISDBExecutionId   BIGINT,
                                                     @ETLPackageId        INT,
													 @ETLPackageGroupId   INT
AS
  BEGIN
      INSERT INTO ctl.ETLBatchSSISDBExecutions
                  ([ETLBatchExecutionId]
                  ,SSISDBExecutionId
                  ,ETLPackageId
				  ,ETLPackageGroupId)
      VALUES      (@ETLBatchExecutionId
                  ,@SSISDBExecutionId
                  ,@ETLPackageId
				  ,@ETLPackageGroupId)

      RETURN 0
  END 
