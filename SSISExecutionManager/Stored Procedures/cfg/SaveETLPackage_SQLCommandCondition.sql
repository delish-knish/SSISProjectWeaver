CREATE PROCEDURE [cfg].[SaveETLPackage_SQLCommandCondition] @ETLPackageId INT,
																@SQLCommandId INT,
																@EnabledInd   BIT
AS

          MERGE [ctl].[ETLPackage_SQLCommandCondition] AS Target
          USING (SELECT
                   @ETLPackageId
                   ,@SQLCommandId
                   ,@EnabledInd) AS source (ETLPackageId, SQLCommandId, EnabledInd )
          ON target.ETLPackageId = source.ETLPackageId
             AND target.SQLCommandId = source.SQLCommandId
          WHEN Matched THEN
            UPDATE SET EnabledInd = source.EnabledInd
                       ,[LastUpdatedDate] = GETDATE()
                       ,[LastUpdatedUser] = SUSER_SNAME()
          WHEN NOT MATCHED THEN
            INSERT (ETLPackageId
                    ,SQLCommandId
                    ,EnabledInd )
            VALUES( source.ETLPackageId
                    ,source.SQLCommandId
                    ,source.EnabledInd );
    
    RETURN 0 
