CREATE PROCEDURE [cfg].[SaveETLBatch] @ETLBatchId                 INT = NULL,
                                      @ETLBatchName               VARCHAR(250),
                                      @ETLBatchDescription        VARCHAR(MAX),
                                      @MinutesBackToContinueBatch INT
AS
    MERGE [ctl].[ETLBatch] AS Target
    USING (SELECT
             @ETLBatchId
            ,@ETLBatchName
            ,@ETLBatchDescription
            ,@MinutesBackToContinueBatch) AS source ( ETLBatchId, ETLBatchName, ETLBatchDescription, MinutesBackToContinueBatch)
    ON target.[ETLBatchId] = source.ETLBatchId
    WHEN Matched THEN
      UPDATE SET [ETLBatchName] = source.ETLBatchName
                ,[ETLBatchDescription] = source.ETLBatchDescription
                ,[MinutesBackToContinueBatch] = source.MinutesBackToContinueBatch
                ,[LastUpdatedDate] = GETDATE()
                ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT ([ETLBatchName]
             ,[ETLBatchDescription]
             ,[MinutesBackToContinueBatch] )
      VALUES( source.ETLBatchName
             ,source.ETLBatchDescription
             ,source.MinutesBackToContinueBatch );

    RETURN 0 
