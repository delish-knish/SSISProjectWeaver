IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
                  WHERE TABLE_NAME = N'Sync_ETLPackageExecutionStatus')
      DROP TABLE Sync_ETLPackageExecutionStatus
      
CREATE TABLE Sync_ETLPackageExecutionStatus (
    [ETLPackageExecutionStatusId] INT NOT NULL 
     ,[ETLPackageExecutionStatus]  VARCHAR(50) NULL)

INSERT Sync_ETLPackageExecutionStatus (
     [ETLPackageExecutionStatusId]
	 ,[ETLPackageExecutionStatus] )
VALUES 
	(0,	'Succeeded'),
	(1, 'Failed'),
	(2, 'Completed'),
	(4, 'Canceled'),
	(5, 'Running'),
	(6, 'Waiting for Dependency'),
	(7, 'Unknown'),
	(8, 'Ready'),
	(10, 'Waiting to be called by Parent'),
	(11, 'Parent failed')

MERGE ref.ETLPackageExecutionStatus AS Target
USING Sync_ETLPackageExecutionStatus AS Source ON (Target.[ETLPackageExecutionStatusId] = Source.[ETLPackageExecutionStatusId])
WHEN MATCHED THEN
UPDATE SET Target.[ETLPackageExecutionStatus] = Source.[ETLPackageExecutionStatus]
WHEN NOT MATCHED BY TARGET THEN 
    INSERT ([ETLPackageExecutionStatusId], [ETLPackageExecutionStatus])
    VALUES ([ETLPackageExecutionStatusId], [ETLPackageExecutionStatus])

WHEN NOT MATCHED BY SOURCE THEN DELETE;

DROP TABLE Sync_ETLPackageExecutionStatus;
--------------------------------------------------

IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
                  WHERE TABLE_NAME = N'Sync_ETLPackageExecutionErrorType')
      DROP TABLE Sync_ETLPackageExecutionErrorType
      
CREATE TABLE Sync_ETLPackageExecutionErrorType (
    [ETLPackageExecutionErrorTypeId] INT NOT NULL 
     ,[ETLPackageExecutionErrorType]  VARCHAR(50) NULL)

INSERT Sync_ETLPackageExecutionErrorType (
     [ETLPackageExecutionErrorTypeId]
	 ,[ETLPackageExecutionErrorType] )
VALUES 
	(1,	'SSISDB Error'),
	(2, 'Unexpected Termination'),
	(3, 'Unhandled Exception')

MERGE ref.ETLPackageExecutionErrorType AS Target
USING Sync_ETLPackageExecutionErrorType AS Source ON (Target.[ETLPackageExecutionErrorTypeId] = Source.[ETLPackageExecutionErrorTypeId])
WHEN MATCHED THEN
UPDATE SET Target.[ETLPackageExecutionErrorType] = Source.[ETLPackageExecutionErrorType]
WHEN NOT MATCHED BY TARGET THEN 
    INSERT ([ETLPackageExecutionErrorTypeId], [ETLPackageExecutionErrorType])
    VALUES ([ETLPackageExecutionErrorTypeId], [ETLPackageExecutionErrorType])

WHEN NOT MATCHED BY SOURCE THEN DELETE;

DROP TABLE Sync_ETLPackageExecutionErrorType;
--------------------------------------------------


IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
                  WHERE TABLE_NAME = N'Sync_ETLExecutionStatus')
      DROP TABLE Sync_ETLExecutionStatus
      
CREATE TABLE Sync_ETLExecutionStatus (
      [ETLExecutionStatusId] INT NOT NULL 
     ,[ETLExecutionStatus]  VARCHAR(50) NULL)

INSERT Sync_ETLExecutionStatus (
      [ETLExecutionStatusId]
	 ,[ETLExecutionStatus] )
VALUES 
	(1,'Created'),
	(2,'Running'),
	(3,'Canceled'),
	(4,'Failed'),
	(5,'Pending'),
	(6,'Ended Unexpectedly'),
	(7,'Succeeded'),
	(8,'Stopping'),
	(9,'Completed')

MERGE ref.ETLExecutionStatus AS Target
USING Sync_ETLExecutionStatus AS Source ON (Target.[ETLExecutionStatusId] = Source.[ETLExecutionStatusId])
WHEN MATCHED THEN
  UPDATE SET Target.[ETLExecutionStatus] = Source.[ETLExecutionStatus]
WHEN NOT MATCHED BY TARGET THEN 
    INSERT ([ETLExecutionStatusId], [ETLExecutionStatus])
    VALUES ([ETLExecutionStatusId], [ETLExecutionStatus])

WHEN NOT MATCHED BY SOURCE THEN DELETE;

DROP TABLE Sync_ETLExecutionStatus;

-----------------------------------------------------------

IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
                  WHERE TABLE_NAME = N'Sync_ETLBatchStatus')
      DROP TABLE Sync_ETLBatchStatus
      
CREATE TABLE Sync_ETLBatchStatus (
      [ETLBatchStatusId] INT NOT NULL 
     ,[ETLBatchStatus]  VARCHAR(50) NULL)

INSERT Sync_ETLBatchStatus (
      [ETLBatchStatusId]
	 ,[ETLBatchStatus] )
VALUES 
	(1,'Created'),
	(4,'Halted'),
	(5,'Completed'),
	(6,'Running'),
	(8,'Timed Out'),
	(9,'Exception'),
	(10,'Manually Ended/Canceled')

MERGE ref.ETLBatchStatus AS Target
USING Sync_ETLBatchStatus AS Source ON (Target.[ETLBatchStatusId] = Source.[ETLBatchStatusId])
WHEN MATCHED THEN
UPDATE SET Target.[ETLBatchStatus] = Source.[ETLBatchStatus]
WHEN NOT MATCHED BY TARGET THEN 
    INSERT ([ETLBatchStatusId], [ETLBatchStatus])
    VALUES ([ETLBatchStatusId], [ETLBatchStatus])

WHEN NOT MATCHED BY SOURCE THEN DELETE;

DROP TABLE Sync_ETLBatchStatus;

-----------------------------------------------------------

IF EXISTS(SELECT
            1
          FROM
            INFORMATION_SCHEMA.TABLES
          WHERE
           TABLE_NAME = N'Sync_SupportSeverityLevel')
  DROP TABLE Sync_SupportSeverityLevel

CREATE TABLE Sync_SupportSeverityLevel
  (
     [SupportSeverityLevelId]  INT NOT NULL
     ,[SupportSeverityLevelCd] VARCHAR(20) NOT NULL
     ,[SupportSeverityLevel]   VARCHAR(255) NULL
  )

INSERT Sync_SupportSeverityLevel
       ([SupportSeverityLevelId]
        ,[SupportSeverityLevelCd]
        ,[SupportSeverityLevel])
VALUES (1
        ,'1'
        ,'High'),
       (2
        ,'2'
        ,'Medium'),
       (3
        ,'3'
        ,'Low')

MERGE ref.SupportSeverityLevel AS Target
USING Sync_SupportSeverityLevel AS Source
ON ( Target.[SupportSeverityLevelId] = Source.[SupportSeverityLevelId] )
WHEN MATCHED THEN
  UPDATE SET Target.[SupportSeverityLevel] = Source.[SupportSeverityLevel]
             ,Target.[SupportSeverityLevelCd] = source.[SupportSeverityLevelCd]
WHEN NOT MATCHED BY TARGET THEN
  INSERT ([SupportSeverityLevelId]
          ,[SupportSeverityLevelCd]
          ,[SupportSeverityLevel])
  VALUES ([SupportSeverityLevelId]
          ,[SupportSeverityLevelCd]
          ,[SupportSeverityLevel])
WHEN NOT MATCHED BY SOURCE THEN
  DELETE;

DROP TABLE Sync_SupportSeverityLevel; 


-----------------------------------------------------------

IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
                  WHERE TABLE_NAME = N'Sync_ETLBatchEventType')
      DROP TABLE Sync_ETLBatchEventType
      
CREATE TABLE Sync_ETLBatchEventType (
      [ETLBatchEventTypeId] INT NOT NULL 
     ,[ETLBatchEventType]  VARCHAR(50) NULL)

INSERT Sync_ETLBatchEventType (
      [ETLBatchEventTypeId]
	 ,[ETLBatchEventType] )
VALUES 
	(1,'Created'),
	(2,'Identifying Packages to Execute'),
	(3,'Executing Package'),
	(4,'Error'),
	(5,'Completed'),
	(7,'Error Notifications Sent'),
	(11,'Waiting for Sufficient Time to Pass'),
	(13,'Restarting Package After Unexpected Termination'),
	(14,'Timeout'),
	(15,'Executing SQL Command'),
	(16,'SQL Command(s) Executed'),
	(18,'SQL Command-based Trigger Executed'),
	(19,'SQL Command Execution Error')

MERGE ref.[ETLBatchExecutionEventType] AS Target
USING Sync_ETLBatchEventType AS Source ON (Target.[ETLBatchExecutionEventTypeId] = Source.[ETLBatchEventTypeId])
WHEN MATCHED THEN
UPDATE SET Target.[ETLBatchExecutionEventType] = Source.[ETLBatchEventType]
WHEN NOT MATCHED BY TARGET THEN 
    INSERT ([ETLBatchExecutionEventTypeId], [ETLBatchExecutionEventType])
    VALUES ([ETLBatchEventTypeId], [ETLBatchEventType])

WHEN NOT MATCHED BY SOURCE THEN DELETE;

DROP TABLE Sync_ETLBatchEventType;

-------------------------------------------------------------------------------------

SET IDENTITY_INSERT ctl.ETLPackage ON;
MERGE ctl.ETLPackage AS Target
USING (SELECT
         0                                AS ETLPackageId
         ,'N/A'                           AS SSISDBFolderName
         ,'N/A'                           AS SSISDBProjectName
         ,'Dummy for Unhandled Exceptions'AS SSISDBPackageName
         ,1                               AS EntryPointPackageInd
         ,NULL                            AS EntryPointETLPackageId
         ,1                               AS EnabledInd
         ,NULL                            AS ReadyForExecutionInd
         ,0                               AS BypassEntryPointInd
         ,0                               AS IgnoreDependenciesInd
         ,0                               AS InCriticalPathPostTransformProcessesInd
         ,0                               AS InCriticalPathPostLoadProcessesInd
         ,0                               AS ExecutePostTransformInd
         ,0                               AS ExecuteSundayInd
         ,0                               AS ExecuteMondayInd
         ,0                               AS ExecuteTuesdayInd
         ,0                               AS ExecuteWednesdayInd
         ,0                               AS ExecuteThursdayInd
         ,0                               AS ExecuteFridayInd
         ,0                               AS ExecuteSaturdayInd
         ,0                               AS Use32BitDtExecInd
         ,2                               AS SupportSeverityLevelId
         ,''                              AS Comments) AS Source
ON ( Target.ETLPackageId = Source.ETLPackageId )
WHEN MATCHED THEN
  UPDATE SET Target.SSISDBFolderName = Source.SSISDBFolderName
             ,Target.SSISDBProjectName = Source.SSISDBProjectName
             ,Target.SSISDBPackageName = Source.SSISDBPackageName
             ,Target.EntryPointETLPackageId = Source.EntryPointETLPackageId
             ,Target.EnabledInd = Source.EnabledInd
             ,Target.ReadyForExecutionInd = Source.ReadyForExecutionInd
             ,Target.BypassEntryPointInd = Source.BypassEntryPointInd
             ,Target.IgnoreDependenciesInd = Source.IgnoreDependenciesInd
             ,Target.ExecuteSundayInd = Source.ExecuteSundayInd
             ,Target.ExecuteMondayInd = Source.ExecuteMondayInd
             ,Target.ExecuteTuesdayInd = Source.ExecuteTuesdayInd
             ,Target.ExecuteWednesdayInd = Source.ExecuteWednesdayInd
             ,Target.ExecuteThursdayInd = Source.ExecuteThursdayInd
             ,Target.ExecuteFridayInd = Source.ExecuteFridayInd
             ,Target.ExecuteSaturdayInd = Source.ExecuteSaturdayInd
             ,Target.Use32BitDtExecInd = Source.Use32BitDtExecInd
             ,Target.SupportSeverityLevelId = Source.SupportSeverityLevelId
WHEN NOT MATCHED BY TARGET THEN
  INSERT (ETLPackageId
          ,SSISDBFolderName
          ,SSISDBProjectName
          ,SSISDBPackageName
          ,EntryPointETLPackageId
          ,EnabledInd
          ,ReadyForExecutionInd
          ,BypassEntryPointInd
          ,IgnoreDependenciesInd
          ,ExecuteSundayInd
          ,ExecuteMondayInd
          ,ExecuteTuesdayInd
          ,ExecuteWednesdayInd
          ,ExecuteThursdayInd
          ,ExecuteFridayInd
          ,ExecuteSaturdayInd
          ,Use32BitDtExecInd
          ,SupportSeverityLevelId
          ,Comments)
  VALUES (ETLPackageId
          ,SSISDBFolderName
          ,SSISDBProjectName
          ,SSISDBPackageName
          ,EntryPointETLPackageId
          ,EnabledInd
          ,ReadyForExecutionInd
          ,BypassEntryPointInd
          ,IgnoreDependenciesInd
          ,ExecuteSundayInd
          ,ExecuteMondayInd
          ,ExecuteTuesdayInd
          ,ExecuteWednesdayInd
          ,ExecuteThursdayInd
          ,ExecuteFridayInd
          ,ExecuteSaturdayInd
          ,Use32BitDtExecInd
          ,SupportSeverityLevelId
          ,Comments); 
SET IDENTITY_INSERT ctl.ETLPackage OFF;

-------------------------------------------------------------------------------------

IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
                  WHERE TABLE_NAME = N'Sync_SSISDBLoggingLevel')
      DROP TABLE Sync_SSISDBLoggingLevel
      
CREATE TABLE Sync_SSISDBLoggingLevel (
    [SSISDBLoggingLevelId] INT NOT NULL 
     ,[SSISDBLoggingLevel]  VARCHAR(50) NULL)

INSERT Sync_SSISDBLoggingLevel (
     [SSISDBLoggingLevelId]
	 ,[SSISDBLoggingLevel] )
VALUES 
	(0,	'None'),
	(1, 'Basic'),
	(2, 'Performance'),
	(3, 'Verbose'),
	(4, 'Runtime lineage'),
	(100, 'Custom logging level')

MERGE ref.SSISDBLoggingLevel AS Target
USING Sync_SSISDBLoggingLevel AS Source ON (Target.[SSISDBLoggingLevelId] = Source.[SSISDBLoggingLevelId])
WHEN MATCHED THEN
UPDATE SET Target.[SSISDBLoggingLevel] = Source.[SSISDBLoggingLevel]
WHEN NOT MATCHED BY TARGET THEN 
    INSERT ([SSISDBLoggingLevelId], [SSISDBLoggingLevel])
    VALUES ([SSISDBLoggingLevelId], [SSISDBLoggingLevel])

WHEN NOT MATCHED BY SOURCE THEN DELETE;

DROP TABLE Sync_SSISDBLoggingLevel;
--------------------------------------------------

PRINT 'Completed populating reference tables'