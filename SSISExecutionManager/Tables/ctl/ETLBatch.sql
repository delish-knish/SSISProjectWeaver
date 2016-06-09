CREATE TABLE [ctl].[ETLBatch]
  (
     [ETLBatchId]                                         INT IDENTITY(1, 1) NOT NULL
     ,[SQLAgentJobName]                                   VARCHAR(250) NOT NULL
     ,[SSISEnvironmentName]                               VARCHAR(128)
     ,[ETLPackageSetId]                                   INT CONSTRAINT [DF_ETLBatch_ETLPackageSetId] DEFAULT (0) NOT NULL
     ,[StartDateTime]                                     DATETIME2 CONSTRAINT [DF_ETLBatch_StartDateTime] DEFAULT (GETDATE()) NOT NULL
     ,[EndDateTime]                                       DATETIME2 NULL
     ,[ExecutionDurationInMinutes] AS DATEDIFF(MINUTE, StartDateTime, EndDateTime)
     ,[DayOfWeekName] AS DATENAME (WEEKDAY, [StartDateTime])
     ,[ETLBatchStatusId]                                  INT NULL
     ,[TotalEntryPointPackageCount]                       SMALLINT NULL
     ,[TotalRemainingEntryPointPackageCount]              SMALLINT NULL
     ,[TotalETLPackageCount]                              SMALLINT NULL
     ,[TotalRemainingETLPackageCount]                     SMALLINT NULL
     ,[CriticalPathPostTransformRemainingETLPackageCount] SMALLINT NULL
     ,[CriticalPathPostLoadRemainingETLPackageCount]      SMALLINT NULL
     ,[CreatedDate]                                       DATETIME2 (7) CONSTRAINT [DF_ETLBatch_CreatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[CreatedUser]                                       VARCHAR (50) CONSTRAINT [DF_ETLBatch_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
     ,[LastUpdatedDate]                                   DATETIME2 (7) CONSTRAINT [DF_ETLBatch_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
     ,[LastUpdatedUser]                                   VARCHAR (50) CONSTRAINT [DF_ETLBatch_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLBatch] PRIMARY KEY ([ETLBatchId]),
     CONSTRAINT [FK_ETLBatch_ETLBatchStatus] FOREIGN KEY (ETLBatchStatusId) REFERENCES ref.ETLBatchStatus([ETLBatchStatusId]), 
    CONSTRAINT [FK_ETLBatch_ETLPackageSet] FOREIGN KEY (ETLPackageSetId) REFERENCES ctl.ETLPackageSet(ETLPackageSetId),
  )

GO

CREATE INDEX [IX_ETLBatch_ETLBatchStatusId]
  ON [ctl].[ETLBatch] (ETLBatchStatusId) 
