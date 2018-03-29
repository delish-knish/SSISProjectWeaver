CREATE PROCEDURE [rpt].[GetETLBatchParamList]
AS
    SELECT
      NULL AS ETLBatchId
      ,'(All)' AS ETLBatchName
      ,-99999999 AS ExecutionCount
    UNION ALL
    SELECT
      eb.ETLBatchId
      ,eb.ETLBatchName
      ,-COUNT(*) AS ExecutionCount
    FROM
      cfg.ETLBatch eb
      JOIN ctl.ETLBatchExecution ebe
        ON eb.ETLBatchId = ebe.ETLBatchId
    GROUP  BY
      eb.ETLBatchId
      ,eb.ETLBatchName
    ORDER  BY
      ExecutionCount

    RETURN 0 
