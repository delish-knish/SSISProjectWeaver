CREATE TABLE [ctl].[ETLPackage]
  (
     [ETLPackageId]           INT IDENTITY (1, 1) NOT NULL
    ,[SSISDBFolderName]       VARCHAR (128) NOT NULL
    ,[SSISDBProjectName]      VARCHAR (128) NOT NULL
    ,[SSISDBPackageName]      VARCHAR (260) NOT NULL
    ,[EntryPointPackageInd] AS (CONVERT([BIT], CASE
                           WHEN [EntryPointETLPackageId] IS NULL THEN (1)
                           ELSE (0)
                         END))
    ,[EntryPointETLPackageId] INT NULL
    ,[EnabledInd]             BIT CONSTRAINT [DF_ETLPackage_PackageEnabledInd] DEFAULT ((1)) NOT NULL
    ,[ReadyForExecutionInd]   BIT NULL
    ,[BypassEntryPointInd]    BIT CONSTRAINT [DF_ETLPackage_ByPassEntryPointInd] DEFAULT ((0)) NOT NULL
    ,[IgnoreDependenciesInd]  BIT CONSTRAINT [DF_ETLPackage_IgnoreDependenciesInd] DEFAULT ((0)) NOT NULL
    ,[MaximumRetryAttempts]   INT CONSTRAINT [DF_ETLPackage_MaximumRetryAttempts] DEFAULT ((0)) NOT NULL
    ,[RemainingRetryAttempts] INT CONSTRAINT [DF_ETLPackage_RemainingRetryAttempts] DEFAULT ((0)) NOT NULL
    ,[ExecuteSundayInd]       BIT CONSTRAINT [DF_ETLPackage_ExecuteSundayInd] DEFAULT ((0)) NOT NULL
    ,[ExecuteMondayInd]       BIT CONSTRAINT [DF_ETLPackage_ExecuteMondayInd] DEFAULT ((0)) NOT NULL
    ,[ExecuteTuesdayInd]      BIT CONSTRAINT [DF_ETLPackage_ExecuteTuesdayInd] DEFAULT ((0)) NOT NULL
    ,[ExecuteWednesdayInd]    BIT CONSTRAINT [DF_ETLPackage_ExecuteWednesdayInd] DEFAULT ((0)) NOT NULL
    ,[ExecuteThursdayInd]     BIT CONSTRAINT [DF_ETLPackage_ExecuteThursdayInd] DEFAULT ((0)) NOT NULL
    ,[ExecuteFridayInd]       BIT CONSTRAINT [DF_ETLPackage_ExecuteFridayInd] DEFAULT ((0)) NOT NULL
    ,[ExecuteSaturdayInd]     BIT CONSTRAINT [DF_ETLPackage_ExecuteSaturdayInd] DEFAULT ((0)) NOT NULL
    ,[Use32BitDtExecInd]      BIT CONSTRAINT [DF_ETLPackage_Use32BitDtExecInd] DEFAULT ((0)) NOT NULL
    ,[SupportSeverityLevelId] INT NOT NULL
    ,[Comments]               VARCHAR (MAX) NULL
    ,[CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_ETLPackage_CreatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[CreatedUser]            VARCHAR (50) CONSTRAINT [DF_ETLPackage_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
    ,[LastUpdatedDate]        DATETIME2 (7) CONSTRAINT [DF_ETLPackage_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[LastUpdatedUser]        VARCHAR (50) CONSTRAINT [DF_ETLPackage_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLPackage] PRIMARY KEY CLUSTERED ([ETLPackageId] ASC),
     CONSTRAINT [FK_ETLPackage_EntryPointETLPackageId] FOREIGN KEY ([EntryPointETLPackageId]) REFERENCES [ctl].[ETLPackage] ([ETLPackageId]),
     CONSTRAINT [FK_ETLPackage_SupportSeverityLevel] FOREIGN KEY ([SupportSeverityLevelId]) REFERENCES [ref].[SupportSeverityLevel] ([SupportSeverityLevelId]),
     CONSTRAINT [AK_ETLPackage_SSISDBPackageName] UNIQUE NONCLUSTERED ([SSISDBPackageName] ASC) --ToDo: Needed to limit this to the package due to a possible bug related to joining on only package name and not on folder, project, and package.
  );

GO

EXECUTE sp_addextendedproperty
  @name = N'MS_Description'
 ,@value = N'Run regardless of dependency statuses. Good for dev/debug and potential prod scenarios. Initialize process should set to False.'
 ,@level0type = N'SCHEMA'
 ,@level0name = N'ctl'
 ,@level1type = N'TABLE'
 ,@level1name = N'ETLPackage'
 ,@level2type = N'COLUMN'
 ,@level2name = N'IgnoreDependenciesInd';

GO

EXECUTE sp_addextendedproperty
  @name = N'MS_Description'
 ,@value = N'If this package is executed via a parent/main package but an admin would like to execute it directly, this flag should be set to True.'
 ,@level0type = N'SCHEMA'
 ,@level0name = N'ctl'
 ,@level1type = N'TABLE'
 ,@level1name = N'ETLPackage'
 ,@level2type = N'COLUMN'
 ,@level2name = N'BypassEntryPointInd';

GO

EXECUTE sp_addextendedproperty
  @name = N'MS_Description'
 ,@value = N'Lets the control process know that the package should be picked up for execution. This will be set by the initialize process as well as manually when resetting after a failure.'
 ,@level0type = N'SCHEMA'
 ,@level0name = N'ctl'
 ,@level1type = N'TABLE'
 ,@level1name = N'ETLPackage'
 ,@level2type = N'COLUMN'
 ,@level2name = N'ReadyForExecutionInd';

GO

EXECUTE sp_addextendedproperty
  @name = N'MS_Description'
 ,@value = N'Indicates whether the package should be included for execution and dependency checks regardless of whether it is an entry point package.'
 ,@level0type = N'SCHEMA'
 ,@level0name = N'ctl'
 ,@level1type = N'TABLE'
 ,@level1name = N'ETLPackage'
 ,@level2type = N'COLUMN'
 ,@level2name = N'EnabledInd';

GO

EXECUTE sp_addextendedproperty
  @name = N'MS_Description'
 ,@value = N'If this package is executed via a parent/main package, this is the Id of that package.'
 ,@level0type = N'SCHEMA'
 ,@level0name = N'ctl'
 ,@level1type = N'TABLE'
 ,@level1name = N'ETLPackage'
 ,@level2type = N'COLUMN'
 ,@level2name = 'EntryPointETLPackageId';

GO 
