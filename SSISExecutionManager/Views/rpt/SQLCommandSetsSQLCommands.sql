CREATE VIEW [rpt].[SQLCommandSetsSQLCommands]
AS
  SELECT
    SQLCommand_SQLCommandSetId
    ,b.SQLCommandSetId
    ,scs.SQLCommandSetName
    ,scdt.SQLCommandDependencyType
    ,b.SQLCommandId
    ,sc.SQLCommandName
    ,b.EnabledInd
    ,b.ExecutionOrder
    ,b.FailBatchOnFailureInd
    ,b.Comments
  FROM
    [ctl].[SQLCommand_SQLCommandSet] b
    JOIN ctl.SQLCommandSet scs
      ON b.SQLCommandSetId = scs.SQLCommandSetId
    JOIN ctl.SQLCommand sc
      ON b.SQLCommandId = sc.SQLCommandId
    JOIN ref.SQLCommandDependencyType scdt
      ON b.SQLCommandDependencyTypeId = scdt.SQLCommandDependencyTypeId 
