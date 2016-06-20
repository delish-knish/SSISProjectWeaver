CREATE TABLE [ctl].[ETLBatch_ETLBatchPhase]
  (
     [ETLBatch_ETLBatchPhaseId]				INT IDENTITY(1, 1) NOT NULL
     ,[ETLBatchId]							INT NOT NULL
     ,[ETLBatchPhaseId]						INT NOT NULL
	 ,[PhaseExecutionOrderNo]				INT CONSTRAINT [DF_ETLBatch_ETLBatchPhase_PhaseExecutionOrderNo] DEFAULT (0) NOT NULL
     ,[CreatedDate]							DATETIME2 (7) CONSTRAINT [DF_ETLBatch_ETLBatchPhase_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]							VARCHAR (50) CONSTRAINT [DF_ETLBatch_ETLBatchPhase_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLBatch_ETLBatchPhase] PRIMARY KEY ([ETLBatch_ETLBatchPhaseId]),
     CONSTRAINT [AK_ETLBatch_ETLBatchPhase_ETLBatchId_ETLBatchPhaseId] UNIQUE ([ETLBatchId], ETLBatchPhaseId),
     CONSTRAINT [FK_ETLBatch_ETLBatchPhase_ETLBatch] FOREIGN KEY ([ETLBatchId]) REFERENCES ctl.[ETLBatch]([ETLBatchId]),
     CONSTRAINT [FK_ETLBatch_ETLBatchPhase_ETLBatchPhase] FOREIGN KEY (ETLBatchPhaseId) REFERENCES ctl.[ETLBatchPhase]([ETLBatchPhaseId]),
  )

GO 
