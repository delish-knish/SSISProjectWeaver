CREATE PROCEDURE [rpt].[GetETLBatchPerformancePastNDays] @ETLBatchId INT,
                                                         @DaysBack   INT
AS
    SELECT
      [ETLBatchExecutionId]
      ,[StartDateTime]
      ,[ExecutionDurationInMinutes]
      ,CAST([ExecutionDurationInMinutes] / 60 AS VARCHAR)
       + ':'
       + CAST([ExecutionDurationInMinutes] % 60 AS VARCHAR) AS ExecutionDurationString
      ,[DayOfWeekName]
      ,ETLBatchStatus
    FROM
      [rpt].[ETLBatchExecutions] be
    WHERE
      ETLBatchId = @ETLBatchId
      AND [StartDateTime] >= DATEADD(DAY, -@DaysBack, GETDATE())
    ORDER  BY
      [StartDateTime]

    RETURN 0 
