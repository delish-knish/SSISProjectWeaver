CREATE PROCEDURE [cfg].[SaveETLPackageDependency] @ETLPackageId            INT,
                                                  @DependedOnETLPackageId INT,
                                                  @EnabledInd              BIT
AS
    DECLARE @IsETLPackageAnEntryPointInd BIT = (SELECT
         EntryPointPackageInd
       FROM
         [ctl].ETLPackage
       WHERE
        ETLPackageId = @ETLPackageId)

	DECLARE @IsDependedOnETLPackageAnEntryPointInd BIT = (SELECT
         EntryPointPackageInd
       FROM
         [ctl].ETLPackage
       WHERE
        ETLPackageId = @DependedOnETLPackageId)

    IF @IsETLPackageAnEntryPointInd = 0 --
	BEGIN
		IF @IsETLPackageAnEntryPointInd = 0
			THROW 50002, 'The ETL package must be an entry-point package. Dependencies are only checked for entry-point packages.', 1;
		END
	ELSE
      BEGIN
          MERGE [ctl].[ETLPackage_ETLPackageDependency] AS Target
          USING (SELECT
                   @ETLPackageId
                   ,@DependedOnETLPackageId
                   ,@EnabledInd) AS source (ETLPackageId, DependentOnETLPackageId, EnabledInd )
          ON target.ETLPackageId = source.ETLPackageId
             AND target.[DependedOnETLPackageId] = source.DependentOnETLPackageId
          WHEN Matched THEN
            UPDATE SET EnabledInd = source.EnabledInd
                       ,[LastUpdatedDate] = GETDATE()
                       ,[LastUpdatedUser] = SUSER_SNAME()
          WHEN NOT MATCHED THEN
            INSERT (ETLPackageId
                    ,[DependedOnETLPackageId]
                    ,EnabledInd )
            VALUES( source.ETLPackageId
                    ,source.DependentOnETLPackageId
                    ,source.EnabledInd );
      END

    RETURN 0 
