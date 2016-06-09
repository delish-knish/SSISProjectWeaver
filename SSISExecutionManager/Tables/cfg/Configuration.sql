CREATE TABLE [cfg].[Configuration]
  (
     [ConfigurationId]     INT IDENTITY(1, 1) NOT NULL
     ,[ConfigurationName]  VARCHAR(250) NOT NULL
     ,[ConfigurationValue] VARCHAR(MAX) NOT NULL
     ,[CreatedDate]        DATETIME2 (7) CONSTRAINT [DF_Configuration_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]        VARCHAR (50) CONSTRAINT [DF_Configuration_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]    DATETIME2 (7) CONSTRAINT [DF_Configuration_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]    VARCHAR (50) CONSTRAINT [DF_Configuration_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_Configuration] PRIMARY KEY ([ConfigurationId]),
     CONSTRAINT [AK_Configuration_ConfigurationName] UNIQUE (ConfigurationName),
  ) 
