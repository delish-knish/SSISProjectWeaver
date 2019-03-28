
CREATE PROCEDURE [catalog].[update_master_address]
	@MasterAddress NVARCHAR(256)
AS
BEGIN
	IF @MasterAddress IS NULL
	BEGIN
		RAISERROR('@MasterAddress argument is null.', 16, 1)
		RETURN
	END
		
	SET NOCOUNT ON

	UPDATE [SSISDB].[internal].[master_properties] SET property_value = @MasterAddress  WHERE property_name = 'MASTER_ADDRESS'

END
