CREATE PROCEDURE [internal].[create_extended_operation_info]
        @operation_id       bigint,         
        @object_name        nvarchar(260), 
        @object_type        int,            
        @reference_id       bigint = NULL,         
        @status             int,            
        @info_id            bigint output   
AS
    DECLARE @result bit
    DECLARE @start_time datetimeoffset
    
    IF @operation_id IS NULL OR @object_name IS NULL
        OR @object_type IS NULL OR @status IS NULL
    BEGIN
        RAISERROR(27138, 16 , 4) WITH NOWAIT
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
        
        IF NOT EXISTS (SELECT [operation_id] FROM [internal].[operations]
            WHERE [operation_id] = @operation_id 
            AND ([operation_type] = 301 
                OR [operation_type] = 300)
            AND [status] = 2)
        BEGIN
            RAISERROR(27143 , 16 , 1, @operation_id) WITH NOWAIT  
        END
    
        SET @result = [internal].[check_permission]
        (
            4,
            @operation_id,
            2
         ) 
        IF @result= 0
        BEGIN
            RAISERROR(27143 , 16 , 1, @operation_id) WITH NOWAIT    
        END
        
        SET @start_time = SYSDATETIMEOFFSET();
        
        INSERT INTO [internal].[extended_operation_info]
                   ([operation_id],
                    [object_name],
                    [object_type],
                    [reference_id],
                    [status],
                    [start_time],
                    [end_time])
             VALUES
                   (@operation_id,
                   @object_name,
                   @object_type,
                   @reference_id,
                   @status,
                   @start_time,
                   null)
          IF @@ROWCOUNT = 1
          BEGIN
            SET @info_id = scope_identity()
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
    
