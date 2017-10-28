CREATE FUNCTION [dbo].[func_GetRunningETLBatchExecution] (@BatchStartedWithinMinutes SMALLINT,
                                                          @CallingJobName            VARCHAR(128))
RETURNS TABLE
AS
    RETURN
      (SELECT
         ebe.ETLBatchExecutionId
        ,ebe.ETLBatchStatusId
        ,ebe.DayOfWeekName
        ,ebe.StartDateTime
        ,ebe.ETLBatchId
        ,eb.SendBatchCompleteEmailInd
       FROM
         ctl.[ETLBatchExecution] ebe (NOLOCK)
         JOIN [cfg].[ETLBatch] eb (NOLOCK)
           ON ebe.ETLBatchId = eb.ETLBatchId
         OUTER APPLY [dbo].[func_GetETLBatchExecutionSSISDBExecutionSummary] (ebe.ETLBatchExecutionId) xsum
       WHERE
        EndDateTime IS NULL
        AND CallingJobName = @CallingJobName
        AND ETLBatchStatusId <> 12 --To handle batches that have been created but are waiting on SQL Command Conditions - might have to revisit 
        AND (DATEDIFF(MINUTE, StartDateTime, GETDATE()) <= @BatchStartedWithinMinutes
              OR xsum.RunningCount > 0)) --If the batch is within the time window OR it still has packages in a running state
