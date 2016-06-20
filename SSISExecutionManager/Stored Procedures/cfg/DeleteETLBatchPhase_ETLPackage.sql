CREATE PROCEDURE [cfg].[DeleteETLBatchPhase_ETLPackage] @ETLPackageId    INT,
															 @ETLBatchPhaseId INT
AS
    DELETE FROM ctl.[ETLBatchPhase_ETLPackage]
    WHERE  ETLPackageId = @ETLPackageId
           AND [ETLBatchPhaseId] = @ETLBatchPhaseId

    RETURN 0 
