CREATE PROCEDURE [cfg].[SaveETLPackageGroup] @ETLPackageGroupId          INT = NULL,
                                           @ETLPackageGroup        VARCHAR(250)
AS
    MERGE [cfg].[ETLPackageGroup] AS Target
    USING (SELECT
             @ETLPackageGroupId
             ,@ETLPackageGroup) AS source ( ETLPackageGroupId, ETLPackageGroup)
    ON target.[ETLPackageGroupId] = source.ETLPackageGroupId
    WHEN Matched THEN
      UPDATE SET @ETLPackageGroup = source.ETLPackageGroup
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT ([ETLPackageGroup] )
      VALUES( source.ETLPackageGroup );


    RETURN 0 
