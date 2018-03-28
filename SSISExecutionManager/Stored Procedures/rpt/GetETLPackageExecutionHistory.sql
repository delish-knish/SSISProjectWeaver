CREATE PROCEDURE [rpt].[GetETLPackageExecutionNDaysHistory] @ETLPackageId INT,
                                                            @DaysBack     INT = 30
AS
    SELECT
      ETLPackageId
      ,SSISDBProjectName
      ,SSISDBPackageName
      ,PackageStartDateTime
      ,DATEDIFF(MINUTE, PackageStartDateTime, PackageEndDateTime) AS Duration
    FROM
      [rpt].[ETLPackageExecutionHistory]
    WHERE
      ETLPackageId = @ETLPackageId
      AND DATEDIFF(DD, PackageStartDateTime, GETDATE()) <= @DaysBack
    ORDER  BY
      PackageStartDateTime

    RETURN 0 
