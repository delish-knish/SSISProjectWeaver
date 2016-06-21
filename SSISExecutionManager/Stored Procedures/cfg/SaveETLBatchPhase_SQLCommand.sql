CREATE PROCEDURE [cfg].[SaveETLBatchPhase_SQLCommand]	@ETLBatchPhaseId				INT,
														@SQLCommandId					INT,
														@ExecuteAtBeginningOfPhaseInd	BIT,
														@ExecuteAtEndOfPhaseInd			BIT,
														@FailBatchOnFailureInd			BIT
AS

          MERGE [ctl].[ETLBatchPhase_SQLCommand] AS Target
          USING (SELECT
                   @ETLBatchPhaseId
                   ,@SQLCommandId
				   ,@ExecuteAtBeginningOfPhaseInd
				   ,@ExecuteAtEndOfPhaseInd
				   ,@FailBatchOnFailureInd) AS source (ETLBatchPhaseId, SQLCommandId, ExecuteAtBeginningOfPhaseInd, ExecuteAtEndOfPhaseInd, FailBatchOnFailureInd)
          ON target.ETLBatchPhaseId = source.ETLBatchPhaseId
             AND target.SQLCommandId = source.SQLCommandId
          WHEN Matched THEN
            UPDATE SET ExecuteAtBeginningOfPhaseInd = source.ExecuteAtBeginningOfPhaseInd
						,ExecuteAtEndOfPhaseInd = source.ExecuteAtEndOfPhaseInd
						,FailBatchOnFailureInd = source.FailBatchOnFailureInd
                       ,[LastUpdatedDate] = GETDATE()
                       ,[LastUpdatedUser] = SUSER_SNAME()
          WHEN NOT MATCHED THEN
            INSERT (ETLBatchPhaseId
                    ,SQLCommandId
                    ,ExecuteAtBeginningOfPhaseInd
					,ExecuteAtEndOfPhaseInd
					,FailBatchOnFailureInd )
            VALUES( source.ETLBatchPhaseId
                    ,source.SQLCommandId
                    ,source.ExecuteAtBeginningOfPhaseInd
					,source.ExecuteAtEndOfPhaseInd
					,source.FailBatchOnFailureInd ); 

    RETURN 0 
