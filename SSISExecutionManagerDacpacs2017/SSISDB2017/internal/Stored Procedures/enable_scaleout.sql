
CREATE PROCEDURE [internal].[enable_scaleout]
  @agent_password			NVARCHAR(MAX) = NULL

AS
BEGIN
SET NOCOUNT ON

IF (IS_SRVROLEMEMBER('sysadmin') <> 1)
	BEGIN
		RAISERROR(27260, 16, 1) WITH NOWAIT
		RETURN 1
	END

DECLARE @accountName AS SYSNAME
DECLARE @strExec NVARCHAR (MAX)
DECLARE @instance_version NVARCHAR(1024)
DECLARE @master_registry_path NVARCHAR(MAX)
DECLARE @key_value NVARCHAR(1024)

SET @instance_version = SUBSTRING (CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),1,2) + N'0';
SET @master_registry_path = N'SOFTWARE\\Microsoft\\Microsoft SQL Server\\' + @instance_version + N'\\DTS\\Setup\\SQL_IS_Master';
EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@master_registry_path, N'Version', @key_value output;

IF @key_value IS NULL
	BEGIN
		RAISERROR(27261, 16, 1) WITH NOWAIT
		RETURN 1
	END

SET @accountName = N'NT Service\SSISScaleOutMaster140'
IF (SUSER_SID(@accountName) IS NOT NULL AND NOT EXISTS (SELECT * FROM sys.server_principals WHERE NAME = @accountName))
BEGIN
	PRINT N'Adding login for ' + @accountName

	SET @strExec = N'CREATE LOGIN ' + QUOTENAME(@accountName) + ' FROM WINDOWS'
	EXEC (@strExec)

	IF EXISTS(SELECT * FROM sys.database_principals where name = 'SSISScaleOutMasterUser140')
		DROP USER SSISScaleOutMasterUser140

	SET @strExec = N'CREATE USER SSISScaleOutMasterUser140 for login '  + QUOTENAME(@accountName) 
	EXEC (@strExec)

	SET @strExec = N'sp_addrolemember ''ssis_admin'', ''SSISScaleOutMasterUser140'''
	EXEC (@strExec)
END


IF EXISTS(SELECT * FROM sys.server_principals where name = '##MS_SSISLogDBWorkerAgentLogin##')
    DROP LOGIN ##MS_SSISLogDBWorkerAgentLogin##

EXEC ('CREATE LOGIN ##MS_SSISLogDBWorkerAgentLogin## WITH PASSWORD =''' + @agent_password+''', CHECK_POLICY = OFF')

IF EXISTS(SELECT * FROM sys.database_principals where name = '##MS_SSISLogDBWorkerAgentUser##')
	DROP USER ##MS_SSISLogDBWorkerAgentUser##

CREATE USER ##MS_SSISLogDBWorkerAgentUser## FOR LOGIN ##MS_SSISLogDBWorkerAgentLogin##

EXEC sp_addrolemember 'ssis_cluster_worker', '##MS_SSISLogDBWorkerAgentUser##'

IF EXISTS(SELECT * FROM [SSISDB].[catalog].[master_properties] WHERE [property_name] = 'IS_SCALEOUT_ENABLED')
	UPDATE [internal].[master_properties] SET [property_value] = 'TRUE' WHERE [property_name] = 'IS_SCALEOUT_ENABLED'
ELSE
	INSERT INTO [internal].[master_properties] VALUES ('IS_SCALEOUT_ENABLED', 'TRUE')

END
