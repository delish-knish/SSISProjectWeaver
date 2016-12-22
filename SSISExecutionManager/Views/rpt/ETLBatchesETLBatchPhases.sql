CREATE VIEW [rpt].[ETLBatchesETLPackageGroups]
AS
  SELECT
    b.[ETLBatch_ETLPackageGroup]
    ,b.[ETLBatchId]
    ,eps.[ETLBatchName]
    ,b.[ETLPackageGroupId]
    ,ep.[ETLPackageGroup]
  FROM
    [ctl].[ETLBatch_ETLPackageGroup] b
    JOIN ctl.[ETLBatch] eps
      ON b.[ETLBatchId] = eps.[ETLBatchId]
    JOIN ctl.[ETLPackageGroup] ep
      ON b.[ETLPackageGroupId] = ep.[ETLPackageGroupId] 
