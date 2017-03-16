CREATE PROCEDURE [cfg].[DeleteETLPackage] @ETLPackageId      INT = NULL,
                                          @SSISDBPackageName NVARCHAR (260) = NULL,
                                          @SSISDBProjectName NVARCHAR(128) = NULL,
                                          @SSISDBFolderName  NVARCHAR(128) = NULL
AS
    SELECT
      @ETLPackageId = ETLPackageId
    FROM
      ctl.ETLPackage
    WHERE
      ETLPackageId = @ETLPackageId
       OR ( SSISDBPackageName = @SSISDBPackageName
            AND SSISDBProjectName = @SSISDBProjectName
            AND SSISDBFolderName = @SSISDBFolderName );

    IF @ETLPackageId IS NULL
      THROW 50012, 'The package does not exist. Please review package id, package, project, and folder names for accuracy.', 1;
    ELSE
      BEGIN
          DELETE FROM [ctl].[ETLBatchSSISDBExecutions]
          WHERE  ETLPackageId = @ETLPackageId;

          DELETE FROM [log].[ETLBatchExecutionEvent]
          WHERE  ETLPackageId = @ETLPackageId;

          DELETE FROM [log].ETLPackageExecution
          WHERE  ETLPackageId = @ETLPackageId;

		  DELETE FROM [log].ETLPackageExecutionError
          WHERE  ETLPackageId = @ETLPackageId;

          DELETE FROM ctl.[ETLPackageGroup_ETLPackage]
          WHERE  ETLPackageId = @ETLPackageId;

          DELETE FROM ctl.[ETLPackage_SQLCommandTrigger]
          WHERE  ETLPackageId = @ETLPackageId;
		  
          DELETE FROM ctl.ETLPackage
          WHERE  ETLPackageId = @ETLPackageId;
      END

    RETURN 0 
