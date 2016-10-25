CREATE TABLE [log].[ETLPackageExecutionRowLevelError]
  (
     [ETLPackageExecutionRowLevelErrorId] BIGINT IDENTITY(1, 1) NOT NULL
    ,[TableProcessRowKey]                 VARCHAR(250) NOT NULL
    ,[LookupTableName]                    VARCHAR(250) NULL
    ,[LookupTableRowKey]                  VARCHAR(250) NULL
    ,[ParentProcessName]                  VARCHAR(250) NULL
    ,[TargetTableName]                    VARCHAR(250) NULL
    ,[Description]                        VARCHAR(1000) NULL
    ,[ErrorDateTime]                      DATETIME NOT NULL
    ,[CreatedDate]                        DATETIME2 (7) CONSTRAINT [DF_ETLPackageExecutionRowLevelError_CreatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[CreatedUser]                        VARCHAR (50) CONSTRAINT [DF_ETLPackageExecutionRowLevelError_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     PRIMARY KEY CLUSTERED ( [ETLPackageExecutionRowLevelErrorId] ASC )
  ) 
