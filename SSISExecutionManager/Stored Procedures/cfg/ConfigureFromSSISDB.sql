CREATE PROCEDURE [cfg].[ConfigureFromSSISDB] @SSISDBFolderNames   VARCHAR(MAX)  -- Comma delimited list of folders to be imported
                                             ,@SSISDBProjectNames  VARCHAR(MAX) -- Comma delimited list of projects to be imported
                                             ,@SSISDBPackages      VARCHAR(MAX) = NULL -- Comma delimited list of packages to be imported, NULL will include all packages in the project(s). Include '.dtsx' to the end of package names.
                                             ,@ETLBatchName        VARCHAR(MAX) 
                                             ,@ETLPackageGroupName VARCHAR(MAX) 
AS
    /* Create ETLBatch record */
    IF NOT EXISTS (SELECT
                     1
                   FROM
                     cfg.ETLBatch
                   WHERE
                    ETLBatchName = @ETLBatchName)
      BEGIN
          INSERT INTO cfg.ETLBatch
                      (ETLBatchName
                       ,ETLBatchDescription)
          SELECT
            @ETLBatchName
            ,'Loads ' + @ETLBatchName
      END

    /* Create ETLPackageGroup record */
    IF NOT EXISTS (SELECT
                     1
                   FROM
                     cfg.ETLPackageGroup
                   WHERE
                    ETLPackageGroup = @ETLPackageGroupName)
      BEGIN
          INSERT INTO cfg.ETLPackageGroup
                      (ETLPackageGroup)
          SELECT
            @ETLPackageGroupName
      END;

    /* Insert Packages from @SSISDBPackages list*/
    WITH cte_ETLPackage
         AS (SELECT
               fldr.NAME        AS SSISDBFolderName
               ,prjct.NAME      AS SSISDBProjectName
               ,pkg.NAME        AS SSISDBPackageName
               ,pkg.entry_point AS EntryPointPackageInd
             FROM
               [$(SSISDB)].catalog.folders AS fldr
               JOIN [$(SSISDB)].catalog.projects AS prjct
                 ON prjct.folder_id = fldr.folder_id
                    AND @SSISDBProjectNames LIKE '%' + prjct.NAME + '%'
               JOIN [$(SSISDB)].catalog.packages AS pkg
                 ON pkg.project_id = prjct.project_id
                    AND pkg.NAME LIKE '%' + @SSISDBPackages + '%'
             WHERE
               @SSISDBFolderNames LIKE '%' + fldr.NAME + '%'
               AND @SSISDBPackages IS NOT NULL
             UNION
             -- To import all of the packages
             SELECT
               fldr.NAME        AS SSISDBFolderName
               ,prjct.NAME      AS SSISDBProjectName
               ,pkg.NAME        AS SSISDBPackageName
               ,pkg.entry_point AS EntryPointPackageInd
             FROM
               [$(SSISDB)].catalog.folders AS fldr
               JOIN [$(SSISDB)].catalog.projects AS prjct
                 ON prjct.folder_id = fldr.folder_id
                    AND @SSISDBProjectNames LIKE '%' + prjct.NAME + '%'
               JOIN [$(SSISDB)].catalog.packages AS pkg
                 ON pkg.project_id = prjct.project_id
             WHERE
               @SSISDBFolderNames LIKE '%' + fldr.NAME + '%'
               AND @SSISDBPackages IS NULL)
    MERGE cfg.ETLPackage trgt
    USING cte_ETLPackage src
    ON trgt.SSISDBPackageName = src.SSISDBPackageName
       AND trgt.SSISDBProjectName = src.SSISDBProjectName
       AND trgt.SSISDBFolderName = src.SSISDBFolderName
    WHEN NOT MATCHED THEN
      INSERT (SSISDBPackageName
              ,SSISDBProjectName
              ,SSISDBFolderName)
      VALUES(src.SSISDBPackageName
             ,src.SSISDBProjectName
             ,src.SSISDBFolderName);

    /* Insert records into ETLBatch_ETLPackageGroup*/
    WITH cte_ETLBatchPackageGroup
         AS (SELECT
               btch.ETLBatchID
               ,pkggrp.ETLPackageGroupId
             FROM
               [cfg].[ETLBatch] AS btch,
               [cfg].[ETLPackageGroup] AS pkggrp
             WHERE
              ETLBatchName = @ETLBatchName
              AND ETLPackageGroup = @ETLPackageGroupName)
    MERGE [cfg].[ETLBatch_ETLPackageGroup] trgt
    USING cte_ETLBatchPackageGroup src
    ON src.ETLBatchID = trgt.ETLBatchID
       AND trgt.ETLPackageGroupId = src.ETLPackageGroupId
    WHEN NOT MATCHED THEN
      INSERT (ETLBatchID
              ,ETLPackageGroupID)
      VALUES(src.ETLBatchID
             ,src.ETLPackageGroupID);

    /* Create ETLPackageGroup_ETLPackage record */
    WITH cte_ETLPackageGroup_ETLPackage
         AS (SELECT
               pkggrp.ETLPackageGroupId
               ,pkg.ETLPackageId
             FROM
               [cfg].[ETLPackageGroup] AS pkggrp,
               [cfg].[ETLPackage] AS pkg
             WHERE
               pkg.SSISDBPackageName LIKE '%' + @SSISDBPackages + '%'
               AND @SSISDBFolderNames LIKE '%' + pkg.SSISDBFolderName + '%'
               AND @SSISDBProjectNames LIKE '%' + pkg.SSISDBProjectName + '%'
               AND pkggrp.ETLPackageGroup = @ETLPackageGroupName
             UNION
             SELECT
               pkggrp.ETLPackageGroupId
               ,pkg.ETLPackageId
             FROM
               [cfg].[ETLPackageGroup] AS pkggrp,
               [cfg].[ETLPackage] AS pkg
             WHERE
               @SSISDBPackages IS NULL
               AND @SSISDBFolderNames LIKE '%' + pkg.SSISDBFolderName + '%'
               AND @SSISDBProjectNames LIKE '%' + pkg.SSISDBProjectName + '%'
               AND pkggrp.ETLPackageGroup = @ETLPackageGroupName)
    MERGE cfg.ETLPackageGroup_ETLPackage trgt
    USING cte_ETLPackageGroup_ETLPackage src
    ON trgt.ETLPackageGroupId = src.ETLPackageGroupId
       AND trgt.ETLPackageId = src.ETLPackageId
    WHEN NOT MATCHED THEN
      INSERT (ETLPackageGroupId
              ,ETLPackageId
              ,SupportSeverityLevelID)
      VALUES(src.ETLPackageGroupId
             ,src.ETLPackageId
             ,1);

    RETURN 0 
