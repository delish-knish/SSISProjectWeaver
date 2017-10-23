CREATE PROCEDURE [cfg].[SaveETLPackageGroup_ETLPackageGroupDependency] @ETLPackageGroupId           INT,
                                                                       @DependedOnETLPackageGroupId INT,
                                                                       @EnabledInd                  BIT
AS
    MERGE [cfg].[ETLPackageGroup_ETLPackageGroupDependency] AS Target
    USING (SELECT
             @ETLPackageGroupId
            ,@DependedOnETLPackageGroupId
            ,@EnabledInd) AS source (ETLPackageGroupId, DependentOnETLPackageGroupId, EnabledInd )
    ON target.ETLPackageGroupId = source.ETLPackageGroupId
       AND target.[DependedOnETLPackageGroupId] = source.DependentOnETLPackageGroupId
    WHEN Matched THEN
      UPDATE SET EnabledInd = source.EnabledInd
                ,[LastUpdatedDate] = GETDATE()
                ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (ETLPackageGroupId
             ,[DependedOnETLPackageGroupId]
             ,EnabledInd )
      VALUES( source.ETLPackageGroupId
             ,source.DependentOnETLPackageGroupId
             ,source.EnabledInd );

    RETURN 0 
