CREATE TABLE [ref].[SSISDBLoggingLevel]
  (
     [SSISDBLoggingLevelId] INT NOT NULL
    ,[SSISDBLoggingLevel]   VARCHAR(50) NULL
    ,[CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_SSISDBLoggingLevel_CreatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[CreatedUser]          VARCHAR (50) CONSTRAINT [DF_SSISDBLoggingLevel_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
    ,[LastUpdatedDate]      DATETIME2 (7) CONSTRAINT [DF_SSISDBLoggingLevel_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[LastUpdatedUser]      VARCHAR (50) CONSTRAINT [DF_SSISDBLoggingLevel_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_SSISDBLoggingLevel] PRIMARY KEY ([SSISDBLoggingLevelId]),
  ) 
