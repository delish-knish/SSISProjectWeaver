CREATE FUNCTION [dbo].[func_IsPackageGroupComplete] (@ETLBatchExecutionId INT,
                                                     @ETLPackageGroupId   INT)
RETURNS INT
AS
  BEGIN
      RETURN
        (SELECT
           CAST(IIF(COUNT(DISTINCT p.ETLPackageId) - COUNT(DISTINCT folder_name + project_name + package_name) = 0, 1, 0) AS BIT) AS IsPackageGroupCompleteInd
         --,COUNT(DISTINCT p.ETLPackageId) AS TotalEntryPointPackages
         --,COUNT(DISTINCT folder_name + project_name + package_name) AS TotalCompletedEntryPointPackages
         FROM
           ctl.ETLBatch_ETLPackageGroup g
           JOIN ctl.ETLBatchExecution bx
             ON g.ETLBatchId = bx.ETLBatchId
           JOIN ctl.ETLPackageGroup_ETLPackage b
             ON g.ETLPackageGroupId = b.ETLPackageGroupId
           JOIN ctl.ETLPackage p
             ON b.ETLPackageId = p.ETLPackageId
           LEFT JOIN ctl.ETLBatchSSISDBExecutions sx
                  ON p.ETLPackageId = sx.ETLPackageId
                     AND bx.ETLBatchExecutionId = sx.ETLBatchExecutionId
           LEFT JOIN [$(SSISDB)].[catalog].executions x
                  ON p.SSISDBProjectName = x.project_name
                     AND p.SSISDBFolderName = x.folder_name
                     AND p.SSISDBPackageName = x.package_name
                     AND sx.SSISDBExecutionId = x.execution_id
                     AND x.[status] IN (7, 9)
         WHERE
          g.EnabledInd = 1
          AND b.EnabledInd = 1
          AND p.EnabledInd = 1
          AND p.EntryPointPackageInd = 1
          AND (b.IgnoreForBatchCompleteInd = 0 or x.[status] IN (7, 9))
          AND bx.ETLBatchExecutionId = @ETLBatchExecutionId
          AND b.ETLPackageGroupId = @ETLPackageGroupId
         GROUP  BY
          bx.ETLBatchExecutionId)

  END 
