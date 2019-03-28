








CREATE PROCEDURE [internal].[sync_validation_status]
        @operation_id   bigint,       
        @external  bit       
AS
    SET NOCOUNT ON
    DECLARE @status int
    DECLARE @validation_status int
    SET @status = 7
    
    
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

        
        IF (NOT EXISTS (SELECT operation_id FROM [internal].[operations]  
                        WHERE operation_id = @operation_id 
                        AND ([operation_type] = 300 
                            OR[operation_type] = 301)))
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
         
         SELECT @validation_status = [status] FROM [internal].[operations] 
                WHERE [operation_id] = @operation_id
         
         
         IF( @validation_status IN (3,6))
         BEGIN
             RETURN 1
         END
         
         
         IF EXISTS (SELECT [operation_id] FROM [internal].[extended_operation_info] 
                WHERE [operation_id] = @operation_id 
                AND [status] = 2)
         BEGIN
             SET @status = 6
             UPDATE [internal].[extended_operation_info] 
                SET [status] = @status,
                    [end_time] = @end_time 
                WHERE [operation_id] =@operation_id AND [status] = 2
         END
            
        
        ELSE IF EXISTS (SELECT [operation_id] FROM [internal].[extended_operation_info] 
                WHERE [operation_id] = @operation_id 
                AND [status] = 3)
        BEGIN
            SET @status = 3
        END
        
        
        ELSE IF EXISTS (SELECT [operation_id] FROM [internal].[extended_operation_info] 
                WHERE [operation_id] = @operation_id 
                AND [status] = 4)
        BEGIN
            SET @status = 4
        END
        
         
         
         IF(@external = 0 AND (@validation_status IN (2, 5)))
         BEGIN
             SET @status = 6
         END
        
        UPDATE [internal].[operations]
            SET [status] = @status,
                [end_time] = @end_time
            WHERE [operation_id] = @operation_id 
            AND ([status] NOT IN(3, 
                 6, 4, 7))
        
        
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
    
