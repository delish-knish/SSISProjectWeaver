
CREATE PROCEDURE [catalog].[delete_customized_logging_level]
    @level_name NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON
    
    
    IF (IS_MEMBER('ssis_admin') = 0) 
        AND (IS_SRVROLEMEMBER('sysadmin') = 0)
    BEGIN
        RAISERROR(27236, 16, 1, @level_name) WITH NOWAIT
        RETURN 1
    END
    
    IF @level_name IS NULL
    BEGIN
        RAISERROR(27233, 16, 1) WITH NOWAIT
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
        IF NOT EXISTS 
        (
            SELECT [name]
            FROM [internal].[customized_logging_levels]
            WHERE [name] = @level_name
        )
        BEGIN
            RAISERROR(27237, 16, 1, @level_name) WITH NOWAIT
            RETURN 1
        END
    
        DELETE FROM [internal].[customized_logging_levels]
        WHERE [name] = @level_name
        
        
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
