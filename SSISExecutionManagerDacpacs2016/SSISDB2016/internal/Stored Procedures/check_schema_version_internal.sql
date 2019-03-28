CREATE PROCEDURE [internal].[check_schema_version_internal]
@operationId BIGINT NULL, @use32bitruntime SMALLINT NULL, @serverBuild NVARCHAR (1024) NULL OUTPUT, @schemaVersion INT NULL OUTPUT, @schemaBuild NVARCHAR (1024) NULL OUTPUT, @assemblyBuild NVARCHAR (1024) NULL OUTPUT, @componentVersion NVARCHAR (1024) NULL OUTPUT, @compatibilityStatus SMALLINT NULL OUTPUT
AS EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.ServerApi].[CheckSchemaVersionInternal]

