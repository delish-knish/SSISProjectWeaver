CREATE PROCEDURE [cfg].[SaveETLPackageGroup_SQLCommand]	@ETLPackageGroupId				INT,
														@SQLCommandId					INT,
														@ExecuteAtBeginningOfGroupInd	BIT,
														@ExecuteAtEndOfGroupInd			BIT,
														@FailBatchOnFailureInd			BIT
AS

          MERGE [ctl].[ETLPackageGroup_SQLCommand] AS Target
          USING (SELECT
                   @ETLPackageGroupId
                   ,@SQLCommandId
				   ,@ExecuteAtBeginningOfGroupInd
				   ,@ExecuteAtEndOfGroupInd
				   ,@FailBatchOnFailureInd) AS source (ETLPackageGroupId, SQLCommandId, ExecuteAtBeginningOfGroupInd, ExecuteAtEndOfGroupInd, FailBatchOnFailureInd)
          ON target.[ETLPackageGroupId] = source.ETLPackageGroupId
             AND target.SQLCommandId = source.SQLCommandId
          WHEN Matched THEN
            UPDATE SET [ExecuteAtBeginningOfGroupInd] = source.ExecuteAtBeginningOfGroupInd
						,[ExecuteAtEndOfGroupInd] = source.ExecuteAtEndOfGroupInd
						,FailBatchOnFailureInd = source.FailBatchOnFailureInd
                       ,[LastUpdatedDate] = GETDATE()
                       ,[LastUpdatedUser] = SUSER_SNAME()
          WHEN NOT MATCHED THEN
            INSERT ([ETLPackageGroupId]
                    ,SQLCommandId
                    ,[ExecuteAtBeginningOfGroupInd]
					,[ExecuteAtEndOfGroupInd]
					,FailBatchOnFailureInd )
            VALUES( source.ETLPackageGroupId
                    ,source.SQLCommandId
                    ,source.ExecuteAtBeginningOfGroupInd
					,source.ExecuteAtEndOfGroupInd
					,source.FailBatchOnFailureInd ); 

    RETURN 0 
