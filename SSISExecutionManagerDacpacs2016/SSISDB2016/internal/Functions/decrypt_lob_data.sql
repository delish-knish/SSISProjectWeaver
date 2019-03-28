




CREATE FUNCTION [internal].[decrypt_lob_data]
( 
    @key_name nvarchar(255), 
    @KEY varbinary(8000),
    @IV varbinary(8000),
    @lob varbinary(max) 
)
RETURNS varbinary(max)
WITH EXECUTE AS 'AllSchemaOwner'
AS
BEGIN
    DECLARE @decrypted_binary varbinary(MAX)
    SET @decrypted_binary = (SELECT [internal].[decrypt_binarydata](@key_name, @KEY,@IV, @lob))
    RETURN @decrypted_binary
END
