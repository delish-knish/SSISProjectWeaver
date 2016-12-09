CREATE TABLE [ctl].[ETLBatchPhase_ETLPackage]
  (
     [ETLBatchPhase_ETLPackageId]	INT IDENTITY(1, 1) NOT NULL
     ,[ETLBatchPhaseId]				INT NOT NULL
	 ,[ETLPackageId]				INT NOT NULL
     ,[EnabledInd]                  BIT CONSTRAINT [DF_ETLBatchPhase_ETLPackage_EnabledInd] DEFAULT (1) NOT NULL
     ,[CreatedDate]					DATETIME2 (7) CONSTRAINT [DF_ETLBatchPhase_ETLPackage_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]					VARCHAR (50) CONSTRAINT [DF_ETLBatchPhase_ETLPackage_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]				DATETIME2 (7) CONSTRAINT [DF_ETLBatchPhase_ETLPackage_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]				VARCHAR (50) CONSTRAINT [DF_ETLBatchPhase_ETLPackage_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     CONSTRAINT [PK_ETLBatchPhase_ETLPackage_ETLPackage] PRIMARY KEY ([ETLBatchPhase_ETLPackageId]),
     CONSTRAINT [AK_ETLBatchPhase_ETLPackage_ETLPackage_ETLBatchPhaseId_ETLPackageId] UNIQUE ([ETLBatchPhaseId], [ETLPackageId]),
     CONSTRAINT [FK_ETLBatchPhase_ETLPackage_ETLPackage_ETLBatchPhase] FOREIGN KEY ([ETLBatchPhaseId]) REFERENCES ctl.[ETLBatchPhase]([ETLBatchPhaseId]),
     CONSTRAINT [FK_ETLBatchPhase_ETLPackage_ETLPackage_ETLPackage] FOREIGN KEY (ETLPackageId) REFERENCES ctl.[ETLPackage]([ETLPackageId]),
  )

GO 
