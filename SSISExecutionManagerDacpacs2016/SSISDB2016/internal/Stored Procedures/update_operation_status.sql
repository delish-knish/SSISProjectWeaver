



CREATE PROCEDURE [internal].[update_operation_status]
        @operation_id       bigint,       
        @process_id         int,          
        @end_time           datetimeoffset  = NULL,     
        @status             int           
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
        
        
        IF (NOT EXISTS (SELECT operation_id
                        FROM [catalog].[operations] 
                        WHERE operation_id = @operation_id))
        BEGIN
            RAISERROR(27143, 16, 1, @operation_id) WITH NOWAIT
        END
        
               
        DECLARE @can_access BIT;
        IF [internal].[check_permission]
        (
            4,
            @operation_id,
            2
         ) = 0
         BEGIN
             RAISERROR(27143, 16, 2, @operation_id) WITH NOWAIT
             RETURN 1
         END 
        
        UPDATE [internal].[operations] 
            SET [process_id] = @process_id ,
                [status] = @status,
                [end_time] =  @end_time 
            WHERE operation_id =@operation_id
        IF @@ROWCOUNT <> 1
        BEGIN
            RAISERROR(27112, 16, 10, N'operations') WITH NOWAIT
        END

        
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
