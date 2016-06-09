CREATE TABLE [ctl].[ETLPackage_ETLPackageSet]
  (
     [ETLPackage_ETLPackageSetId] INT IDENTITY(1, 1) NOT NULL
     ,[ETLPackageId]              INT NOT NULL
     ,[ETLPackageSetId]           INT NOT NULL
     ,[CreatedDate]               DATETIME2 (7) CONSTRAINT [DF_ETLPackage_ETLPackageSet_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]               VARCHAR (50) CONSTRAINT [DF_ETLPackage_ETLPackageSet_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLPackage_ETLPackageSet] PRIMARY KEY ([ETLPackage_ETLPackageSetId]),
     CONSTRAINT [AK_ETLPackage_ETLPackageSet_ETLPackageId_ETLPackageSetId] UNIQUE ([ETLPackageId], [ETLPackageSetId]),
     CONSTRAINT [FK_ETLPackage_ETLPackageSet_ETLPackage] FOREIGN KEY ([ETLPackageId]) REFERENCES ctl.[ETLPackage]([ETLPackageId]),
     CONSTRAINT [FK_ETLPackage_ETLPackageSet_ETLPackageSet] FOREIGN KEY (ETLPackageSetId) REFERENCES ctl.ETLPackageSet(ETLPackageSetId),
  )

GO 
