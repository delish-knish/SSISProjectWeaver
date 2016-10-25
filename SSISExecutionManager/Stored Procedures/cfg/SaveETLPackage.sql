CREATE PROCEDURE [cfg].[SaveETLPackage] @SSISDBPackageName           VARCHAR (260),
                                        @SSISDBProjectName           VARCHAR(128),
                                        @SSISDBFolderName            VARCHAR(128),
                                        @Comments                    VARCHAR(MAX),
                                        @EntryPointSSISDBPackageName VARCHAR(260),
                                        @EnabledInd                  BIT,
                                        @ReadyForExecutionInd        BIT,
                                        @BypassEntryPointInd         BIT,
                                        @IgnoreDependenciesInd       BIT,
                                        @MaximumRetryAttempts        INT,
                                        @ExecuteSundayInd            BIT,
                                        @ExecuteMondayInd            BIT,
                                        @ExecuteTuesdayInd           BIT,
                                        @ExecuteWednesdayInd         BIT,
                                        @ExecuteThursdayInd          BIT,
                                        @ExecuteFridayInd            BIT,
                                        @ExecuteSaturdayInd          BIT,
                                        @Use32BitDtExecInd           BIT,
                                        @SupportSeverityLevelId      INT
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
        OR (@EntryPointSSISDBPackageName IS NOT NULL
            AND @EntryPointETLPackageId IS NULL)
        OR (@EntryPointETLPackageId IS NOT NULL
            AND @ReadyForExecutionInd = 1)
        OR (@EntryPointSSISDBPackageName IS NOT NULL
            AND @BypassEntryPointInd = 0
            AND @Use32BitDtExecInd = 1)
      BEGIN
          IF @SSISDBPackageId IS NULL
            THROW 50000, 'The package does not exist in the SSIS catalog. Please review package, project, and folder names for accuracy.', 1;

          IF @EntryPointSSISDBPackageName IS NOT NULL
             AND @EntryPointETLPackageId IS NULL
            THROW 50001, 'The entry-point package does not exist in the SSIS catalog. Please review the entry-point package name for accuracy.', 1;

          IF (@EntryPointETLPackageId IS NOT NULL
               OR @BypassEntryPointInd = 0)
             AND @ReadyForExecutionInd = 1
            THROW 50002, 'Only entry-point packages can be marked "ready for execution" unless bypass entry-point is set to true.', 1;

          IF @EntryPointSSISDBPackageName IS NOT NULL
             AND @BypassEntryPointInd = 0
             AND @Use32BitDtExecInd = 1
            THROW 50004, 'Only entry-point packages can be configured to use the 32-bit dtexec unless the package is set to bypass the entry-point (@BypassEntryPointInd=1).', 1;

		 IF @EntryPointSSISDBPackageName IS NOT NULL
             AND @MaximumRetryAttempts > 0
            THROW 50005, 'Only entry-point packages can be configured for retry attempts.', 1;
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
                  ,@EnabledInd
                  ,@ReadyForExecutionInd
                  ,@BypassEntryPointInd
                  ,@IgnoreDependenciesInd
                  ,@MaximumRetryAttempts
                  ,@ExecuteSundayInd
                  ,@ExecuteMondayInd
                  ,@ExecuteTuesdayInd
                  ,@ExecuteWednesdayInd
                  ,@ExecuteThursdayInd
                  ,@ExecuteFridayInd
                  ,@ExecuteSaturdayInd
                  ,@Use32BitDtExecInd
                  ,@SupportSeverityLevelId) AS source ( SSISDBPackageName, SSISDBProjectName, SSISDBFolderName, Comments, EntryPointETLPackageId, EnabledInd, ReadyForExecutionInd, BypassEntryPointInd, IgnoreDependenciesInd, MaximumRetryAttempts, ExecuteSundayInd, ExecuteMondayInd, ExecuteTuesdayInd, ExecuteWednesdayInd, ExecuteThursdayInd, ExecuteFridayInd, ExecuteSaturdayInd, Use32BitDtExecInd, SupportSeverityLevelId )
          ON target.SSISDBPackageName = source.SSISDBPackageName
             AND target.SSISDBProjectName = source.SSISDBProjectName
             AND target.SSISDBFolderName = source.SSISDBFolderName
          WHEN Matched THEN
            UPDATE SET SSISDBPackageName = source.SSISDBPackageName
                      ,SSISDBProjectName = source.SSISDBProjectName
                      ,SSISDBFolderName = source.SSISDBFolderName
                      ,Comments = source.Comments
                      ,EntryPointETLPackageId = source.EntryPointETLPackageId
                      ,EnabledInd = source.EnabledInd
                      ,ReadyForExecutionInd = source.ReadyForExecutionInd
                      ,BypassEntryPointInd = source.BypassEntryPointInd
                      ,IgnoreDependenciesInd = source.IgnoreDependenciesInd
                      ,MaximumRetryAttempts = source.MaximumRetryAttempts
                      ,ExecuteSundayInd = source.ExecuteSundayInd
                      ,ExecuteMondayInd = source.ExecuteMondayInd
                      ,ExecuteTuesdayInd = source.ExecuteTuesdayInd
                      ,ExecuteWednesdayInd = source.ExecuteWednesdayInd
                      ,ExecuteThursdayInd = source.ExecuteThursdayInd
                      ,ExecuteFridayInd = source.ExecuteFridayInd
                      ,ExecuteSaturdayInd = source.ExecuteSaturdayInd
                      ,Use32BitDtExecInd = source.Use32BitDtExecInd
                      ,SupportSeverityLevelId = source.SupportSeverityLevelId
                      ,[LastUpdatedDate] = GETDATE()
                      ,[LastUpdatedUser] = SUSER_SNAME()
          WHEN NOT MATCHED THEN
            INSERT ( SSISDBPackageName
                    ,SSISDBProjectName
                    ,SSISDBFolderName
                    ,Comments
                    ,EntryPointETLPackageId
                    ,EnabledInd
                    ,ReadyForExecutionInd
                    ,BypassEntryPointInd
                    ,IgnoreDependenciesInd
                    ,MaximumRetryAttempts
                    ,ExecuteSundayInd
                    ,ExecuteMondayInd
                    ,ExecuteTuesdayInd
                    ,ExecuteWednesdayInd
                    ,ExecuteThursdayInd
                    ,ExecuteFridayInd
                    ,ExecuteSaturdayInd
                    ,Use32BitDtExecInd
                    ,SupportSeverityLevelId )
            VALUES( source.SSISDBPackageName
                   ,source.SSISDBProjectName
                   ,source.SSISDBFolderName
                   ,source.Comments
                   ,source.EntryPointETLPackageId
                   ,source.EnabledInd
                   ,source.ReadyForExecutionInd
                   ,source.BypassEntryPointInd
                   ,source.IgnoreDependenciesInd
                   ,source.MaximumRetryAttempts
                   ,source.ExecuteSundayInd
                   ,source.ExecuteMondayInd
                   ,source.ExecuteTuesdayInd
                   ,source.ExecuteWednesdayInd
                   ,source.ExecuteThursdayInd
                   ,source.ExecuteFridayInd
                   ,source.ExecuteSaturdayInd
                   ,source.Use32BitDtExecInd
                   ,source.SupportSeverityLevelId );
      END

    RETURN 0 
