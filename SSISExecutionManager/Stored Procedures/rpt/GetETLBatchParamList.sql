CREATE PROCEDURE [rpt].[GetETLBatchParamList]
AS
    SELECT
      eb.ETLBatchId
      ,eb.ETLBatchName
      ,COUNT(*) AS ExecutionCount
    FROM
      cfg.ETLBatch eb
      JOIN ctl.ETLBatchExecution ebe
        ON eb.ETLBatchId = ebe.ETLBatchId
    GROUP  BY
      eb.ETLBatchId
      ,eb.ETLBatchName
    ORDER  BY
		ExecutionCount DESC

    RETURN 0 
