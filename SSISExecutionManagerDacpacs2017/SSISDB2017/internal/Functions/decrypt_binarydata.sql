CREATE FUNCTION [internal].[decrypt_binarydata]
(@algorithmName NVARCHAR (255) NULL, @key VARBINARY (8000) NULL, @IV VARBINARY (8000) NULL, @binary_value VARBINARY (MAX) NULL)
RETURNS VARBINARY (MAX)
AS
 EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.Security.CryptoGraphy].[DecryptBinaryData]

