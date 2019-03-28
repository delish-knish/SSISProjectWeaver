CREATE FUNCTION [internal].[get_isserver_processes]
( )
RETURNS 
     TABLE (
        [process_id] BIGINT NULL)
AS
 EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.StartupApi].[GetISServerProcesses]

