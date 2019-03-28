CREATE FUNCTION [internal].[convert_value]
(@origin_value SQL_VARIANT NULL, @data_type NVARCHAR (128) NULL)
RETURNS SQL_VARIANT
AS
 EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.ServerApi].[ConvertValue]

