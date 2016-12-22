CREATE TABLE [ctl].[ETLPackageGroup_SQLCommand]
  (
     [ETLPackageGroup_SQLCommandId] INT IDENTITY(1, 1) NOT NULL
    ,[ETLPackageGroupId]            INT NOT NULL
    ,[SQLCommandId]                 INT NOT NULL
    ,[ExecuteAtBeginningOfGroupInd] BIT CONSTRAINT [DF_ETLPackageGroup_SQLCommand_SQLCommand_ExecuteAtBeginningOfGroupInd] DEFAULT (0) NOT NULL
    ,[ExecuteAtEndOfGroupInd]       BIT CONSTRAINT [DF_ETLPackageGroup_SQLCommand_SQLCommand_ExecuteAtEndOfGroupInd] DEFAULT (0) NOT NULL
    ,[FailBatchOnFailureInd]        BIT CONSTRAINT [DF_ETLPackageGroup_SQLCommand_SQLCommand_FailBatchOnFailureInd] DEFAULT (0) NOT NULL
    ,[ExecutionOrder]               SMALLINT CONSTRAINT [DF_ETLPackageGroup_SQLCommand_SQLCommand_ExecutionOrder] DEFAULT (0) NOT NULL
    ,[EnabledInd]                   BIT CONSTRAINT [DF_ETLPackageGroup_SQLCommand_EnabledInd] DEFAULT (0) NOT NULL
    ,[Comments]                     VARCHAR (MAX) NULL
    ,[CreatedDate]                  DATETIME2 (7) CONSTRAINT [DF_ETLPackageGroup_SQLCommand_SQLCommand_CreatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[CreatedUser]                  VARCHAR (50) CONSTRAINT [DF_ETLPackageGroup_SQLCommand_SQLCommand_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
    ,[LastUpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_ETLPackageGroup_SQLCommand_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[LastUpdatedUser]              VARCHAR (50) CONSTRAINT [DF_ETLPackageGroup_SQLCommand_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     CONSTRAINT [PK_ETLPackageGroup_SQLCommand_SQLCommand] PRIMARY KEY ([ETLPackageGroup_SQLCommandId]),
     CONSTRAINT [AK_ETLPackageGroup_SQLCommand_SQLCommand_ETLPackageGroupId_SQLCommandId] UNIQUE ([ETLPackageGroupId], [SQLCommandId]),
     CONSTRAINT [FK_ETLPackageGroup_SQLCommand_SQLCommand_ETLPackageGroup] FOREIGN KEY ([ETLPackageGroupId]) REFERENCES ctl.[ETLPackageGroup]([ETLPackageGroupId]),
     CONSTRAINT [FK_ETLPackageGroup_SQLCommand_SQLCommand_SQLCommand] FOREIGN KEY (SQLCommandId) REFERENCES ctl.[SQLCommand]([SQLCommandId]),
  )

GO 
