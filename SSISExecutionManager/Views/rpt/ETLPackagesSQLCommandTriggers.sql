CREATE VIEW [rpt].[ETLPackagesSQLCommandTriggers]
AS
  SELECT
    b.[ETLPackage_SQLCommandTriggerId]
	,b.ETLPackageId
    ,ep.SSISDBPackageName
    ,b.SQLCommandId
    ,sc.SQLCommandName
    ,sc.SQLCommand
    ,sc.SQLCommandDescription
    ,sc.RequiresETLBatchIdParameterInd
    ,b.EnabledInd
  FROM
    [ctl].[ETLPackage_SQLCommandTrigger] b
    JOIN ctl.SQLCommand sc
      ON b.SQLCommandId = sc.SQLCommandId
    JOIN ctl.ETLPackage ep
      ON b.[ETLPackageId] = ep.[ETLPackageId] 
