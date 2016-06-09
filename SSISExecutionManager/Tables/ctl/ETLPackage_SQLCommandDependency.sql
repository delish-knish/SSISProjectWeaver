CREATE TABLE [ctl].[ETLPackage_SQLCommandDependency]
  (
     [ETLPackage_SQLCommandDependencyId] INT IDENTITY(1, 1) NOT NULL
     ,[ETLPackageId]                  INT NOT NULL
     ,[SQLCommandId]                  INT NOT NULL
     ,[EnabledInd]                    BIT CONSTRAINT [DF_ETLPackage_EnabledInd_CreatedDate] DEFAULT (0) NOT NULL
     ,[CreatedDate]                   DATETIME2 (7) CONSTRAINT [DF_ETLPackage_SQLCommandDependency_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                   VARCHAR (50) CONSTRAINT [DF_ETLPackage_SQLCommandDependency_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLPackage_SQLCommandDependency] PRIMARY KEY ([ETLPackage_SQLCommandDependencyId]),
     CONSTRAINT [AK_ETLPackage_SQLCommandDependency_ETLPackageId_SQLCommandId] UNIQUE ([ETLPackageId], [SQLCommandId]),
     CONSTRAINT [FK_ETLPackage_SQLCommandDependency_ETLPackage] FOREIGN KEY ([ETLPackageId]) REFERENCES ctl.[ETLPackage]([ETLPackageId]),
     CONSTRAINT [FK_ETLPackage_SQLCommandDependency_SQLCommand] FOREIGN KEY (SQLCommandId) REFERENCES ctl.SQLCommand(SQLCommandId),
  )

GO 
