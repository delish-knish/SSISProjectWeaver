CREATE TABLE [cfg].[SQLCommand]
  (
     [SQLCommandId]                              INT IDENTITY (1, 1) NOT NULL
     ,[SQLCommandName]                           VARCHAR (128) NOT NULL
     ,[SQLCommand]                               NVARCHAR(MAX) NOT NULL
     ,[SQLCommandDescription]                    VARCHAR(MAX)
     ,[RequiresETLBatchIdParameterInd]           BIT CONSTRAINT [DF_SQLCommand_RequiresBatchIdParameter] DEFAULT 0 NOT NULL
     ,[RequiresEndETLBatchExecutionParameterInd] BIT CONSTRAINT [DF_SQLCommand_RequiresEndETLBatchExecutionParameterInd] DEFAULT 0 NOT NULL
     ,[CreatedDate]                              DATETIME2 (7) CONSTRAINT [DF_SQLCommand_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                              VARCHAR (50) CONSTRAINT [DF_SQLCommand_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]                          DATETIME2 (7) CONSTRAINT [DF_SQLCommand_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]                          VARCHAR (50) CONSTRAINT [DF_SQLCommand_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_SQLCommand] PRIMARY KEY CLUSTERED ([SQLCommandId] ASC),
     CONSTRAINT [AK_SQLCommand_Folder_Project_Package] UNIQUE NONCLUSTERED ([SQLCommandName] ASC),
  ) 
