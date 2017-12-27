CREATE TABLE [cfg].[ETLPackageGroup]
  (
     [ETLPackageGroupId]				INT IDENTITY (1,1) NOT NULL
     ,[ETLPackageGroup]				VARCHAR(50) NULL
     ,[CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_ETLETLPackageGroup_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                 VARCHAR (50) CONSTRAINT [DF_ETLETLPackageGroup_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_ETLETLPackageGroup_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]             VARCHAR (50) CONSTRAINT [DF_ETLETLPackageGroup_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLETLPackageGroup] PRIMARY KEY ([ETLPackageGroupId]),
  ) 
