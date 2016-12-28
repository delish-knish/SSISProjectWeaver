CREATE TABLE [ctl].[ETLPackageGroup_ETLPackageGroupDependency]
  (
     [ETLPackageGroup_ETLPackageGroupDependencyId]  INT IDENTITY(1, 1) NOT NULL
     ,[ETLPackageGroupId]           INT NOT NULL
     ,[DependedOnETLPackageGroupId] INT NOT NULL
     ,[EnabledInd]             BIT CONSTRAINT [DF_ETLPackageGroup_ETLPackageGroupDependency_PackageEnabledInd] DEFAULT ((1)) NOT NULL
     ,[Comments]               VARCHAR(MAX) NULL
     ,[CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_ETLPackageGroup_ETLPackageGroupDependency_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]            VARCHAR (50) CONSTRAINT [DF_ETLPackageGroup_ETLPackageGroupDependency_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]        DATETIME2 (7) CONSTRAINT [DF_ETLPackageGroup_ETLPackageGroupDependency_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]        VARCHAR (50) CONSTRAINT [DF_ETLPackageGroup_ETLPackageGroupDependency_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLPackageGroup_ETLPackageGroupDependency] PRIMARY KEY ([ETLPackageGroup_ETLPackageGroupDependencyId]),
     CONSTRAINT [FK_ETLPackageGroup_ETLPackageGroupDependency_ETLPackageGroup] FOREIGN KEY (ETLPackageGroupId) REFERENCES [ctl].ETLPackageGroup(ETLPackageGroupId),
     CONSTRAINT [FK_ETLPackageGroup_ETLPackageGroupDependency_ETLPackage_DependentOn] FOREIGN KEY ([DependedOnETLPackageGroupId]) REFERENCES [ctl].ETLPackageGroup(ETLPackageGroupId),
     CONSTRAINT [AK_ETLPackageGroup_ETLPackageGroupDependency_ETLPackageId_DependentOnETLPackageId] UNIQUE (ETLPackageGroupId, [DependedOnETLPackageGroupId]),
  ) 
