CREATE PROCEDURE [sup].[ExecutePackageForETLBatch] @ETLBatchExecutionId INT,
                                                   @SSISDBFolderName    NVARCHAR(128),
                                                   @SSISDBProjectName   NVARCHAR(128),
                                                   @SSISDBPackageName   NVARCHAR (260),
                                                   @ETLPackageGroupId   INT,
                                                   @SSISExecutionId     BIGINT = NULL OUT
AS
    /*The purpose of this stored procedure is to immediately execute a package and tie it to an ETL Batch Execution but outside of the polling process */

    DECLARE @SSISEnvironmentName VARCHAR(128)
            ,@EventDescription   VARCHAR(MAX);

    SELECT
      @SSISEnvironmentName = SSISEnvironmentName
    FROM
      ctl.[ETLBatchExecution]
    WHERE
      [ETLBatchExecutionId] = @ETLBatchExecutionId

    DECLARE @ETLPackageId INT = (SELECT
         ETLPackageId
       FROM
         [cfg].ETLPackage
       WHERE
        @SSISDBFolderName = SSISDBFolderName
        AND @SSISDBProjectName = SSISDBProjectName
        AND @SSISDBPackageName = SSISDBPackageName)

    IF @ETLPackageId IS NULL
      THROW 50000, 'The package does not exist. No packages were executed.', 1;

    --Execute the package
    EXEC [ctl].ExecuteETLPackage
      @ETLBatchExecutionId,
      @ETLPackageId,
      @ETLPackageGroupId,
      @SSISEnvironmentName,
      @SSISExecutionId OUT

    SET @EventDescription = 'User-initiated execution of package Id '
                            + CAST(@ETLPackageId AS VARCHAR(10));

    EXEC [log].[InsertETLBatchExecutionEvent]
      20,
      @ETLBatchExecutionId,
      @ETLPackageId,
      @EventDescription;

    RETURN 0 
