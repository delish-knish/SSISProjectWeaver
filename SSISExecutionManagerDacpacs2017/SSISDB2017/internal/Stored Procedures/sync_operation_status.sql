






CREATE PROCEDURE [internal].[sync_operation_status]
        @operation_id       bigint,       
        @operation_type     smallint      
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
                        FROM [internal].[operations]  
                        WHERE operation_id = @operation_id))
        BEGIN
            RAISERROR(27143, 16, 3, @operation_id) WITH NOWAIT;
        END

           
        DECLARE @can_access BIT;

        SET @can_access =
            [internal].[check_permission] 
                (4,
                 @operation_id,
                 2)
                     
        IF @can_access = 0
            BEGIN
                RAISERROR(27143, 16, 4, @operation_id) WITH NOWAIT;
            END
             
         DECLARE @end_time datetimeoffset
         SET @end_time = SYSDATETIMEOFFSET()
          
         UPDATE [internal].[operations] 
            SET [status] = 6,
                [end_time] = @end_time 
            WHERE operation_id =@operation_id
            AND ([status] = 2 OR [status] = 5)
            AND [operation_type] = @operation_type

        
        

        
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
    
