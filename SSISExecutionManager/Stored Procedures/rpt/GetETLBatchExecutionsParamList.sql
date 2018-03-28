CREATE PROCEDURE [rpt].[GetETLBatchExecutionsParamList] @MaxBatchesToReturn BIGINT = 20,
                                                        @ETLBatchId         INT = NULL
AS
    SELECT TOP (@MaxBatchesToReturn)
      ETLBatchExecutionId
      ,CAST(ETLBatchExecutionId AS VARCHAR) + ' '
       + ETLBatchName + ' - ' + DayOfWeekName + ' - '
       + FORMAT( StartDateTime, 'MM/dd/yyyy h:mmtt', 'en-US' ) AS ETLBatchName
    FROM
      rpt.ETLBatchExecutions
    WHERE
      ETLBatchId = @ETLBatchId
	  OR @ETLBatchId IS NULL
    ORDER  BY
      ETLBatchExecutionId DESC

    RETURN 0 
