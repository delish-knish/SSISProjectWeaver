CREATE PROCEDURE [cfg].[SaveETLPackageGroup_ETLPackage]	@ETLPackageGroupId	INT,
														@ETLPackageId		INT,
														@EnabledInd INT
AS

          MERGE [ctl].[ETLPackageGroup_ETLPackage] AS Target
          USING (SELECT
                   @ETLPackageGroupId
                   ,@ETLPackageId
				   ,@EnabledInd) AS source (ETLPackageGroupId, ETLPackageId, EnabledInd )
          ON target.[ETLPackageGroupId] = source.ETLPackageGroupId
             AND target.ETLPackageId = source.ETLPackageId
          WHEN Matched THEN
            UPDATE SET EnabledInd = source.EnabledInd
                       ,[LastUpdatedDate] = GETDATE()
                       ,[LastUpdatedUser] = SUSER_SNAME()
          WHEN NOT MATCHED THEN
            INSERT ([ETLPackageGroupId]
                    ,ETLPackageId
                    ,EnabledInd )
            VALUES( source.ETLPackageGroupId
                    ,source.ETLPackageId
                    ,source.EnabledInd ); 

    RETURN 0 
