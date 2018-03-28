CREATE PROCEDURE [rpt].[GetETLBatchGroupStatuses] @ETLBatchExecutionId INT
AS
    SELECT
      [ETLBatchExecutionId]
      ,[CallingJobName]
	  ,[ETLBatchId]
      ,[ETLBatchName]
      ,[ETLPackageGroupId]
      ,[ETLPackageGroup]
      ,[GroupStartDateTime]
      ,[GroupEndDateTime]
    FROM
      [rpt].[ETLBatchGroupsStatuses]
    WHERE
      [ETLBatchExecutionId] = @ETLBatchExecutionId

    RETURN 0 
