CREATE PROCEDURE [rpt].[GetETLPackagesInFailedState] @ETLBatchExecutionId INT
AS
    SELECT
      [ETLBatchExecutionId]
      ,[SSISDBFolderName]
      ,[SSISDBProjectName]
      ,[SSISDBPackageName]
      ,[ETLPackageGroupId]
      ,[LastPackageFailureStartTime]
      ,[LastPackageSuccessStartTime]
      ,[FirstErrorMessage]
      ,[ErrorDateTime]
    FROM
      [rpt].[ETLPackagesInFailedState] fs
    WHERE
      ETLBatchExecutionId = @ETLBatchExecutionId

    RETURN 0 
