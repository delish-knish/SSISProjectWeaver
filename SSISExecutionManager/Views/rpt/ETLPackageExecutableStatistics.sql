CREATE VIEW [rpt].[ETLPackageExecutableStatistics]
AS
  SELECT TOP 10000000
    b.ETLBatchName                                   AS ETLBatchName
   ,ebe.ETLBatchExecutionId                          AS ETLBatchExecutionId
   ,st.[execution_id]                                AS SSISDBExecutionId
   ,pkg.ETLPackageId                                 AS ETLPackageId
   ,pkg.SSISDBProjectName                            AS SSISDBProjectName
   ,ex.package_name                                  AS SSISDBPackageName
   ,ex.executable_name                               AS ExecutableName
   ,st.[start_time]                                  AS ExecutionStartTime
   ,st.[end_time]                                    AS ExecutionEndTime
   ,DATEDIFF(minute, st.[start_time], st.[end_time]) AS ExecutionDurationInMinutes
   ,CASE st.[execution_result]
       WHEN 0 THEN 'Success'
       WHEN 1 THEN 'Failure'
       WHEN 2 THEN 'Completion'
       WHEN 3 THEN 'Canceled'
     END                                             AS ExecutionResult
  FROM
    [$(SSISDB)].[catalog].[executable_statistics] st
    JOIN [$(SSISDB)].catalog.executables ex
      ON st.executable_id = ex.executable_id
         AND st.execution_id = ex.execution_id
    JOIN [cfg].ETLPackage pkg
      ON ex.package_name = pkg.SSISDBPackageName
    JOIN ctl.ETLBatchSSISDBExecutions ebe
      ON ex.execution_id = ebe.SSISDBExecutionId
    JOIN ctl.ETLBatchExecution eb
      ON ebe.ETLBatchExecutionId = eb.ETLBatchExecutionId
    JOIN ctl.ETLBatch b
      ON eb.ETLBatchId = b.ETLBatchId
  ORDER  BY
    st.[start_time] DESC 
