CREATE PROCEDURE [cfg].[DeleteETLPackage] @ETLPackageId      INT = NULL,
                                          @SSISDBPackageName NVARCHAR (260) = NULL,
                                          @SSISDBProjectName NVARCHAR(128) = NULL,
                                          @SSISDBFolderName  NVARCHAR(128) = NULL
AS
    SELECT
      @ETLPackageId = ETLPackageId
    FROM
      [cfg].ETLPackage
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

          DELETE FROM [log].[ETLPackageExecutionHistory]
          WHERE  ETLPackageId = @ETLPackageId;

		  DELETE FROM [log].ETLPackageExecutionError
          WHERE  ETLPackageId = @ETLPackageId;

          DELETE FROM [cfg].[ETLPackageGroup_ETLPackage]
          WHERE  ETLPackageId = @ETLPackageId;

          DELETE t 
		  FROM [cfg].[ETLPackageGroup_ETLPackage_SQLCommandCondition] t
		  JOIN [cfg].ETLPackageGroup_ETLPackage epgep ON t.ETLPackageGroup_ETLPackageId = epgep.ETLPackageGroup_ETLPackageId
          WHERE  epgep.ETLPackageId = @ETLPackageId;

		  DELETE FROM [cfg].[ETLPackage_ETLPackageDependency]
          WHERE  ETLPackageId = @ETLPackageId;
		  
          DELETE FROM [cfg].ETLPackage
          WHERE  ETLPackageId = @ETLPackageId;
      END

    RETURN 0 
