CREATE TABLE [ctl].[SQLCommandSet]
  (
     [SQLCommandSetId]                INT IDENTITY(1, 1) NOT NULL
     ,[SQLCommandSetName]             VARCHAR(250) NOT NULL
     ,[SQLCommandSetDescription]      VARCHAR(MAX) NOT NULL
     ,[CreatedDate]                   DATETIME2 (7) CONSTRAINT [DF_SQLCommandSet_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                   VARCHAR (50) CONSTRAINT [DF_SQLCommandSet_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]               DATETIME2 (7) CONSTRAINT [DF_SQLCommandSet_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]               VARCHAR (50) CONSTRAINT [DF_SQLCommandSet_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_SQLCommandSet] PRIMARY KEY ([SQLCommandSetId]),
  )

GO 
