CREATE FUNCTION [dbo].[func_GetSQLCommandCountForETLBatchPhase]
(
	@ETLBatchPhaseId INT,
	@ExecuteAtBeginningOfPhaseInd	BIT,
	@ExecuteAtEndOfPhaseInd			BIT
)
RETURNS INT
AS
BEGIN
	DECLARE @ReturnValue SMALLINT;

	SELECT 
		@ReturnValue = COUNT(*) 
	FROM 
		ctl.ETLBatchPhase_SQLCommand WITH (NOLOCK)
	WHERE
		ETLBatchPhaseId = @ETLBatchPhaseId
		AND (NULLIF(ExecuteAtBeginningOfPhaseInd, 0) = @ExecuteAtBeginningOfPhaseInd
				OR NULLIF(ExecuteAtEndOfPhaseInd, 0) = @ExecuteAtEndOfPhaseInd);

	RETURN @ReturnValue;
END
