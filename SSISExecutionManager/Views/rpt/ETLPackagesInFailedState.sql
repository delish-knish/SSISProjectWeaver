CREATE VIEW [rpt].[ETLPackagesInFailedState]
AS
  WITH ex
       AS (SELECT
             exe.ETLBatchExecutionId
             ,exe.SSISDBExecutionId
             ,s.ETLExecutionStatusId
             ,exe.ETLPackageGroupId
             ,s.ETLPackageId
             ,s.StartDateTime
           FROM
             [ctl].[ETLBatchSSISDBExecutions] exe
             CROSS APPLY dbo.func_GetETLPackageExecutionStatusesFromSSISDB(exe.SSISDBExecutionId) s)
  SELECT
    fex.ETLBatchExecutionId
    ,fex.ETLPackageId
    ,fex.ETLPackageGroupId
    ,LastPackageFailureStartTime
    ,LastPackageSuccessStartTime
    ,fex.FirstErrorMessage
    ,fex.ErrorDateTime
  FROM
    (SELECT
       ex.ETLBatchExecutionId
       ,ex.ETLPackageGroupId
       ,ex.ETLPackageId
       ,MAX(ex.StartDateTime)  AS LastPackageFailureStartTime
       ,MAX(err.ErrorMessage)  AS FirstErrorMessage
       ,MAX(err.ErrorDateTime) AS ErrorDateTime
     FROM
       ex
       OUTER APPLY (SELECT TOP 1
                      err.ErrorMessage
                      ,err.ErrorDateTime
                    FROM
                      [log].[ETLPackageExecutionError] err
                    WHERE
                     ex.[SSISDBExecutionId] = err.[SSISDBExecutionId]
                    ORDER  BY
                     ErrorDateTime ASC) err
     WHERE
      ex.ETLExecutionStatusId IN ( 3, 4, 6 )
     GROUP  BY
      ex.ETLBatchExecutionId
      ,ex.ETLPackageGroupId
      ,ex.ETLPackageId
     HAVING
      COUNT(*) > 0) fex
    LEFT JOIN (SELECT
                 ETLBatchExecutionId
                 ,ex.ETLPackageId
                 ,MAX(ex.StartDateTime) AS LastPackageSuccessStartTime
               FROM
                 ex
               WHERE
                ex.ETLExecutionStatusId = 7
               GROUP  BY
                ex.ETLBatchExecutionId
                ,ex.ETLPackageId
               HAVING
                COUNT(*) > 0) sex
           ON fex.ETLPackageId = sex.ETLPackageId
              AND fex.ETLBatchExecutionId = sex.ETLBatchExecutionId
  WHERE
    ISNULL(sex.LastPackageSuccessStartTime, '1900-01-01') < fex.LastPackageFailureStartTime 
