CREATE FUNCTION [dbo].[func_GetETLBatchPhaseName]
(
	@ETLBatchPhaseId INT
)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @ReturnValue VARCHAR(50);

	SELECT @ReturnValue = [ETLBatchPhase] FROM ctl.ETLBatchPhase WHERE ETLBatchPhaseId = @ETLBatchPhaseId;

	RETURN @ReturnValue
END
