CREATE VIEW [rpt].[ETLBatchesETLPackagesSQLCommandConditions]
AS
  SELECT
    b.[ETLBatch_ETLPackage_SQLCommandConditionId]
   ,b.ETLBatchId
   ,b.ETLPackageId
   ,ep.SSISDBPackageName
   ,b.SQLCommandId
   ,sc.SQLCommandName
   ,sc.SQLCommand
   ,sc.SQLCommandDescription
   ,sc.RequiresETLBatchIdParameterInd
   ,b.EnabledInd
  FROM
    [cfg].[ETLBatch_ETLPackage_SQLCommandCondition] b
    JOIN [cfg].SQLCommand sc
      ON b.SQLCommandId = sc.SQLCommandId
    JOIN [cfg].ETLPackage ep
      ON b.[ETLPackageId] = ep.[ETLPackageId]
    JOIN ctl.ETLBatch eb
      ON b.ETLBatchId = eb.ETLBatchId 
