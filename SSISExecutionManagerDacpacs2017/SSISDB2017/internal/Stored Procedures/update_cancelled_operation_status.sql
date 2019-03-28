
CREATE PROCEDURE [internal].[update_cancelled_operation_status]
		@operation_id	bigint,		
		@stop_id		bigint		
AS
	SET NOCOUNT ON
    
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
		DECLARE @stopped_by_sid		varbinary(85)
		DECLARE @stopped_by_name	nvarchar(128)
		SELECT @stopped_by_sid = [caller_sid], @stopped_by_name = [caller_name]
		FROM [internal].[operations]
		WHERE [operation_id] = @stop_id

		
		UPDATE [internal].[operations]
		SET [stopped_by_sid] = @stopped_by_sid, [stopped_by_name] = @stopped_by_name, [status] = 3, [end_time] = SYSDATETIMEOFFSET()
		WHERE [operation_id] = @operation_id

		
		UPDATE [internal].[operations]
		SET [status] = 7, [end_time] = SYSDATETIMEOFFSET()
		WHERE [operation_id] = @stop_id

		
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY

    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           

        THROW
    END CATCH

    RETURN 0
