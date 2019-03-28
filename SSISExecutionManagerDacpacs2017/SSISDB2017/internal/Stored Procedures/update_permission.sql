
CREATE PROCEDURE [internal].[update_permission]
    @object_type SMALLINT,
    @object_id BIGINT,
    @principal_id INTEGER,
    @permission_type SMALLINT,
    @is_deny BIT,
    @grantor_id INTEGER
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @ret INTEGER
    DECLARE @is_role BIT
    DECLARE @sid [internal].[adt_sid]
    DECLARE @grantor_sid [internal].[adt_sid]
    
    
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
        EXEC @ret = internal.check_permission_parameters
             @object_type,
             @object_id,
             @principal_id,
             @permission_type,
             @is_role OUTPUT
             
        IF @ret<>0  
             RETURN 1
        
        SELECT @sid = USER_SID(@principal_id)

        SELECT @grantor_sid = USER_SID(@grantor_id)

        IF @object_type = 1
        BEGIN
            
        MERGE [internal].[folder_permissions] AS TARGET
        USING
           (VALUES (@object_type,@object_id,@sid,@permission_type,@is_deny))
           AS SOURCE ([object_type],[object_id],[sid],[permission_type],[is_deny])
        ON   TARGET.[object_id] = SOURCE.[object_id]
             AND TARGET.[permission_type] = SOURCE.[permission_type]
             AND TARGET.[sid] = SOURCE.[sid]
        WHEN MATCHED THEN
           UPDATE SET TARGET.[is_deny] = @is_deny, TARGET.[grantor_sid] = @grantor_sid
        WHEN NOT MATCHED THEN
           INSERT ([object_id],[sid],[permission_type],[is_deny],[is_role],[grantor_sid])
           VALUES (@object_id,@sid,@permission_type,@is_deny,@is_role,@grantor_sid);
        IF @@ROWCOUNT<> 1
        BEGIN
            RAISERROR(27112, 16, 10, N'folder_permissions') WITH NOWAIT
            RETURN 1
        END                                                                                     
        END
        ELSE IF @object_type = 2
        BEGIN
            
        MERGE [internal].[project_permissions] AS TARGET
        USING
           (VALUES (@object_type,@object_id,@sid,@permission_type,@is_deny))
           AS SOURCE ([object_type],[object_id],[sid],[permission_type],[is_deny])
        ON   TARGET.[object_id] = SOURCE.[object_id]
             AND TARGET.[permission_type] = SOURCE.[permission_type]
             AND TARGET.[sid] = SOURCE.[sid]
        WHEN MATCHED THEN
           UPDATE SET TARGET.[is_deny] = @is_deny, TARGET.[grantor_sid] = @grantor_sid
        WHEN NOT MATCHED THEN
           INSERT ([object_id],[sid],[permission_type],[is_deny],[is_role],[grantor_sid])
           VALUES (@object_id,@sid,@permission_type,@is_deny,@is_role,@grantor_sid);
        IF @@ROWCOUNT<> 1
        BEGIN
            RAISERROR(27112, 16, 10, N'project_permissions') WITH NOWAIT
            RETURN 1
        END                                                                                     
        END
        ELSE IF @object_type = 3
        BEGIN
            
        MERGE [internal].[environment_permissions] AS TARGET
        USING
           (VALUES (@object_type,@object_id,@sid,@permission_type,@is_deny))
           AS SOURCE ([object_type],[object_id],[sid],[permission_type],[is_deny])
        ON   TARGET.[object_id] = SOURCE.[object_id]
             AND TARGET.[permission_type] = SOURCE.[permission_type]
             AND TARGET.[sid] = SOURCE.[sid]
        WHEN MATCHED THEN
           UPDATE SET TARGET.[is_deny] = @is_deny, TARGET.[grantor_sid] = @grantor_sid
        WHEN NOT MATCHED THEN
           INSERT ([object_id],[sid],[permission_type],[is_deny],[is_role],[grantor_sid])
           VALUES (@object_id,@sid,@permission_type,@is_deny,@is_role,@grantor_sid);
        IF @@ROWCOUNT<> 1
        BEGIN
            RAISERROR(27112, 16, 10, N'environment_permissions') WITH NOWAIT
            RETURN 1
        END                                                                                     
        END
        ELSE
        BEGIN
            
        MERGE [internal].[operation_permissions] AS TARGET
        USING
           (VALUES (@object_type,@object_id,@sid,@permission_type,@is_deny))
           AS SOURCE ([object_type],[object_id],[sid],[permission_type],[is_deny])
        ON   TARGET.[object_id] = SOURCE.[object_id]
             AND TARGET.[permission_type] = SOURCE.[permission_type]
             AND TARGET.[sid] = SOURCE.[sid]
        WHEN MATCHED THEN
           UPDATE SET TARGET.[is_deny] = @is_deny, TARGET.[grantor_sid] = @grantor_sid
        WHEN NOT MATCHED THEN
           INSERT ([object_id],[sid],[permission_type],[is_deny],[is_role],[grantor_sid])
           VALUES (@object_id,@sid,@permission_type,@is_deny,@is_role,@grantor_sid);
        IF @@ROWCOUNT<> 1
        BEGIN
            RAISERROR(27112, 16, 10, N'operation_permissions') WITH NOWAIT
            RETURN 1
        END                                                                                     
        END
        
        
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
        RETURN 0
    END TRY
    
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        THROW
    END CATCH
END
