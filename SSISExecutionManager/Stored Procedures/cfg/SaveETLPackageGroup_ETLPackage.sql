﻿CREATE PROCEDURE [cfg].[SaveETLPackageGroup_ETLPackage] @ETLPackageGroupId                    INT,
                                                       @ETLPackageId                         INT,
                                                       @EnabledInd                           INT,
                                                       @IgnoreForBatchCompleteInd            BIT = 0,
                                                       @ReadyForExecutionInd                 BIT,
                                                       @BypassEntryPointInd                  BIT,
                                                       @IgnoreDependenciesInd                BIT,
                                                       @IgnoreSQLCommandConditionsDefaultInd BIT,
                                                       @MaximumRetryAttempts                 INT,
                                                       @OverrideSSISDBLoggingLevelId         INT,
                                                       @ExecuteNthDayOfMonth                 INT,
                                                       @ExecuteSundayInd                     BIT,
                                                       @ExecuteMondayInd                     BIT,
                                                       @ExecuteTuesdayInd                    BIT,
                                                       @ExecuteWednesdayInd                  BIT,
                                                       @ExecuteThursdayInd                   BIT,
                                                       @ExecuteFridayInd                     BIT,
                                                       @ExecuteSaturdayInd                   BIT,
                                                       @SupportSeverityLevelId               INT
AS
    --Get entry-point SSISDBPackageId
    DECLARE @EntryPointETLPackageId BIGINT = (SELECT
         EntryPointETLPackageId
       FROM
         [cfg].ETLPackage
       WHERE
        ETLPackageId = @ETLPackageId)

    --Validate configuration
    IF ( @EntryPointETLPackageId IS NOT NULL
         AND @ReadyForExecutionInd = 1 )
        OR ( @BypassEntryPointInd = 0 )
      BEGIN
          IF ( @EntryPointETLPackageId IS NOT NULL
                OR @BypassEntryPointInd = 0 )
             AND @ReadyForExecutionInd = 1
            THROW 50002, 'Only entry-point packages can be marked "ready for execution" unless bypass entry-point is set to true.', 1;

          IF @EntryPointETLPackageId IS NOT NULL
             AND @MaximumRetryAttempts > 0
            THROW 50005, 'Only entry-point packages can be configured for retry attempts.', 1;

          IF @EntryPointETLPackageId IS NOT NULL
             AND @OverrideSSISDBLoggingLevelId IS NOT NULL
            THROW 50006, 'Only entry-point packages can have their logging level overridden.', 1;
      END

    MERGE [cfg].[ETLPackageGroup_ETLPackage] AS Target
    USING (SELECT
             @ETLPackageGroupId
             ,@ETLPackageId
             ,@EnabledInd
             ,@IgnoreForBatchCompleteInd
             ,@ReadyForExecutionInd
             ,@BypassEntryPointInd
             ,@IgnoreDependenciesInd
             ,@IgnoreSQLCommandConditionsDefaultInd
             ,@MaximumRetryAttempts
             ,@OverrideSSISDBLoggingLevelId
             ,@ExecuteNthDayOfMonth
             ,@ExecuteSundayInd
             ,@ExecuteMondayInd
             ,@ExecuteTuesdayInd
             ,@ExecuteWednesdayInd
             ,@ExecuteThursdayInd
             ,@ExecuteFridayInd
             ,@ExecuteSaturdayInd
             ,@SupportSeverityLevelId) AS source (ETLPackageGroupId, ETLPackageId, EnabledInd, IgnoreForBatchCompleteInd, ReadyForExecutionInd, BypassEntryPointInd, IgnoreDependenciesInd, IgnoreSQLCommandConditionsDefaultInd, MaximumRetryAttempts, OverrideSSISDBLoggingLevelId, ExecuteNthDayOfMonth, ExecuteSundayInd, ExecuteMondayInd, ExecuteTuesdayInd, ExecuteWednesdayInd, ExecuteThursdayInd, ExecuteFridayInd, ExecuteSaturdayInd, SupportSeverityLevelId )
    ON target.[ETLPackageGroupId] = source.ETLPackageGroupId
       AND target.ETLPackageId = source.ETLPackageId
    WHEN Matched THEN
      UPDATE SET EnabledInd = source.EnabledInd
                 ,[IgnoreForBatchCompleteDefaultInd] = source.IgnoreForBatchCompleteInd
                 ,ReadyForExecutionInd = source.ReadyForExecutionInd
                 ,[BypassEntryPointDefaultInd] = source.BypassEntryPointInd
                 ,[IgnoreDependenciesDefaultInd] = source.IgnoreDependenciesInd
                 ,IgnoreSQLCommandConditionsDefaultInd = source.IgnoreSQLCommandConditionsDefaultInd
                 ,[MaximumRetryAttemptsDefault] = source.MaximumRetryAttempts
                 ,OverrideSSISDBLoggingLevelId = source.OverrideSSISDBLoggingLevelId
                 ,ExecuteNthDayOfMonth = source.ExecuteNthDayOfMonth
                 ,ExecuteSundayInd = source.ExecuteSundayInd
                 ,ExecuteMondayInd = source.ExecuteMondayInd
                 ,ExecuteTuesdayInd = source.ExecuteTuesdayInd
                 ,ExecuteWednesdayInd = source.ExecuteWednesdayInd
                 ,ExecuteThursdayInd = source.ExecuteThursdayInd
                 ,ExecuteFridayInd = source.ExecuteFridayInd
                 ,ExecuteSaturdayInd = source.ExecuteSaturdayInd
                 ,SupportSeverityLevelId = source.SupportSeverityLevelId
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (ETLPackageGroupId
              ,ETLPackageId
              ,EnabledInd
              ,IgnoreForBatchCompleteDefaultInd
              ,ReadyForExecutionInd
              ,BypassEntryPointDefaultInd
              ,IgnoreDependenciesDefaultInd
              ,IgnoreSQLCommandConditionsDefaultInd
              ,MaximumRetryAttemptsDefault
              ,OverrideSSISDBLoggingLevelId
              ,ExecuteNthDayOfMonth
              ,ExecuteSundayInd
              ,ExecuteMondayInd
              ,ExecuteTuesdayInd
              ,ExecuteWednesdayInd
              ,ExecuteThursdayInd
              ,ExecuteFridayInd
              ,ExecuteSaturdayInd
              ,SupportSeverityLevelId  )
      VALUES( source.ETLPackageGroupId
              ,source.ETLPackageId
              ,source.EnabledInd
              ,source.IgnoreForBatchCompleteInd
              ,source.ReadyForExecutionInd
              ,source.BypassEntryPointInd
              ,source.IgnoreDependenciesInd
              ,source.IgnoreSQLCommandConditionsDefaultInd
              ,source.MaximumRetryAttempts
              ,source.OverrideSSISDBLoggingLevelId
              ,source.ExecuteNthDayOfMonth
              ,source.ExecuteSundayInd
              ,source.ExecuteMondayInd
              ,source.ExecuteTuesdayInd
              ,source.ExecuteWednesdayInd
              ,source.ExecuteThursdayInd
              ,source.ExecuteFridayInd
              ,source.ExecuteSaturdayInd
              ,source.SupportSeverityLevelId);

    RETURN 0 
