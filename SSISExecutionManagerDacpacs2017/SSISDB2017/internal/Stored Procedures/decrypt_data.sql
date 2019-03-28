
CREATE PROCEDURE [internal].[decrypt_data]
		@key_name               [internal].[adt_name],
		@certificate_name       [internal].[adt_name],
		@data 	nvarchar(max),
		@decrypted_data nvarchar(max) output
WITH EXECUTE AS 'AllSchemaOwner'
AS
	SET NOCOUNT ON
    DECLARE @open_cert_sqlString    nvarchar(1024)
	DECLARE @close_cert_sqlString   nvarchar(1024)

	SET @open_cert_sqlString = 'OPEN SYMMETRIC KEY ' + @key_name 
		+ ' DECRYPTION BY CERTIFICATE ' + @certificate_name
	SET @close_cert_sqlString = 'CLOSE SYMMETRIC KEY '+ @key_name
	
	IF NOT EXISTS (SELECT [key_name] 
    FROM [internal].[catalog_encryption_keys]
    WHERE [key_name] = @key_name)
    BEGIN
        RAISERROR(27250, 16 ,1) WITH NOWAIT
        RETURN 1
    END	 

	EXECUTE sp_executesql @open_cert_sqlString 
	
	SET @decrypted_data = DECRYPTBYKEY(@data)

	EXECUTE sp_executesql @close_cert_sqlString 
