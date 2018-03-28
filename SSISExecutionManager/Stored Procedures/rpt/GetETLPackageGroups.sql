CREATE PROCEDURE [rpt].[GetETLPackageGroupParamList] @ETLBatchId INT
AS
    SELECT
      [ETLPackageGroupId]
      ,[ETLPackageGroup]
    FROM
      [rpt].[ETLBatchesETLPackageGroups]
    WHERE
      [ETLBatchId] = @ETLBatchId
       OR @ETLBatchId IS NULL

    RETURN 0 
