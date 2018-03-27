CREATE VIEW [rpt].[ETLPackageGroupExecutions]
AS
--ToDo: replace  [log].[ETLPackageExecutionHistory] with a "live" package execution status table, once created
  SELECT TOP 1000000
    ebsdbe.ETLBatchExecutionId
   ,ebp.[ETLPackageGroupId]
   ,ebp.[ETLPackageGroup]
   ,COUNT(DISTINCT epe.[ETLPackageId])                             AS PackagesExecutedNo
   ,MIN(epe.StartDateTime)                                         AS GroupStartDateTime
   ,MAX(epe.EndDateTime)                                           AS GroupEndDateTime
   ,DATEDIFF(MINUTE, MIN(epe.StartDateTime), MAX(epe.EndDateTime)) AS GroupExecutionDurationInMinutes
  FROM
    [log].[ETLPackageExecutionHistory] epe
    JOIN [ctl].[ETLBatchSSISDBExecutions] ebsdbe
      ON epe.SSISDBExecutionId = ebsdbe.SSISDBExecutionId
    JOIN [cfg].[ETLBatch_ETLPackageGroup] b
      ON epe.ETLBatchId = b.ETLBatchId
    JOIN [cfg].[ETLPackageGroup] ebp
      ON b.[ETLPackageGroupId] = ebp.[ETLPackageGroupId]
    JOIN [cfg].[ETLPackageGroup_ETLPackage] b2
      ON ebp.[ETLPackageGroupId] = b2.[ETLPackageGroupId]
         AND epe.ETLPackageId = b2.ETLPackageId
  GROUP  BY
    ebsdbe.ETLBatchExecutionId
    ,ebp.[ETLPackageGroupId]
    ,ebp.[ETLPackageGroup]
  ORDER  BY
    ebsdbe.ETLBatchExecutionId DESC
