CREATE TABLE [ctl].[ETLPackageGroup_ETLPackage]
  (
     [ETLPackageGroup_ETLPackageId] INT IDENTITY(1, 1) NOT NULL
    ,[ETLPackageGroupId]            INT NOT NULL
    ,[ETLPackageId]                 INT NOT NULL
	,[IgnoreForBatchCompleteInd]    BIT CONSTRAINT [DF_ETLPackageGroup_ETLPackage_IgnoreForBatchCompleteInd] DEFAULT (0) NOT NULL
    ,[EnabledInd]                   BIT CONSTRAINT [DF_ETLPackageGroup_ETLPackage_EnabledInd] DEFAULT (1) NOT NULL
    ,[CreatedDate]                  DATETIME2 (7) CONSTRAINT [DF_ETLPackageGroup_ETLPackage_CreatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[CreatedUser]                  VARCHAR (50) CONSTRAINT [DF_ETLPackageGroup_ETLPackage_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
    ,[LastUpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_ETLPackageGroup_ETLPackage_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[LastUpdatedUser]              VARCHAR (50) CONSTRAINT [DF_ETLPackageGroup_ETLPackage_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     CONSTRAINT [PK_ETLPackageGroup_ETLPackage_ETLPackage] PRIMARY KEY ([ETLPackageGroup_ETLPackageId]),
     CONSTRAINT [AK_ETLPackageGroup_ETLPackage_ETLPackage_ETLPackageGroupId_ETLPackageId] UNIQUE ([ETLPackageGroupId], [ETLPackageId]),
     CONSTRAINT [FK_ETLPackageGroup_ETLPackage_ETLPackage_ETLPackageGroup] FOREIGN KEY ([ETLPackageGroupId]) REFERENCES ctl.[ETLPackageGroup]([ETLPackageGroupId]),
     CONSTRAINT [FK_ETLPackageGroup_ETLPackage_ETLPackage_ETLPackage] FOREIGN KEY (ETLPackageId) REFERENCES ctl.[ETLPackage]([ETLPackageId]),
  )

GO 
