CREATE TABLE [cfg].[ETLPackage]
  (
     [ETLPackageId]                 INT IDENTITY (1, 1) NOT NULL
     ,[SSISDBFolderName]            NVARCHAR (128) NOT NULL
     ,[SSISDBProjectName]           NVARCHAR (128) NOT NULL
     ,[SSISDBPackageName]           NVARCHAR (260) NOT NULL
     ,[EntryPointPackageInd] AS ( CONVERT([BIT], CASE
                            WHEN [EntryPointETLPackageId] IS NULL THEN ( 1 )
                            ELSE ( 0 )
                          END) )
     ,[EntryPointETLPackageId]      INT NULL
     ,[HasParamETLBatchExecutionId] BIT CONSTRAINT [DF_ETLPackage_HasParamETLBatchExecutionId] DEFAULT ((0)) NOT NULL
     ,[Use32BitDtExecInd]           BIT CONSTRAINT [DF_ETLPackage_Use32BitDtExecInd] DEFAULT ((0)) NOT NULL
     ,[Comments]                    VARCHAR (MAX) NULL
     ,[CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_ETLPackage_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                 VARCHAR (50) CONSTRAINT [DF_ETLPackage_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_ETLPackage_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]             VARCHAR (50) CONSTRAINT [DF_ETLPackage_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLPackage] PRIMARY KEY CLUSTERED ([ETLPackageId] ASC),
     CONSTRAINT [FK_ETLPackage_EntryPointETLPackageId] FOREIGN KEY ([EntryPointETLPackageId]) REFERENCES [cfg].[ETLPackage] ([ETLPackageId]),
     CONSTRAINT [AK_ETLPackage_SSISDBPackageName] UNIQUE NONCLUSTERED ([SSISDBPackageName] ASC) --ToDo: Needed to limit this to the package due to a possible bug related to joining on only package name and not on folder, project, and package.

  );

GO

EXECUTE sp_addextendedproperty
  @name = N'MS_Description',
  @value = N'If this package is executed via a parent/main package, this is the Id of that package.',
  @level0type = N'SCHEMA',
  @level0name = N'cfg',
  @level1type = N'TABLE',
  @level1name = N'ETLPackage',
  @level2type = N'COLUMN',
  @level2name = 'EntryPointETLPackageId';

GO 
