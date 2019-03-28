CREATE FUNCTION [internal].[get_package_data]
(@key_name NVARCHAR (255) NULL, @KEY VARBINARY (8000) NULL, @IV VARBINARY (8000) NULL, @project_version_lsn BIGINT NULL, @project_id BIGINT NULL)
RETURNS 
     TABLE (
        [name]         NVARCHAR (260)  NULL,
        [package_data] VARBINARY (MAX) NULL)
WITH EXECUTE AS N'AllSchemaOwner'
AS
 EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.Security.CryptoGraphy].[GetDecryptedPackageData]

