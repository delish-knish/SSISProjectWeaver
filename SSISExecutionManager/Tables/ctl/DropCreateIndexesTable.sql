CREATE TABLE [ctl].[DropCreateIndexesTable]
(
   [DropCreateIndexesTableId]  INT IDENTITY (1, 1) NOT NULL
   ,[SchemaName]               VARCHAR(255) NOT NULL
   ,[TableName]                VARCHAR(255) NOT NULL
   ,[IncludeClusteredIndexInd] BIT NOT NULL
   ,[OnlyIfEmptyInd]           BIT NOT NULL
   ,[CreatedDate]              DATETIME CONSTRAINT [DF_DropCreateIndexesTable_CreatedDate] DEFAULT (GETDATE()) NOT NULL
   ,[CreatedUser]              VARCHAR (100) CONSTRAINT [DF_DropCreateIndexesTable_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
   ,[LastUpdatedDate]          DATETIME CONSTRAINT [DF_DropCreateIndexesTable_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
   ,[LastUpdatedUser]          VARCHAR (100) CONSTRAINT [DF_DropCreateIndexesTable_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
   CONSTRAINT [PK_DropCreateIndexesTable] PRIMARY KEY CLUSTERED ([DropCreateIndexesTableId] ASC),
   CONSTRAINT [UK_DropCreateIndexesTable_SchemaName_TableName] UNIQUE (SchemaName, TableName)
);

GO 