CREATE PROCEDURE [cfg].[DeleteETLPackageGroup_ETLPackageGroupDependency] @ETLPackageGroupId           INT,
                                                                         @DependedOnETLPackageGroupId INT
AS
    DELETE FROM ctl.[ETLPackageGroup_ETLPackageGroupDependency]
    WHERE  ETLPackageGroupId = @ETLPackageGroupId
           AND DependedOnETLPackageGroupId = @DependedOnETLPackageGroupId

    RETURN 0 
