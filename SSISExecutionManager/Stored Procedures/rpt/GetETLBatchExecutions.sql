CREATE PROCEDURE [rpt].[GetETLBatchExecutions] @ETLBatchId INT = NULL
AS
    SELECT
      ebe.ETLBatchExecutionId
      ,ebe.CallingJobName
	  ,ebe.ETLBatchId
      ,ebe.ETLBatchName
      ,ebe.DayOfWeekName
      ,ebe.StartDateTime
      ,ebe.EndDateTime
      ,ebe.ExecutionDurationInMinutes
      ,ebe.ETLBatchStatus
      ,ebe.TotalEntryPointPackageCount
      ,ebe.TotalRemainingEntryPointPackageCount
      ,ebe.TotalETLPackageCount
      ,ebe.TotalRemainingETLPackageCount
      ,ebe.BatchStatusLastUpdatedDate
    FROM
      rpt.ETLBatchExecutions ebe
    WHERE
      ebe.ETLBatchId = @ETLBatchId
       OR @ETLBatchId IS NULL
    ORDER  BY
      ebe.StartDateTime DESC

    RETURN 0 
