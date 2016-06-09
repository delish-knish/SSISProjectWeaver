CREATE TABLE [ref].[SupportSeverityLevel]
  (
     [SupportSeverityLevelId]  INT NOT NULL
     ,[SupportSeverityLevelCd] VARCHAR (20) NOT NULL
     ,[SupportSeverityLevel]   VARCHAR (255) NULL
     ,[CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_SupportSeverityLevel_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]            VARCHAR (50) CONSTRAINT [DF_SupportSeverityLevel_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]        DATETIME2 (7) CONSTRAINT [DF_SupportSeverityLevel_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]        VARCHAR (50) CONSTRAINT [DF_SupportSeverityLevel_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_SupportSeverityLevel] PRIMARY KEY CLUSTERED ([SupportSeverityLevelId] ASC)
  ); 
