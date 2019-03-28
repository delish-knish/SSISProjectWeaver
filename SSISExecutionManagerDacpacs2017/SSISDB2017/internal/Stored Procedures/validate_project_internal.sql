CREATE PROCEDURE [internal].[validate_project_internal]
@project_id BIGINT NULL, @version_id BIGINT NULL, @validation_id BIGINT NULL, @environment_scope NCHAR (1) NULL, @use32bitruntime SMALLINT NULL
AS EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.ServerApi].[ValidateProjectInternal]

