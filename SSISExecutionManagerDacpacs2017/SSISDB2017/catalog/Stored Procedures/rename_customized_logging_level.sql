
CREATE PROCEDURE [catalog].[rename_customized_logging_level]
    @old_name NVARCHAR(128),
    @new_name NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON
    
    
    IF (IS_MEMBER('ssis_admin') = 0)
        AND (IS_SRVROLEMEMBER('sysadmin') = 0)
    BEGIN
        RAISERROR(27238, 16, 1, @old_name, @new_name) WITH NOWAIT
        RETURN 1
    END
    
    IF (@old_name IS NULL) OR (@new_name IS NULL)
    BEGIN
        RAISERROR(27233, 16, 1) WITH NOWAIT
        RETURN 1
    END
    
    IF [internal].[is_valid_name](@new_name) = 0
    BEGIN
        RAISERROR(27234, 16, 1, @new_name) WITH NOWAIT
        RETURN 1
    END
    
    
    IF @new_name = @old_name
    BEGIN
        RETURN 0
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
        IF NOT EXISTS 
        (
            SELECT [name]
            FROM [internal].[customized_logging_levels]
            WHERE [name] = @old_name
        )
        BEGIN
            RAISERROR(27237, 16, 1, @old_name) WITH NOWAIT
            RETURN 1
        END
        
        IF EXISTS 
        (
            SELECT [name]
            FROM [internal].[customized_logging_levels]
            WHERE [name] = @new_name
        )
        BEGIN
            RAISERROR(27235, 16, 1, @new_name) WITH NOWAIT
            RETURN 1
        END
        
        UPDATE [internal].[customized_logging_levels]
        SET [name] = @new_name
        WHERE [name] = @old_name
        
        IF @@ROWCOUNT = 0
        BEGIN
             RAISERROR(27112, 16, 10, N'customized_logging_levels') WITH NOWAIT
             RETURN 1
        END
        ELSE 
        BEGIN
            
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
            RETURN 0
        END
    END TRY
     
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                           
        THROW
    END CATCH
END
