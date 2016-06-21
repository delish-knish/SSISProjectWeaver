CREATE TABLE [log].[ETLPackageExecutionRowLevelError](
	[ETLPackageExecutionRowLevelErrorId] [bigint] IDENTITY(1,1) NOT NULL,
	[TableProcessRowKey] [varchar](250) NOT NULL,
	[LookupTableName] [varchar](250) NULL,
	[LookupTableRowKey] [varchar](250) NULL,
	[Comment] [varchar](1000) NULL,
	[ErrorDateTime] [datetime] NOT NULL,
	[CreatedDate] DATETIME2 (7) CONSTRAINT [DF_ETLPackageExecutionRowLevelError_CreatedDate] DEFAULT (GETDATE()) NOT NULL,
	[CreatedUser] VARCHAR (50) CONSTRAINT [DF_ETLPackageExecutionRowLevelError_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ETLPackageExecutionRowLevelErrorId] ASC
))