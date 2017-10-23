CREATE PROCEDURE [cfg].[SaveETLPackage_SQLCommandCondition] @ETLBatchId   INT,
                                                            @ETLPackageId INT,
                                                            @SQLCommandId INT,
                                                            @EnabledInd   BIT
AS
    MERGE [cfg].[ETLBatch_ETLPackage_SQLCommandCondition] AS Target
    USING (SELECT
             @ETLBatchId
            ,@ETLPackageId
            ,@SQLCommandId
            ,@EnabledInd) AS source (ETLBatchId, ETLPackageId, SQLCommandId, EnabledInd )
    ON target.ETLBatchId = source.ETLBatchId
       AND target.ETLPackageId = source.ETLPackageId
       AND target.SQLCommandId = source.SQLCommandId
    WHEN Matched THEN
      UPDATE SET EnabledInd = source.EnabledInd
                ,[LastUpdatedDate] = GETDATE()
                ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (ETLBatchId
             ,ETLPackageId
             ,SQLCommandId
             ,EnabledInd )
      VALUES( source.ETLBatchId
             ,source.ETLPackageId
             ,source.SQLCommandId
             ,source.EnabledInd );

    RETURN 0 
