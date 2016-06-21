CREATE PROCEDURE [cfg].[DeleteETLBatchPhase_SQLCommand]	@ETLBatchPhaseId INT,
														@SQLCommandId INT
AS
    DELETE FROM ctl.[ETLBatchPhase_SQLCommand]
    WHERE  ETLBatchPhaseId = @ETLBatchPhaseId
           AND SQLCommandId = @SQLCommandId

    RETURN 0 
