CREATE PROCEDURE [log].[InsertETLBatchExecutionEvent] @ETLBatchEventTypeId INT,
                                             @ETLBatchExecutionId INT,
                                             @ETLPackageId        INT,
                                             @Description         VARCHAR(MAX)
AS
    INSERT INTO [log].[ETLBatchExecutionEvent]
                ([ETLBatchExecutionEventTypeId]
                 ,[ETLBatchExecutionId]
                 ,[ETLPackageId]
                 ,[Description]
                 ,[EventDateTime])
    VALUES      ( @ETLBatchEventTypeId
                  ,@ETLBatchExecutionId
                  ,@ETLPackageId
                  ,@Description + ': ' + FORMAT(GETDATE(), 'yyyy/MM/dd hh:mm:ss t', 'en-US')
                  ,GETDATE() )

    RETURN 0 
