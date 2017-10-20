CREATE VIEW [rpt].[ETLBatchGroupsStatuses]
AS
  SELECT
    ebe.[ETLBatchExecutionId]
   ,ebe.[CallingJobName]
   ,eb.[ETLBatchName]
   ,ebp.[ETLPackageGroupId]
   ,ebp.[ETLPackageGroup]
   ,MIN(CAST(ex.start_time AS DATETIME2))                                                                                                      AS GroupStartDateTime
   ,IIF([dbo].[func_IsPackageGroupComplete] (ebe.[ETLBatchExecutionId], ebp.ETLPackageGroupId) = 1, MAX(CAST(ex.end_time AS DATETIME2)), NULL) AS GroupEndDateTime
  FROM
    ctl.ETLBatchExecution ebe
    JOIN [ctl].[ETLBatch_ETLPackageGroup] b
      ON ebe.ETLBatchId = b.ETLBatchId
    JOIN ctl.ETLBatch eb
      ON ebe.ETLBatchId = eb.ETLBatchId
    JOIN [ctl].[ETLPackageGroup] ebp
      ON b.[ETLPackageGroupId] = ebp.[ETLPackageGroupId]
    JOIN ctl.ETLPackageGroup_ETLPackage grppkg
      ON ebp.[ETLPackageGroupId] = grppkg.[ETLPackageGroupId]
    JOIN ctl.ETLPackage ep
      ON grppkg.ETLPackageId = ep.ETLPackageId
         AND EntryPointETLPackageId IS NULL
    LEFT JOIN [ctl].[ETLBatchSSISDBExecutions] ebsdbe
           ON ebsdbe.ETLBatchExecutionId = ebe.ETLBatchExecutionId
              AND ebsdbe.ETLPackageId = ep.ETLPackageId
    LEFT JOIN [$(SSISDB)].[catalog].executions ex
           ON ebsdbe.SSISDBExecutionId = ex.execution_id
  GROUP  BY
    ebe.[ETLBatchExecutionId]
    ,ebe.[CallingJobName]
    ,eb.[ETLBatchName]
    ,ebp.[ETLPackageGroup] 
	,ebp.[ETLPackageGroupId]
