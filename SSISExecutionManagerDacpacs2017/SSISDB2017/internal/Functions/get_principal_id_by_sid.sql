
CREATE FUNCTION [internal].[get_principal_id_by_sid]
(
        @sid        [internal].[adt_sid] 
)
RETURNS INT
AS
BEGIN
	DECLARE @Result INT
	select @Result = [principal_id] from [sys].[database_principals] where [sid]=@sid;
	RETURN @Result
END

