CREATE TABLE [ctl].[ETLPackageSet]
  (
     [ETLPackageSetId]           INT IDENTITY(1, 1) NOT NULL
     ,[ETLPackageSetName]        VARCHAR(250) NOT NULL
     ,[ETLPackageSetDescription] VARCHAR(MAX) NOT NULL
     ,[CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_ETLPackageSet_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]              VARCHAR (50) CONSTRAINT [DF_ETLPackageSet_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_ETLPackageSet_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]          VARCHAR (50) CONSTRAINT [DF_ETLPackageSet_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLPackageSet] PRIMARY KEY ([ETLPackageSetId]),
  )

GO 
