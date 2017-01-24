CREATE PROCEDURE [cfg].[ClearHistory]
AS
    TRUNCATE TABLE [log].[ETLBatchExecutionEvent];

    TRUNCATE TABLE [log].[ETLPackageExecution];

    TRUNCATE TABLE [log].[ETLPackageExecutionError];

    TRUNCATE TABLE [log].[ETLPackageExecutionLongRunning];

    TRUNCATE TABLE [log].[ETLPackageExecutionRowLevelError];

    DELETE FROM [ctl].[ETLBatchExecution];

    DBCC CHECKIDENT ('ctl.ETLBatchExecution', reseed, 0);

    TRUNCATE TABLE [ctl].[ETLBatchSSISDBExecutions];

    RETURN 0 
