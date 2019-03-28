
CREATE PROCEDURE [catalog].[enable_scaleout]

AS
BEGIN
SET NOCOUNT ON

IF (IS_SRVROLEMEMBER('sysadmin') <> 1)
	BEGIN
		RAISERROR(27260, 16, 1) WITH NOWAIT
		RETURN 1
	END

DECLARE @agentPassword nvarchar(256)
DECLARE @servername sysname
DECLARE @connectionString nvarchar(max)
DECLARE @hardcodedCatalogName nvarchar(max)

EXEC [internal].[GenerateRandomPasswords] @charset =  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789>_!@#$%&=?<>*()^&=-;.', @password = @agentPassword OUTPUT
SET @servername = CONVERT(sysname, SERVERPROPERTY('servername'))
SET @hardcodedCatalogName = 'SSISDB'
SET @connectionString = 'Data Source=' + @servername + ';Initial Catalog=' + @hardcodedCatalogName + ';User Id=##MS_SSISLogDBWorkerAgentLogin##;Password=''' + @agentPassword + ''';'

EXEC [internal].[update_logdb_info] @servername, @connectionString
EXEC [internal].[enable_scaleout] @agentPassword

END
