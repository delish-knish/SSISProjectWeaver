CREATE PROCEDURE [cfg].[SaveETLBatch_ETLBatchPhase] @ETLBatchId         INT,
													@ETLBatchPhaseId	INT,
													@PhaseExecutionOrderNo INT
AS

          MERGE [ctl].[ETLBatch_ETLBatchPhase] AS Target
          USING (SELECT
                   @ETLBatchId
                   ,@ETLBatchPhaseId
				   ,@PhaseExecutionOrderNo) AS source (ETLBatchId, ETLBatchPhaseId, PhaseExecutionOrderNo )
          ON target.ETLBatchId = source.ETLBatchId
             AND target.ETLBatchPhaseId = source.ETLBatchPhaseId
          WHEN Matched THEN
            UPDATE SET PhaseExecutionOrderNo = source.PhaseExecutionOrderNo
                       ,[LastUpdatedDate] = GETDATE()
                       ,[LastUpdatedUser] = SUSER_SNAME()
          WHEN NOT MATCHED THEN
            INSERT (ETLBatchId
                    ,ETLBatchPhaseId
                    ,PhaseExecutionOrderNo )
            VALUES( source.ETLBatchId
                    ,source.ETLBatchPhaseId
                    ,source.PhaseExecutionOrderNo );
 

    RETURN 0 
