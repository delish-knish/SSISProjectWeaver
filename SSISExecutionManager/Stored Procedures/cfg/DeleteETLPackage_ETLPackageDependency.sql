CREATE PROCEDURE [cfg].[DeleteETLPackage_ETLPackageDependency]	@ETLPackageId INT,
																@DependedOnETLPackageId INT
AS
    DELETE FROM [cfg].[ETLPackage_ETLPackageDependency]
    WHERE  ETLPackageId = @ETLPackageId
           AND DependedOnETLPackageId = @DependedOnETLPackageId

    RETURN 0 
