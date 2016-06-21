CREATE PROCEDURE [cfg].[DeleteETLPackage_ETLPackageDependency]	@ETLPackageId INT,
																@DependedOnETLPackageId INT
AS
    DELETE FROM ctl.[ETLPackage_ETLPackageDependency]
    WHERE  ETLPackageId = @ETLPackageId
           AND DependedOnETLPackageId = @DependedOnETLPackageId

    RETURN 0 
