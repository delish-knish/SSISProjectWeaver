CREATE PROCEDURE [rpt].[GetETLPackageParamList]
AS
    SELECT
      [ETLPackageId]
      ,[SSISDBProjectName] + '.'
       + [SSISDBPackageName] AS [ETLPackageName]
    FROM
      [rpt].[ETLPackages]
    WHERE
      ETLPackageId > 0
    ORDER  BY
      [SSISDBProjectName]
      ,[SSISDBPackageName]

    RETURN 0 
