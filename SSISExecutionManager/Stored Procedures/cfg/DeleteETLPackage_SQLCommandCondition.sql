CREATE PROCEDURE [cfg].[ETLBatch_DeleteETLPackage_SQLCommandCondition] @ETLBatchId   INT,
                                                                       @ETLPackageId INT,
                                                                       @SQLCommandId INT
AS
    DELETE FROM ctl.[ETLBatch_ETLPackage_SQLCommandCondition]
    WHERE  ETLBatchId = @ETLBatchId
           AND ETLPackageId = @ETLPackageId
           AND SQLCommandId = @SQLCommandId

    RETURN 0 
