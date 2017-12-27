CREATE PROCEDURE [cfg].[DeleteETLBatch_ETLPackageGroup]	@ETLBatchId    INT,
														@ETLPackageGroupId INT
AS
    DELETE FROM [cfg].[ETLBatch_ETLPackageGroup]
    WHERE  ETLBatchId = @ETLBatchId
           AND [ETLPackageGroupId] = @ETLPackageGroupId

    RETURN 0 
