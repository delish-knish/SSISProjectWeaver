
CREATE FUNCTION [internal].[get_input_value]
(
    @input_value NVARCHAR(MAX),
	@name		 NVARCHAR(MAX)
    )
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @return_value NVARCHAR(MAX)
	SELECT @return_value = [value]
	FROM OPENJSON(@input_value) WITH (name NVARCHAR(MAX) '$.name', value NVARCHAR(MAX) '$.value')
	WHERE name = @name
	RETURN @return_value
END
