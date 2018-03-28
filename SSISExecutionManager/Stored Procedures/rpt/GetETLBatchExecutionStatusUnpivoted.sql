CREATE PROCEDURE [rpt].[GetETLBatchExecutionStatusUnpivoted] @ETLBatchExecutionId INT
AS
    SELECT
      [ETLBatchExecutionId]
      ,Label
      ,Val
    FROM
      (SELECT
         [ETLBatchExecutionId]
         ,'Batch Execution Id'                   AS Label
         ,CAST([ETLBatchExecutionId] AS VARCHAR) AS Val
       FROM
         [rpt].[ETLBatchExecutions]
       UNION ALL
       SELECT
         [ETLBatchExecutionId]
         ,'Name'         AS Label
         ,[ETLBatchName] AS Val
       FROM
         [rpt].[ETLBatchExecutions]
       UNION ALL
       SELECT
         [ETLBatchExecutionId]
         ,'Status' AS Label
         ,[ETLBatchStatus]
       FROM
         [rpt].[ETLBatchExecutions]
       UNION ALL
       SELECT
         [ETLBatchExecutionId]
         ,'Total Pkgs' AS Label
         ,CAST([TotalETLPackageCount] AS VARCHAR)
       FROM
         [rpt].[ETLBatchExecutions]
       UNION ALL
       SELECT
         [ETLBatchExecutionId]
         ,'Remaining Pkgs' AS Label
         ,CAST([TotalRemainingETLPackageCount] AS VARCHAR)
       FROM
         [rpt].[ETLBatchExecutions]
       UNION ALL
       SELECT
         [ETLBatchExecutionId]
         ,'Status Last Updated' AS Label
         ,FORMAT([BatchStatusLastUpdatedDate], 'yyyy/MM/dd HH:mm tt', 'en-US')
       FROM
         [rpt].[ETLBatchExecutions]) t
    WHERE
      [ETLBatchExecutionId] = @ETLBatchExecutionId

    RETURN 0 
