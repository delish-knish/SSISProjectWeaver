
CREATE PROCEDURE [internal].[update_master_settings]
    @MachineName			NVARCHAR(256),
	@MachineIP 				NVARCHAR(256),
	@MasterServicePort 		NVARCHAR(256),
	@SSLCertThumbprint	 	NVARCHAR(256),
	@MasterHeartbeatIntervalInMs NVARCHAR(256)
AS
BEGIN
	IF @MachineName IS NULL
	BEGIN
		RAISERROR('@MachineName argument is null.', 16, 1)
		RETURN
	END
	
	IF @MachineIP IS NULL
	BEGIN
		RAISERROR('@MachineIP argument is null.', 16, 1)
		RETURN
	END
	
	IF @MasterServicePort IS NULL
	BEGIN
		RAISERROR('@MasterServicePort argument is null.', 16, 1)
		RETURN
	END
	
	IF @SSLCertThumbprint IS NULL
	BEGIN
		RAISERROR('@SSLCertThumbprint argument is null.', 16, 1)
		RETURN
	END
	
	IF @MasterHeartbeatIntervalInMs IS NULL
	BEGIN
		RAISERROR('@MasterHeartbeatIntervalInMs argument is null.', 16, 1)
		RETURN
	END
		
	SET NOCOUNT ON
	
	BEGIN TRAN
	BEGIN TRY
	UPDATE [SSISDB].[internal].[master_properties] SET property_value = @MachineName  WHERE property_name = 'MACHINE_NAME'
	UPDATE [SSISDB].[internal].[master_properties] SET property_value = @MachineIP  WHERE property_name = 'MACHINE_IP'
	UPDATE [SSISDB].[internal].[master_properties] SET property_value = @MasterServicePort  WHERE property_name = 'MASTER_SERVICE_PORT'
	UPDATE [SSISDB].[internal].[master_properties] SET property_value = @SSLCertThumbprint  WHERE property_name = 'SSLCERT_THUMBPRINT'
	UPDATE [SSISDB].[internal].[master_properties] SET property_value = @MasterHeartbeatIntervalInMs  WHERE property_name = 'MASTER_HEARTBEAT_INTERVALINMS'
	
	COMMIT TRAN	

	END TRY
    BEGIN CATCH
		IF XACT_STATE() != 0
			ROLLBACK TRAN;
		THROW
	END CATCH
END
