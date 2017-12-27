CREATE VIEW [rpt].[ETLBatchSSISDBExecutions]
AS
  SELECT
    [ETLBatchExecutionId]
    ,[SSISDBExecutionId]
    ,[ETLPackageId]
    ,[ETLPackageGroupId]
  FROM
    [ctl].[ETLBatchSSISDBExecutions] 
