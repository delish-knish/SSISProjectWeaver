CREATE TABLE [ctl].[ETLBatchPhase]
  (
     [ETLBatchPhaseId]				INT IDENTITY (1,1) NOT NULL
     ,[ETLBatchPhase]				VARCHAR(50) NULL
     ,[CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_ETLBatchPackageSetPhase_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                 VARCHAR (50) CONSTRAINT [DF_ETLBatchPackageSetPhase_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_ETLBatchPackageSetPhase_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]             VARCHAR (50) CONSTRAINT [DF_ETLBatchPackageSetPhase_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLBatchPackageSetPhase] PRIMARY KEY ([ETLBatchPhaseId]),
  ) 
