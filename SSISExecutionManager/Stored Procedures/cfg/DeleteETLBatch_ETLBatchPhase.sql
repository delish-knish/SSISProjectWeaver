CREATE PROCEDURE [cfg].[DeleteETLBatch_ETLBatchPhase]	@ETLBatchId    INT,
														@ETLBatchPhaseId INT
AS
    DELETE FROM ctl.[ETLBatch_ETLBatchPhase]
    WHERE  ETLBatchId = @ETLBatchId
           AND [ETLBatchPhaseId] = @ETLBatchPhaseId

    RETURN 0 
