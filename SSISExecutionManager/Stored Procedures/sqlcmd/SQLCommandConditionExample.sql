CREATE PROCEDURE [sqlcmd].[SQLCommandConditionExample] @ConditionMetInd BIT OUT
	
AS
	--Any SQL Statement that returns a bool will work. For example, if you want to test for a table being populated you can check for row count > 0
	-- and if the condition is met, allow a package to execute by adding the SQL Command to the ctl.ETLPackage_SQLCommandCondition table.

    SET @ConditionMetInd = (SELECT 1 AS ConditionMetInd) 
RETURN 0
