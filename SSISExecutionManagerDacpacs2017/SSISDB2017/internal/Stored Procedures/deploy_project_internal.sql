CREATE PROCEDURE [internal].[deploy_project_internal]
@deploy_id BIGINT NULL, @version_id BIGINT NULL, @project_id BIGINT NULL, @project_name NVARCHAR (128) NULL
AS EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.ServerApi].[DeployProjectInternal]

