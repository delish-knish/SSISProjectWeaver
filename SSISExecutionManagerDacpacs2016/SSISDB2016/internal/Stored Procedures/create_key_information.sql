CREATE PROCEDURE [internal].[create_key_information]
@algorithm_name NVARCHAR (255) NULL, @key VARBINARY (8000) NULL OUTPUT, @IV VARBINARY (8000) NULL OUTPUT
AS EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.Security.CryptoGraphy].[CreateKeyInformation]

