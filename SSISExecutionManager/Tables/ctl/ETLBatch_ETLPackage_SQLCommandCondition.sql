CREATE TABLE [ctl].[ETLBatch_ETLPackage_SQLCommandCondition]
  (
     [ETLBatch_ETLPackage_SQLCommandConditionId]	INT IDENTITY(1, 1) NOT NULL
	 ,[ETLBatchId]					    INT NULL
     ,[ETLPackageId]					INT NOT NULL
     ,[SQLCommandId]					INT NOT NULL
     ,[EnabledInd]						BIT CONSTRAINT [DF_ETLPackage_EnabledInd] DEFAULT (0) NOT NULL
     ,[CreatedDate]						DATETIME2 (7) CONSTRAINT [DF_ETLBatch_ETLPackage_SQLCommandCondition_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]						VARCHAR (50) CONSTRAINT [DF_ETLBatch_ETLPackage_SQLCommandCondition_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]					DATETIME2 (7) CONSTRAINT [DF_ETLBatch_ETLPackage_SQLCommandCondition_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]					VARCHAR (50) CONSTRAINT [DF_ETLBatch_ETLPackage_SQLCommandCondition_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     CONSTRAINT [PK_ETLBatch_ETLPackage_SQLCommandCondition] PRIMARY KEY ([ETLBatch_ETLPackage_SQLCommandConditionId]),
     CONSTRAINT [AK_ETLBatch_ETLPackage_SQLCommandCondition_ETLPackageId_SQLCommandId] UNIQUE ([ETLBatchId], [ETLPackageId], [SQLCommandId]),
     CONSTRAINT [FK_ETLBatch_ETLPackage_SQLCommandCondition_ETLPackage] FOREIGN KEY ([ETLPackageId]) REFERENCES ctl.[ETLPackage]([ETLPackageId]),
     CONSTRAINT [FK_ETLBatch_ETLPackage_SQLCommandCondition_SQLCommand] FOREIGN KEY (SQLCommandId) REFERENCES ctl.SQLCommand(SQLCommandId), 
    CONSTRAINT [FK_ETLBatch_ETLBatch_ETLPackage_SQLCommandCondition_ETLBatch] FOREIGN KEY ([ETLBatchId]) REFERENCES ctl.ETLBatch([ETLBatchId]),
  )

GO 
