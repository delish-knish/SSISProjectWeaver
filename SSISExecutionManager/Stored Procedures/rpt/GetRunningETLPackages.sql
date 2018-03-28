CREATE PROCEDURE [rpt].[GetRunningETLPackages] @ETLBatchExecutionId INT = NULL
AS
    SELECT
      exm.ETLBatchExecutionId
      ,execution_id                  AS SSISDBExecutionId
      ,project_name                  AS SSISDBProjectName
      ,package_name                  AS SSISDBPackageName
      ,CAST(start_time AS DATETIME2) AS StartDateTime
    FROM
      [$(SSISDB)].[catalog].executions ex
      JOIN [rpt].[ETLBatchSSISDBExecutions] exm
        ON ex.execution_id = exm.SSISDBExecutionId
    WHERE
      [status] = 2
      AND ( exm.ETLBatchExecutionId = @ETLBatchExecutionId
             OR @ETLBatchExecutionId IS NULL )

    RETURN 0 
