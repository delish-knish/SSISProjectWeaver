CREATE FUNCTION [internal].[is_valid_name]
(@object_name NVARCHAR (MAX) NULL)
RETURNS BIT
AS
 EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.ServerApi].[IsValidName]

