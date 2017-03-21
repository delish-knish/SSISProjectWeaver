CREATE PROCEDURE [cfg].[SaveETLBatch] @ETLBatchId                 INT = NULL,
                                      @ETLBatchName               VARCHAR(250),
                                      @ETLBatchDescription        VARCHAR(MAX),
                                      @MinutesBackToContinueBatch INT,
									  @SendBatchCompleteEmailInd BIT
AS
    MERGE [ctl].[ETLBatch] AS Target
    USING (SELECT
             @ETLBatchId
            ,@ETLBatchName
            ,@ETLBatchDescription
            ,@MinutesBackToContinueBatch
			,@SendBatchCompleteEmailInd) AS source ( ETLBatchId, ETLBatchName, ETLBatchDescription, MinutesBackToContinueBatch, SendBatchCompleteEmailInd)
    ON target.[ETLBatchId] = source.ETLBatchId
    WHEN Matched THEN
      UPDATE SET [ETLBatchName] = source.ETLBatchName
                ,[ETLBatchDescription] = source.ETLBatchDescription
                ,[MinutesBackToContinueBatch] = source.MinutesBackToContinueBatch
				,[SendBatchCompleteEmailInd] = source.[SendBatchCompleteEmailInd]
                ,[LastUpdatedDate] = GETDATE()
                ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT ([ETLBatchName]
             ,[ETLBatchDescription]
             ,[MinutesBackToContinueBatch]
			 ,[SendBatchCompleteEmailInd] )
      VALUES( source.ETLBatchName
             ,source.ETLBatchDescription
             ,source.MinutesBackToContinueBatch
			 ,source.SendBatchCompleteEmailInd );

    RETURN 0 
