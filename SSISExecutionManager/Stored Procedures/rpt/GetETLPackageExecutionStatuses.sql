CREATE PROCEDURE [rpt].[GetETLPackageExecutionStatuses] @ETLBatchExecutionId INT
AS
    SELECT
      p.[ETLBatchExecutionId]
      ,p.[ETLBatchName]
      ,p.[ETLPackageGroupId]
      ,p.[ETLPackageId]
      ,p.[SSISDBExecutionId]
      ,p.[SSISDBFolderName]
      ,p.[SSISDBProjectName]
      ,p.[SSISDBPackageName]
      ,p.[ExecutionStartDateTime]
      ,p.[ExecutionEndDateTime]
      ,p.[ExecutionDurationInMinutes]
      ,p.[PackageExecutionStatus]
      ,p.[SSISParentExecutionStatus]
      ,p.[EntryPointPackageInd]
      ,p.[ReadyForExecutionInd]
      ,b.[ETLBatchStatus]
    FROM
      [rpt].[ETLPackageExecutionStatuses] p
      JOIN [rpt].[ETLBatchExecutions] b
        ON p.[ETLBatchExecutionId] = b.[ETLBatchExecutionId]
    WHERE
      p.[ETLBatchExecutionId] = @ETLBatchExecutionId
    ORDER  BY
      ISNULL([ExecutionStartDateTime], '9999-12-31')
      ,[SSISDBProjectName]

    RETURN 0 
