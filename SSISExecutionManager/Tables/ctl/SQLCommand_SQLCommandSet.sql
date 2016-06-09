CREATE TABLE [ctl].[SQLCommand_SQLCommandSet]
  (
     [SQLCommand_SQLCommandSetId]  INT IDENTITY(1, 1) NOT NULL
     ,[SQLCommandId]               INT NOT NULL
     ,[SQLCommandSetId]            INT NOT NULL
     ,[EnabledInd]                 BIT CONSTRAINT [DF_SQLCommand_SQLCommandSet_EnabledInd] DEFAULT (1) NOT NULL
     ,[SQLCommandDependencyTypeId] INT CONSTRAINT [DF_SQLCommand_SQLCommandSet_SQLCommandDependencyTypeId] DEFAULT (1) NOT NULL
     ,[FailBatchOnFailureInd]      BIT CONSTRAINT [DF_SQLCommand_SQLCommandSet_FailBatchOnFailureInd] DEFAULT (0) NOT NULL
     ,[ExecutionOrder]             SMALLINT CONSTRAINT [DF_SQLCommand_SQLCommandSet_ExecutionOrder] DEFAULT (1) NOT NULL
     ,[Comments]                   VARCHAR (MAX) NULL
     ,[CreatedDate]                DATETIME2 (7) CONSTRAINT [DF_SQLCommand_SQLCommandSet_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                VARCHAR (50) CONSTRAINT [DF_SQLCommand_SQLCommandSet_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_SQLCommand_SQLCommandSet] PRIMARY KEY ([SQLCommand_SQLCommandSetId]),
     CONSTRAINT [AK_SQLCommand_SQLCommandSet_ETLPackageId_ETLPackageSetId] UNIQUE ([SQLCommandId], [SQLCommandSetId]),
     CONSTRAINT [FK_SQLCommand_SQLCommandSet_ETLPackage] FOREIGN KEY ([SQLCommandId]) REFERENCES ctl.[SQLCommand]([SQLCommandId]),
     CONSTRAINT [FK_SQLCommand_SQLCommandSet_ETLPackageSet] FOREIGN KEY (SQLCommandSetId) REFERENCES ctl.SQLCommandSet(SQLCommandSetId),
     CONSTRAINT [FK_SQLCommandSet_SQLCommandDependencyType] FOREIGN KEY (SQLCommandDependencyTypeId) REFERENCES [ref].[SQLCommandDependencyType]([SQLCommandDependencyTypeId])
  )

GO 
