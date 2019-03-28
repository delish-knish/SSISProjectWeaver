CREATE PROCEDURE [internal].[stop_operation_internal]
@operation_id BIGINT NULL, @process_id INT NULL, @operation_guid UNIQUEIDENTIFIER NULL
AS EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.ServerApi].[StopOperationInternal]

