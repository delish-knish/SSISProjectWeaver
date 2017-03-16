CREATE PROCEDURE [cfg].[SaveETLPackageGroup_ETLPackage]	@ETLPackageGroupId	INT,
														@ETLPackageId		INT,
														@EnabledInd INT,
														@IgnoreForBatchCompleteInd BIT = 0
AS

          MERGE [ctl].[ETLPackageGroup_ETLPackage] AS Target
          USING (SELECT
                   @ETLPackageGroupId
                   ,@ETLPackageId
				   ,@EnabledInd
				   ,@IgnoreForBatchCompleteInd) AS source (ETLPackageGroupId, ETLPackageId, EnabledInd, IgnoreForBatchCompleteInd )
          ON target.[ETLPackageGroupId] = source.ETLPackageGroupId
             AND target.ETLPackageId = source.ETLPackageId
          WHEN Matched THEN
            UPDATE SET EnabledInd = source.EnabledInd
					   ,[IgnoreForBatchCompleteInd] = source.IgnoreForBatchCompleteInd
                       ,[LastUpdatedDate] = GETDATE()
                       ,[LastUpdatedUser] = SUSER_SNAME()
          WHEN NOT MATCHED THEN
            INSERT ([ETLPackageGroupId]
                    ,ETLPackageId
                    ,EnabledInd 
					,IgnoreForBatchCompleteInd)
            VALUES( source.ETLPackageGroupId
                    ,source.ETLPackageId
                    ,source.EnabledInd
					,source.IgnoreForBatchCompleteInd); 

    RETURN 0 
