CREATE TABLE [log].[ForeignKeyConstraintViolation]
  (
     [FKConstraintViolationId] INT IDENTITY(1, 1) NOT NULL
    ,[DatabaseName]            VARCHAR(128) NOT NULL 
    ,[TableName]               VARCHAR(128) NOT NULL
    ,[ColumnName]              VARCHAR(128) NOT NULL
    ,[RelatedTableName]        VARCHAR(128) NOT NULL
    ,[ConstraintName]          VARCHAR(128) NOT NULL
    ,[InvalidValue]            NVARCHAR(4000) NOT NULL
    ,[OccurrenceCount]         INT NOT NULL CONSTRAINT [DF_DHConstraintViolation_OccurrenceCount] DEFAULT ((-1))
    ,[CreatedDate]             DATETIME2(7) NOT NULL CONSTRAINT [DF_DHConstraintViolation_CreatedDate] DEFAULT (GETDATE())
    ,[CreatedUser]             NVARCHAR(100) NOT NULL CONSTRAINT [DF_DHConstraintViolation_CreatedUser] DEFAULT (SUSER_SNAME())
  ) 
