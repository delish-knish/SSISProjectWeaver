CREATE PROCEDURE [internal].[start_execution_internal]
@project_id BIGINT NULL, @execution_id BIGINT NULL, @version_id BIGINT NULL, @use32BitRuntime SMALLINT NULL
AS EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.ServerApi].[StartExecutionInternal]

