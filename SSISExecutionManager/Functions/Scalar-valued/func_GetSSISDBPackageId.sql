CREATE FUNCTION [dbo].[func_GetSSISDBPackageId] (@SSISDBPackageName NVARCHAR (260),
                                            @SSISDBProjectName NVARCHAR(128),
                                            @SSISDBFolderName  NVARCHAR(128))
RETURNS INT
AS
  BEGIN
      RETURN
        (SELECT
           pkg.package_id
         FROM
           [$(SSISDB)].catalog.packages pkg WITH (NOLOCK)
           JOIN [$(SSISDB)].catalog.projects prj WITH (NOLOCK)
             ON pkg.project_id = prj.project_id
           JOIN [$(SSISDB)].catalog.folders fld WITH (NOLOCK)
             ON prj.folder_id = fld.folder_id
         WHERE
          pkg.name = @SSISDBPackageName
          AND prj.name = @SSISDBProjectName
          AND fld.name = @SSISDBFolderName)
  END 
