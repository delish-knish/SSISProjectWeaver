CREATE TABLE [ctl].[ETLPackage_SQLCommandCondition]
  (
     [ETLPackage_SQLCommandConditionId]	INT IDENTITY(1, 1) NOT NULL
     ,[ETLPackageId]					INT NOT NULL
     ,[SQLCommandId]					INT NOT NULL
     ,[EnabledInd]						BIT CONSTRAINT [DF_ETLPackage_EnabledInd] DEFAULT (0) NOT NULL
     ,[CreatedDate]						DATETIME2 (7) CONSTRAINT [DF_ETLPackage_SQLCommandCondition_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]						VARCHAR (50) CONSTRAINT [DF_ETLPackage_SQLCommandCondition_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]					DATETIME2 (7) CONSTRAINT [DF_ETLPackage_SQLCommandCondition_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]					VARCHAR (50) CONSTRAINT [DF_ETLPackage_SQLCommandCondition_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     CONSTRAINT [PK_ETLPackage_SQLCommandCondition] PRIMARY KEY ([ETLPackage_SQLCommandConditionId]),
     CONSTRAINT [AK_ETLPackage_SQLCommandCondition_ETLPackageId_SQLCommandId] UNIQUE ([ETLPackageId], [SQLCommandId]),
     CONSTRAINT [FK_ETLPackage_SQLCommandCondition_ETLPackage] FOREIGN KEY ([ETLPackageId]) REFERENCES ctl.[ETLPackage]([ETLPackageId]),
     CONSTRAINT [FK_ETLPackage_SQLCommandCondition_SQLCommand] FOREIGN KEY (SQLCommandId) REFERENCES ctl.SQLCommand(SQLCommandId),
  )

GO 
