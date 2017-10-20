CREATE PROCEDURE [sup].[ManuallyExecutePackageForETLBatch] @ETLBatchExecutionId INT,
                                                           @SSISDBFolderName    NVARCHAR(128),
                                                           @SSISDBProjectName   NVARCHAR(128),
                                                           @SSISDBPackageName   NVARCHAR (260),
														   @ETLPackageGroupId	INT,
                                                           @SSISExecutionId     BIGINT = NULL OUT
AS
    /*The purpose of this stored procedure is to immediately execute a package and tie it to an ETL Batch Execution but outside of the polling process */

    DECLARE
    @SSISEnvironmentName VARCHAR(128)

    SELECT
      @SSISEnvironmentName = SSISEnvironmentName
    FROM
      ctl.[ETLBatchExecution]
    WHERE
      [ETLBatchExecutionId] = @ETLBatchExecutionId

    DECLARE @ETLPackageId INT = (SELECT
         ETLPackageId
       FROM
         ctl.ETLPackage
       WHERE
        @SSISDBFolderName = SSISDBFolderName
        AND @SSISDBProjectName = SSISDBProjectName
        AND @SSISDBPackageName = SSISDBPackageName)

    --Execute the package
    EXEC [ctl].ExecuteETLPackage
      @ETLBatchExecutionId
     ,@ETLPackageId
	 ,@ETLPackageGroupId
     ,@SSISEnvironmentName
     ,@SSISExecutionId OUT

    RETURN 0 
