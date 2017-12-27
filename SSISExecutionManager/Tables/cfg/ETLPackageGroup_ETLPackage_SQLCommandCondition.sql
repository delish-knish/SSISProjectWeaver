CREATE TABLE [cfg].[ETLPackageGroup_ETLPackage_SQLCommandCondition]
  (
     [ETLPackageGroup_ETLPackage_SQLCommandConditionId] INT IDENTITY(1, 1) NOT NULL
     ,[ETLPackageGroup_ETLPackageId]                    INT NULL
     ,[SQLCommandId]                                    INT NOT NULL
     ,[EnabledInd]                                      BIT CONSTRAINT [DF_ETLPackageGroup_ETLPackage_SQLCommandCondition_EnabledInd] DEFAULT (0) NOT NULL
     ,[NotificationOnConditionMetEnabledInd]            BIT CONSTRAINT [DF_ETLPackageGroup_ETLPackage_SQLCommandCondition_NotificationOnConditionMetEnabledInd] DEFAULT (0) NOT NULL
     ,[NotificationOnConditionNotMetEnabledInd]         BIT CONSTRAINT [DF_ETLPackageGroup_ETLPackage_SQLCommandCondition_NotificationOnConditionNotMetEnabledInd] DEFAULT (0) NOT NULL
     ,[NotificationEmailConfigurationCd]				VARCHAR(50) NULL
	 ,[CreatedDate]                                     DATETIME2 (7) CONSTRAINT [DF_ETLPackageGroup_ETLPackage_SQLCommandCondition_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                                     VARCHAR (50) CONSTRAINT [DF_ETLPackageGroup_ETLPackage_SQLCommandCondition_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]                                 DATETIME2 (7) CONSTRAINT [DF_ETLPackageGroup_ETLPackage_SQLCommandCondition_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]                                 VARCHAR (50) CONSTRAINT [DF_ETLPackageGroup_ETLPackage_SQLCommandCondition_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     CONSTRAINT [PK_ETLPackageGroup_ETLPackage_SQLCommandCondition] PRIMARY KEY ([ETLPackageGroup_ETLPackage_SQLCommandConditionId]),
     CONSTRAINT [AK_ETLPackageGroup_ETLPackage_SQLCommandCondition_ETLPackageGroup_ETLPackageId_SQLCommandId] UNIQUE ([ETLPackageGroup_ETLPackageId], [SQLCommandId]),
     CONSTRAINT [FK_ETLPackageGroup_ETLPackage_SQLCommandCondition_ETLPackageGroup_ETLPackage] FOREIGN KEY ([ETLPackageGroup_ETLPackageId]) REFERENCES [cfg].[ETLPackageGroup_ETLPackage]([ETLPackageGroup_ETLPackageId]),
     CONSTRAINT [FK_ETLPackageGroup_ETLPackage_SQLCommandCondition_SQLCommand] FOREIGN KEY (SQLCommandId) REFERENCES [cfg].SQLCommand(SQLCommandId),
  )

GO 
