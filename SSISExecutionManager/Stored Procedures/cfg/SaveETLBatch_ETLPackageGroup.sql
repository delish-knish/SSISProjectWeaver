CREATE PROCEDURE [cfg].[SaveETLBatch_ETLPackageGroup] @ETLBatchId         INT,
													@ETLPackageGroupId	INT
AS

          MERGE [ctl].[ETLBatch_ETLPackageGroup] AS Target
          USING (SELECT
                   @ETLBatchId
                   ,@ETLPackageGroupId) AS source (ETLBatchId, ETLPackageGroupId )
          ON target.ETLBatchId = source.ETLBatchId
             AND target.[ETLPackageGroupId] = source.ETLPackageGroupId
          --WHEN Matched THEN
          --  UPDATE SET [LastUpdatedDate] = GETDATE()
          --             ,[LastUpdatedUser] = SUSER_SNAME()
          WHEN NOT MATCHED THEN
            INSERT (ETLBatchId
                    ,[ETLPackageGroupId] )
            VALUES( source.ETLBatchId
                    ,source.ETLPackageGroupId );
 

    RETURN 0 
