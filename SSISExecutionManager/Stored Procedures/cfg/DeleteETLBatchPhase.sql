CREATE PROCEDURE [cfg].[DeleteETLBatchPhase]	@ETLBatchPhaseId INT
AS
    DELETE FROM ctl.[ETLBatchPhase]
    WHERE  [ETLBatchPhaseId] = @ETLBatchPhaseId

    RETURN 0 
