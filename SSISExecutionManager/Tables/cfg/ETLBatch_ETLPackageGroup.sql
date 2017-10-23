CREATE TABLE [cfg].[ETLBatch_ETLPackageGroup]
  (
     [ETLBatch_ETLPackageGroup] INT IDENTITY (1, 1) NOT NULL
    ,[ETLBatchId]               INT NOT NULL
    ,[ETLPackageGroupId]        INT NOT NULL
    ,[EnabledInd]               BIT CONSTRAINT [DF_ETLBatch_ETLPackageGroup_EnabledInd] DEFAULT ((1)) NOT NULL
    ,[CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_ETLBatch_ETLPackageGroup_CreatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[CreatedUser]              VARCHAR (50) CONSTRAINT [DF_ETLBatch_ETLPackageGroup_CreatedUser] DEFAULT (SUSER_SNAME()) NOT NULL
    ,[LastUpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_ETLBatch_ETLPackageGroup_LastUpdatedDate] DEFAULT (GETDATE()) NOT NULL
    ,[LastUpdatedUser]          VARCHAR (50) CONSTRAINT [DF_ETLBatch_ETLPackageGroup_LastUpdatedUser] DEFAULT (SUSER_SNAME()) NOT NULL,
     CONSTRAINT [PK_ETLBatch_ETLPackageGroup] PRIMARY KEY CLUSTERED ([ETLBatch_ETLPackageGroup] ASC),
     CONSTRAINT [FK_ETLBatch_ETLPackageGroup_ETLBatch] FOREIGN KEY ([ETLBatchId]) REFERENCES [ctl].[ETLBatch] ([ETLBatchId]),
     CONSTRAINT [FK_ETLBatch_ETLPackageGroup_ETLPackageGroup] FOREIGN KEY ([ETLPackageGroupId]) REFERENCES [cfg].[ETLPackageGroup] ([ETLPackageGroupId]),
     CONSTRAINT [AK_ETLBatch_ETLPackageGroup_ETLBatchId_ETLPackageGroupId] UNIQUE NONCLUSTERED ([ETLBatchId] ASC, [ETLPackageGroupId] ASC)
  );

GO 
