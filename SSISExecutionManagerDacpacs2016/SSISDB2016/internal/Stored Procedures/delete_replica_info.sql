
CREATE PROCEDURE [internal].[delete_replica_info]
	@server_name		nvarchar(256)
AS
BEGIN
	SET NOCOUNT ON

	IF (@server_name IS NULL)
	BEGIN
		RAISERROR(27138, 16 , 6) WITH NOWAIT 
        RETURN 1 
	END

	
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
    
    
    
    DECLARE @tran_count INT = @@TRANCOUNT;
    DECLARE @savepoint_name NCHAR(32);
    IF @tran_count > 0
    BEGIN
        SET @savepoint_name = REPLACE(CONVERT(NCHAR(36), NEWID()), N'-', N'');
        SAVE TRANSACTION @savepoint_name;
    END
    ELSE
        BEGIN TRANSACTION;                                                                                      
    BEGIN TRY
		IF EXISTS (SELECT * FROM [internal].[alwayson_support_state] WHERE [server_name] = @server_name)
			DELETE FROM [internal].[alwayson_support_state] WHERE [server_name] = @server_name
		ELSE
		BEGIN
			RAISERROR(27228, 16, 1, @server_name) WITH NOWAIT 
			RETURN 1
		END
	
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        THROW;
    END CATCH
	
	RETURN 0
END
