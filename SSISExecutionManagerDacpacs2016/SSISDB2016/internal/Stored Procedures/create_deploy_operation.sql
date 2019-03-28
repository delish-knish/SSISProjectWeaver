CREATE PROCEDURE [internal].[create_deploy_operation]
    @folder_name nvarchar(128),
    @project_name nvarchar(128),
    @operation_id bigint output
AS 
    SET NOCOUNT ON
   
    
    DECLARE @caller_id     int
    DECLARE @caller_name   [internal].[adt_sname]
    DECLARE @caller_sid    [internal].[adt_sid]
    DECLARE @suser_name    [internal].[adt_sname]
    DECLARE @suser_sid     [internal].[adt_sid]
    
    EXECUTE AS CALLER
        EXEC [internal].[get_user_info]
            @caller_name OUTPUT,
            @caller_sid OUTPUT,
            @suser_name OUTPUT,
            @suser_sid OUTPUT,
            @caller_id OUTPUT;
          
          
        IF(
            EXISTS(SELECT [name]
                    FROM sys.server_principals
                    WHERE [sid] = @suser_sid AND [type] = 'S')  
            OR
            EXISTS(SELECT [name]
                    FROM sys.database_principals
                    WHERE ([sid] = @caller_sid AND [type] = 'S')) 
            )
        BEGIN
            RAISERROR(27123, 16, 1) WITH NOWAIT
            RETURN 1
        END
    REVERT
    
    IF(
            EXISTS(SELECT [name]
                    FROM sys.server_principals
                    WHERE [sid] = @suser_sid AND [type] = 'S')  
            OR
            EXISTS(SELECT [name]
                    FROM sys.database_principals
                    WHERE ([sid] = @caller_sid AND [type] = 'S')) 
            )
    BEGIN
            RAISERROR(27123, 16, 1) WITH NOWAIT
            RETURN 1
    END  
    
    DECLARE @folder_id bigint
    DECLARE @start_time     DATETIMEOFFSET
    DECLARE @return_value   int 
     
    
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
            EXECUTE AS CALLER
               SET @folder_id = 
                    (SELECT [folder_id] FROM [catalog].[folders] WHERE [name] = @folder_name)
            REVERT
                
            IF @folder_id IS NULL
            BEGIN
                RAISERROR(27104 , 16 , 1, @folder_name) WITH NOWAIT
            END 
            
            SET @start_time = SYSDATETIMEOFFSET() 
            

            EXEC @return_value = [internal].[insert_operation] 
                                101, 
                                @start_time,    
                                20,             
                                NULL,             
                                @project_name,
                                5,                                  
                                @start_time,    
                                null,           
                                @caller_sid,    
                                @caller_name,   
                                null,           
                                null,           
                                null,           
                                @operation_id OUTPUT  
        
        IF @return_value <> 0
        BEGIN
            RAISERROR(27169,16,1) WITH NOWAIT
        END
        
        
        EXEC @return_value = [internal].[init_object_permissions] 
                4, @operation_id, @caller_id 
        IF @return_value <> 0
        BEGIN
            
            RAISERROR(27153,16,1) WITH NOWAIT
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
