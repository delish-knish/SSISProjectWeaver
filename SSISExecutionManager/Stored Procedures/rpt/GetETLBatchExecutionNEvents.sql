CREATE PROCEDURE [rpt].[GetETLBatchExecutionLastNEvents] @ETLBatchExecutionId INT,
                                                         @LastNEvents         INT = 10
AS
    SELECT TOP (@LastNEvents)
      [EventDateTime]
      ,[Description]
    FROM
      [rpt].[ETLBatchExecutionEvents]
    WHERE
      [ETLBatchExecutionId] = @ETLBatchExecutionId
    ORDER  BY
      [EventDateTime] DESC

    RETURN 0 
