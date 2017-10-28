﻿CREATE TABLE [cfg].[ETLPackageGroup_ETLPackage]
  (
     [ETLPackageGroup_ETLPackageId]  INT IDENTITY(1, 1) NOT NULL
     ,[ETLPackageGroupId]            INT NOT NULL
     ,[ETLPackageId]                 INT NOT NULL
     ,[IgnoreForBatchCompleteInd]    BIT CONSTRAINT [DF_ETLPackageGroup_ETLPackage_IgnoreForBatchCompleteInd] DEFAULT (0) NOT NULL
     ,[EnabledInd]                   BIT CONSTRAINT [DF_ETLPackageGroup_ETLPackage_EnabledInd] DEFAULT (1) NOT NULL
     ,[ReadyForExecutionInd]         BIT NULL
     ,[BypassEntryPointInd]          BIT CONSTRAINT [DF_ETLPackage_ByPassEntryPointInd] DEFAULT ((0)) NOT NULL
     ,[IgnoreDependenciesInd]        BIT CONSTRAINT [DF_ETLPackage_IgnoreDependenciesInd] DEFAULT ((0)) NOT NULL
     ,[MaximumRetryAttempts]         INT CONSTRAINT [DF_ETLPackage_MaximumRetryAttempts] DEFAULT ((0)) NOT NULL
     ,[RemainingRetryAttempts]       INT CONSTRAINT [DF_ETLPackage_RemainingRetryAttempts] DEFAULT ((0)) NOT NULL
     ,[OverrideSSISDBLoggingLevelId] INT NULL
     ,[ExecuteSundayInd]             BIT CONSTRAINT [DF_ETLPackage_ExecuteSundayInd] DEFAULT ((0)) NOT NULL
     ,[ExecuteMondayInd]             BIT CONSTRAINT [DF_ETLPackage_ExecuteMondayInd] DEFAULT ((0)) NOT NULL
     ,[ExecuteTuesdayInd]            BIT CONSTRAINT [DF_ETLPackage_ExecuteTuesdayInd] DEFAULT ((0)) NOT NULL
     ,[ExecuteWednesdayInd]          BIT CONSTRAINT [DF_ETLPackage_ExecuteWednesdayInd] DEFAULT ((0)) NOT NULL
     ,[ExecuteThursdayInd]           BIT CONSTRAINT [DF_ETLPackage_ExecuteThursdayInd] DEFAULT ((0)) NOT NULL
     ,[ExecuteFridayInd]             BIT CONSTRAINT [DF_ETLPackage_ExecuteFridayInd] DEFAULT ((0)) NOT NULL
     ,[ExecuteSaturdayInd]           BIT CONSTRAINT [DF_ETLPackage_ExecuteSaturdayInd] DEFAULT ((0)) NOT NULL
     ,[SupportSeverityLevelId]       INT NOT NULL
     ,[Comments]                     VARCHAR (MAX) NULL
     ,[CreatedDate]                  DATETIME2 (7) CONSTRAINT [DF_ETLPackageGroup_ETLPackage_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                  VARCHAR (50) CONSTRAINT [DF_ETLPackageGroup_ETLPackage_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_ETLPackageGroup_ETLPackage_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]              VARCHAR (50) CONSTRAINT [DF_ETLPackageGroup_ETLPackage_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     CONSTRAINT [PK_ETLPackageGroup_ETLPackage_ETLPackage] PRIMARY KEY ([ETLPackageGroup_ETLPackageId]),
     CONSTRAINT [AK_ETLPackageGroup_ETLPackage_ETLPackage_ETLPackageGroupId_ETLPackageId] UNIQUE ([ETLPackageGroupId], [ETLPackageId]),
     CONSTRAINT [FK_ETLPackageGroup_ETLPackage_ETLPackage_ETLPackageGroup] FOREIGN KEY ([ETLPackageGroupId]) REFERENCES [cfg].[ETLPackageGroup]([ETLPackageGroupId]),
     CONSTRAINT [FK_ETLPackageGroup_ETLPackage_ETLPackage_ETLPackage] FOREIGN KEY (ETLPackageId) REFERENCES [cfg].[ETLPackage]([ETLPackageId]),
     CONSTRAINT [FK_ETLPackageGroup_ETLPackage_SupportSeverityLevel] FOREIGN KEY ([SupportSeverityLevelId]) REFERENCES [ref].[SupportSeverityLevel] ([SupportSeverityLevelId]),
     CONSTRAINT [FK_ETLPackageGroup_ETLPackage_SSISDBLoggingLevel] FOREIGN KEY ([OverrideSSISDBLoggingLevelId]) REFERENCES ref.SSISDBLoggingLevel(SSISDBLoggingLevelId)
  );

GO

EXECUTE sp_addextendedproperty
  @name = N'MS_Description',
  @value = N'Run regardless of dependency statuses. Good for dev/debug and potential prod scenarios. Initialize process should set to False.',
  @level0type = N'SCHEMA',
  @level0name = N'cfg',
  @level1type = N'TABLE',
  @level1name = N'ETLPackageGroup_ETLPackage',
  @level2type = N'COLUMN',
  @level2name = N'IgnoreDependenciesInd';

GO

EXECUTE sp_addextendedproperty
  @name = N'MS_Description',
  @value = N'If this package is executed via a parent/main package but an admin would like to execute it directly, this flag should be set to True.',
  @level0type = N'SCHEMA',
  @level0name = N'cfg',
  @level1type = N'TABLE',
  @level1name = N'ETLPackageGroup_ETLPackage',
  @level2type = N'COLUMN',
  @level2name = N'BypassEntryPointInd';

GO

EXECUTE sp_addextendedproperty
  @name = N'MS_Description',
  @value = N'Lets the control process know that the package should be picked up for execution. This will be set by the initialize process as well as manually when resetting after a failure.',
  @level0type = N'SCHEMA',
  @level0name = N'cfg',
  @level1type = N'TABLE',
  @level1name = N'ETLPackageGroup_ETLPackage',
  @level2type = N'COLUMN',
  @level2name = N'ReadyForExecutionInd';

GO 

EXECUTE sp_addextendedproperty
  @name = N'MS_Description',
  @value = N'Indicates whether the package should be included for execution and dependency checks regardless of whether it is an entry point package.',
  @level0type = N'SCHEMA',
  @level0name = N'cfg',
  @level1type = N'TABLE',
  @level1name = N'ETLPackageGroup_ETLPackage',
  @level2type = N'COLUMN',
  @level2name = N'EnabledInd';

GO