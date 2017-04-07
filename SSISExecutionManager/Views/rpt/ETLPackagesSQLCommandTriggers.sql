CREATE VIEW [rpt].[ETLPackagesSQLCommandConditions]
AS
  SELECT
    b.[ETLPackage_SQLCommandConditionId]
	,b.ETLPackageId
    ,ep.SSISDBPackageName
    ,b.SQLCommandId
    ,sc.SQLCommandName
    ,sc.SQLCommand
    ,sc.SQLCommandDescription
    ,sc.RequiresETLBatchIdParameterInd
    ,b.EnabledInd
  FROM
    [ctl].[ETLPackage_SQLCommandCondition] b
    JOIN ctl.SQLCommand sc
      ON b.SQLCommandId = sc.SQLCommandId
    JOIN ctl.ETLPackage ep
      ON b.[ETLPackageId] = ep.[ETLPackageId] 
