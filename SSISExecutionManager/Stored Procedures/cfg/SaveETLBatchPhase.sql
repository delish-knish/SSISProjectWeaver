CREATE PROCEDURE [cfg].[SaveETLBatchPhase] @ETLBatchPhaseId          INT = NULL,
                                           @ETLBatchPhase        VARCHAR(250)
AS
    MERGE [ctl].[ETLBatchPhase] AS Target
    USING (SELECT
             @ETLBatchPhaseId
             ,@ETLBatchPhase) AS source ( ETLBatchPhaseId, ETLBatchPhase)
    ON target.ETLBatchPhaseId = source.ETLBatchPhaseId
    WHEN Matched THEN
      UPDATE SET @ETLBatchPhase = source.ETLBatchPhase
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (ETLBatchPhase )
      VALUES( source.ETLBatchPhase );


    RETURN 0 
