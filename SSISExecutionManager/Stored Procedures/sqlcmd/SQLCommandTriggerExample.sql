CREATE PROCEDURE [sqlcmd].[SQLCommandTriggerExample] @TriggerMetInd BIT OUT
	
AS
	--Any SQL Statement that returns a bool will work. For example, if you want to test for a table being populated you can check for row count > 0
	-- and if the condition is met, trigger a package execution by adding the SQL Command to the ctl.ETLPackage_SQLCommandTrigger table.

    SET @TriggerMetInd = (SELECT 1 AS TriggerMetInd) 
RETURN 0
