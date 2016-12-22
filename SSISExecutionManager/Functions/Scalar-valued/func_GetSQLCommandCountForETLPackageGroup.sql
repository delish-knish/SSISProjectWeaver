CREATE FUNCTION [dbo].[func_GetSQLCommandCountForETLPackageGroup]
(
	@ETLPackageGroupId INT,
	@ExecuteAtBeginningOfGroupInd	BIT,
	@ExecuteAtEndOfGroupInd			BIT
)
RETURNS INT
AS
BEGIN
	DECLARE @ReturnValue SMALLINT;

	SELECT 
		@ReturnValue = COUNT(*) 
	FROM 
		ctl.[ETLPackageGroup_SQLCommand] WITH (NOLOCK)
	WHERE
		[ETLPackageGroupId] = @ETLPackageGroupId
		AND (NULLIF([ExecuteAtBeginningOfGroupInd], 0) = @ExecuteAtBeginningOfGroupInd
				OR NULLIF([ExecuteAtEndOfGroupInd], 0) = @ExecuteAtEndOfGroupInd);

	RETURN @ReturnValue;
END
