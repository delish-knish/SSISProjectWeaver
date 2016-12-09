CREATE TABLE [ctl].[ETLBatchPhase_SQLCommand]
  (
     [ETLBatchPhase_SQLCommandId]		INT IDENTITY(1, 1) NOT NULL
     ,[ETLBatchPhaseId]					INT NOT NULL
	 ,[SQLCommandId]					INT NOT NULL
	 ,[ExecuteAtBeginningOfPhaseInd]	BIT CONSTRAINT [DF_ETLBatchPhase_SQLCommand_SQLCommand_ExecuteAtBeginningOfPhaseInd] DEFAULT (0) NOT NULL
	 ,[ExecuteAtEndOfPhaseInd]			BIT CONSTRAINT [DF_ETLBatchPhase_SQLCommand_SQLCommand_ExecuteAtEndOfPhaseInd] DEFAULT (0) NOT NULL
     ,[FailBatchOnFailureInd]			BIT CONSTRAINT [DF_ETLBatchPhase_SQLCommand_SQLCommand_FailBatchOnFailureInd] DEFAULT (0) NOT NULL
	 ,[ExecutionOrder]					SMALLINT CONSTRAINT [DF_ETLBatchPhase_SQLCommand_SQLCommand_ExecutionOrder] DEFAULT (0) NOT NULL
     ,[EnabledInd]						BIT CONSTRAINT [DF_ETLBatchPhase_SQLCommand_EnabledInd] DEFAULT (0) NOT NULL
	 ,[Comments]						VARCHAR (MAX) NULL
	 ,[CreatedDate]						DATETIME2 (7) CONSTRAINT [DF_ETLBatchPhase_SQLCommand_SQLCommand_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]						VARCHAR (50) CONSTRAINT [DF_ETLBatchPhase_SQLCommand_SQLCommand_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]					DATETIME2 (7) CONSTRAINT [DF_ETLBatchPhase_SQLCommand_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]					VARCHAR (50) CONSTRAINT [DF_ETLBatchPhase_SQLCommand_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     CONSTRAINT [PK_ETLBatchPhase_SQLCommand_SQLCommand] PRIMARY KEY ([ETLBatchPhase_SQLCommandId]),
     CONSTRAINT [AK_ETLBatchPhase_SQLCommand_SQLCommand_ETLBatchPhaseId_SQLCommandId] UNIQUE ([ETLBatchPhaseId], [SQLCommandId]),
     CONSTRAINT [FK_ETLBatchPhase_SQLCommand_SQLCommand_ETLBatchPhase] FOREIGN KEY ([ETLBatchPhaseId]) REFERENCES ctl.[ETLBatchPhase]([ETLBatchPhaseId]),
     CONSTRAINT [FK_ETLBatchPhase_SQLCommand_SQLCommand_SQLCommand] FOREIGN KEY (SQLCommandId) REFERENCES ctl.[SQLCommand]([SQLCommandId]),
  )

GO 
