CREATE FUNCTION [dbo].[func_GetSSISDBPackageId] (@SSISDBPackageName VARCHAR (260),
                                            @SSISDBProjectName VARCHAR(128),
                                            @SSISDBFolderName  VARCHAR(128))
RETURNS INT
AS
  BEGIN
      RETURN
        (SELECT
           pkg.package_id
         FROM
           [$(SSISDB)].catalog.packages pkg
           JOIN [$(SSISDB)].catalog.projects prj
             ON pkg.project_id = prj.project_id
           JOIN [$(SSISDB)].catalog.folders fld
             ON prj.folder_id = fld.folder_id
         WHERE
          pkg.name = @SSISDBPackageName
          AND prj.name = @SSISDBProjectName
          AND fld.name = @SSISDBFolderName)
  END 
