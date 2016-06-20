CREATE PROCEDURE [cfg].[SaveETLBatch] @ETLBatchId          INT = NULL,
                                           @ETLBatchName        VARCHAR(250),
                                           @ETLBatchDescription VARCHAR(MAX)
AS
    MERGE [ctl].[ETLBatch] AS Target
    USING (SELECT
             @ETLBatchId
             ,@ETLBatchName
             ,@ETLBatchDescription) AS source ( ETLBatchId, ETLBatchName, ETLBatchDescription)
    ON target.[ETLBatchId] = source.ETLBatchId
    WHEN Matched THEN
      UPDATE SET [ETLBatchName] = source.ETLBatchName
                 ,[ETLBatchDescription] = source.ETLBatchDescription
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT ([ETLBatchName]
              ,[ETLBatchDescription] )
      VALUES( source.ETLBatchName
              ,source.ETLBatchDescription );


    RETURN 0 
