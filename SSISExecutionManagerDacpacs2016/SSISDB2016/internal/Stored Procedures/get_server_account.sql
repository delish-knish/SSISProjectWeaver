CREATE PROCEDURE [internal].[get_server_account]
@account_name [internal].[adt_name] NULL OUTPUT
AS EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.ServerApi].[GetServerAccount]

