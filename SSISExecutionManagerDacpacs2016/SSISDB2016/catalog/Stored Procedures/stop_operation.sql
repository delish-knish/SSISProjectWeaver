
 
CREATE PROCEDURE [catalog].[stop_operation]
    @operation_id bigint                                
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @operation_guid uniqueIdentifier   
    DECLARE @process_id bigint
    DECLARE @return_value int
    DECLARE @stop_id bigint
    DECLARE @status int
    
    IF @operation_id IS NULL 
    BEGIN
       RAISERROR(27100, 16 , 11, 'operation_id') WITH NOWAIT
       RETURN 1
    END
    
    EXEC @return_value = [internal].[prepare_stop] 
                            @operation_id,
                            @process_id output, 
                            @operation_guid output,
                            @stop_id output

    IF @return_value = 0
    BEGIN
        BEGIN TRY
            EXEC @return_value=[internal].[stop_operation_internal] 
                    @operation_id, 
                    @process_id,
                    @operation_guid
        END TRY
        BEGIN CATCH         
            UPDATE [internal].[operations] SET 
                [end_time]  = SYSDATETIMEOFFSET(),
                [status]    = 4
                WHERE operation_id    = @stop_id;
            THROW;
        END CATCH
    END
    
    SET @status =
        CASE
            WHEN (@return_value = 0) THEN 7
            ELSE 4
        END

    UPDATE [internal].[operations] SET 
        [end_time]  = SYSDATETIMEOFFSET(),
        [status]    = @status
        WHERE operation_id    = @stop_id
    RETURN @return_value       
END
