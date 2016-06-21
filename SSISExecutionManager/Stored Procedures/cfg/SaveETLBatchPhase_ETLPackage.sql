CREATE PROCEDURE [cfg].[SaveETLBatchPhase_ETLPackage]	@ETLBatchPhaseId	INT,
														@ETLPackageId		INT,
														@EnabledInd INT
AS

          MERGE [ctl].[ETLBatchPhase_ETLPackage] AS Target
          USING (SELECT
                   @ETLBatchPhaseId
                   ,@ETLPackageId
				   ,@EnabledInd) AS source (ETLBatchPhaseId, ETLPackageId, EnabledInd )
          ON target.ETLBatchPhaseId = source.ETLBatchPhaseId
             AND target.ETLPackageId = source.ETLPackageId
          WHEN Matched THEN
            UPDATE SET EnabledInd = source.EnabledInd
                       ,[LastUpdatedDate] = GETDATE()
                       ,[LastUpdatedUser] = SUSER_SNAME()
          WHEN NOT MATCHED THEN
            INSERT (ETLBatchPhaseId
                    ,ETLPackageId
                    ,EnabledInd )
            VALUES( source.ETLBatchPhaseId
                    ,source.ETLPackageId
                    ,source.EnabledInd ); 

    RETURN 0 
