CREATE TABLE [ctl].[ETLPackage_DropCreateIndexesTable]
  (
     [ETLPackage_DropCreateIndexesTableId]	INT IDENTITY(1, 1) NOT NULL
     ,[ETLPackageId]						INT NOT NULL
     ,[DropCreateIndexesTableId]			INT NOT NULL
     ,[EnabledInd]							BIT CONSTRAINT [DF_ETLPackage_DropCreateIndexesTable_EnabledInd] DEFAULT (0) NOT NULL
     ,[CreatedDate]							DATETIME2 (7) CONSTRAINT [DF_ETLPackage_DropCreateIndexesTable_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]							VARCHAR (50) CONSTRAINT [DF_ETLPackage_DropCreateIndexesTable_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]						DATETIME2 (7) CONSTRAINT [DF_ETLPackage_DropCreateIndexesTable_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]						VARCHAR (50) CONSTRAINT [DF_ETLPackage_DropCreateIndexesTable_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     CONSTRAINT [PK_ETLPackage_DropCreateIndexesTable] PRIMARY KEY ([ETLPackage_DropCreateIndexesTableId]),
     CONSTRAINT [AK_ETLPackage_DropCreateIndexesTable_ETLPackageId_DropCreateIndexesTableId] UNIQUE ([ETLPackageId], [DropCreateIndexesTableId]),
     CONSTRAINT [FK_ETLPackage_DropCreateIndexesTable_ETLPackage] FOREIGN KEY ([ETLPackageId]) REFERENCES ctl.[ETLPackage]([ETLPackageId]),
     CONSTRAINT [FK_ETLPackage_DropCreateIndexesTable_DropCreateIndexesTable] FOREIGN KEY (DropCreateIndexesTableId) REFERENCES ctl.DropCreateIndexesTable(DropCreateIndexesTableId),
  )

GO 
