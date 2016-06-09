CREATE PROCEDURE [log].[InsertETLBatchEvent] @ETLBatchEventTypeId INT,
                                             @ETLBatchId          INT,
                                             @ETLPackageId        INT,
                                             @Description         VARCHAR(MAX)
AS
    INSERT INTO [log].ETLBatchEvent
                ([ETLBatchEventTypeId]
                 ,[ETLBatchId]
                 ,[ETLPackageId]
                 ,[Description]
                 ,[EventDateTime])
    VALUES      ( @ETLBatchEventTypeId
                  ,@ETLBatchId
                  ,@ETLPackageId
                  ,@Description + ': ' + FORMAT(GETDATE(), 'yyyy/MM/dd hh:mm:ss t', 'en-US')
                  ,GETDATE() )

    RETURN 0 
