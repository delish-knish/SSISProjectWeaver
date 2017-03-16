CREATE PROCEDURE [sup].[ManuallyExecutePackageForETLBatch] @ETLBatchId          INT,
                                                           @SSISDBFolderName    NVARCHAR(128),
                                                           @SSISDBProjectName   NVARCHAR(128),
                                                           @SSISDBPackageName   NVARCHAR (260),
                                                           @SSISExecutionId     BIGINT = NULL OUT
AS
    /*The purpose of this stored procedure is to be able to execute a package as part of a batch but outside of the SQL Agent Job */

    DECLARE 
		--@Periodicity CHAR(2),
		@SSISEnvironmentName VARCHAR(128)

	SELECT 
		--@Periodicity = Periodicity
		@SSISEnvironmentName = SSISEnvironmentName
	FROM 
		ctl.[ETLBatchExecution] 
	WHERE
		[ETLBatchExecutionId] = @ETLBatchId

    DECLARE @ETLPackageId INT = (SELECT
         ETLPackageId
       FROM
         ctl.ETLPackage
       WHERE
        @SSISDBFolderName = SSISDBFolderName
        AND @SSISDBProjectName = SSISDBProjectName
        AND @SSISDBPackageName = SSISDBPackageName)

    --Execute the package
    EXEC [ctl].ExecuteETLPackage @ETLBatchId,@ETLPackageId,@SSISEnvironmentName,@SSISExecutionId OUT

    RETURN 0 
