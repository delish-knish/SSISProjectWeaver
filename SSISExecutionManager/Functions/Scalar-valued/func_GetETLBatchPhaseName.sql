CREATE FUNCTION [dbo].[func_GetETLPackageGroupName]
(
	@ETLPackageGroupId INT
)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @ReturnValue VARCHAR(50);

	SELECT @ReturnValue = [ETLPackageGroup] FROM [cfg].[ETLPackageGroup] WHERE [ETLPackageGroupId] = @ETLPackageGroupId;

	RETURN @ReturnValue
END
