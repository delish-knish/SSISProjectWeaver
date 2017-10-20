CREATE PROCEDURE [cfg].[SaveETLPackage] @SSISDBPackageName           NVARCHAR (260),
                                        @SSISDBProjectName           NVARCHAR(128),
                                        @SSISDBFolderName            NVARCHAR(128),
                                        @Comments                    VARCHAR(MAX),
                                        @EntryPointSSISDBPackageName NVARCHAR(260),
                                        @Use32BitDtExecInd           BIT
AS
    --Get SSISDBPackageId
    DECLARE @SSISDBPackageId BIGINT

    SET @SSISDBPackageId = (SELECT
                              dbo.[func_GetSSISDBPackageId] (@SSISDBPackageName, @SSISDBProjectName, @SSISDBFolderName))

    --Get entry-point SSISDBPackageId
    DECLARE @EntryPointETLPackageId BIGINT

    SET @EntryPointETLPackageId = (SELECT
                                     ETLPackageId
                                   FROM
                                     [ctl].ETLPackage
                                   WHERE
                                    SSISDBPackageName = @EntryPointSSISDBPackageName)

    --If the lookup to the SSISDB fails, throw an exception with an explanation
    IF @SSISDBPackageId IS NULL
        OR ( @EntryPointSSISDBPackageName IS NOT NULL
             AND @EntryPointETLPackageId IS NULL )
        OR ( @EntryPointETLPackageId IS NOT NULL )
        OR ( @EntryPointSSISDBPackageName IS NOT NULL
             AND @Use32BitDtExecInd = 1 )
      BEGIN
          IF @SSISDBPackageId IS NULL
            THROW 50000, 'The package does not exist in the SSIS catalog. Please review package, project, and folder names for accuracy.', 1;

          IF @EntryPointSSISDBPackageName IS NOT NULL
             AND @EntryPointETLPackageId IS NULL
            THROW 50001, 'The entry-point package does not exist in the SSIS catalog. Please review the entry-point package name for accuracy.', 1;

          IF @EntryPointSSISDBPackageName IS NOT NULL
             AND @Use32BitDtExecInd = 1
            THROW 50004, 'Only entry-point packages can be configured to use the 32-bit dtexec.', 1;
      END

    ELSE --Save the ETLPackage row
      BEGIN
          MERGE [ctl].ETLPackage AS Target
          USING (SELECT
                   @SSISDBPackageName
                   ,@SSISDBProjectName
                   ,@SSISDBFolderName
                   ,@Comments
                   ,@EntryPointETLPackageId
                   ,@Use32BitDtExecInd) AS source ( SSISDBPackageName, SSISDBProjectName, SSISDBFolderName, Comments, EntryPointETLPackageId, Use32BitDtExecInd )
          ON target.SSISDBPackageName = source.SSISDBPackageName
             AND target.SSISDBProjectName = source.SSISDBProjectName
             AND target.SSISDBFolderName = source.SSISDBFolderName
          WHEN Matched THEN
            UPDATE SET SSISDBPackageName = source.SSISDBPackageName
                       ,SSISDBProjectName = source.SSISDBProjectName
                       ,SSISDBFolderName = source.SSISDBFolderName
                       ,Comments = source.Comments
                       ,EntryPointETLPackageId = source.EntryPointETLPackageId
                       ,Use32BitDtExecInd = source.Use32BitDtExecInd
                       ,[LastUpdatedDate] = GETDATE()
                       ,[LastUpdatedUser] = SUSER_SNAME()
          WHEN NOT MATCHED THEN
            INSERT ( SSISDBPackageName
                     ,SSISDBProjectName
                     ,SSISDBFolderName
                     ,Comments
                     ,EntryPointETLPackageId
                     ,Use32BitDtExecInd )
            VALUES( source.SSISDBPackageName
                    ,source.SSISDBProjectName
                    ,source.SSISDBFolderName
                    ,source.Comments
                    ,source.EntryPointETLPackageId
                    ,source.Use32BitDtExecInd );
      END

    RETURN 0 
