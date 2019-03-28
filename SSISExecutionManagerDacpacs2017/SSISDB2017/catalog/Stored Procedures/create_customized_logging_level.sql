
CREATE PROCEDURE [catalog].[create_customized_logging_level]
    @level_name NVARCHAR(128),
    @level_description NVARCHAR(MAX) = NULL,
    @profile_value BIGINT = 0,
    @events_value BIGINT = 0,
    @level_id BIGINT = NULL OUTPUT
AS
BEGIN
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
    REVERT

    
    IF (IS_MEMBER('ssis_admin') = 0)
        AND (IS_SRVROLEMEMBER('sysadmin') = 0)
    BEGIN
        RAISERROR(27232, 16, 1, @level_name) WITH NOWAIT 
        RETURN 1
    END
    
    IF @level_name IS NULL
    BEGIN
        RAISERROR(27233, 16, 1) WITH NOWAIT
        RETURN 1
    END
    
    IF [internal].[is_valid_name](@level_name) = 0
    BEGIN
        RAISERROR(27234, 16, 1, @level_name) WITH NOWAIT
        RETURN 1
    END
    
    IF @profile_value < 0 OR @events_value < 0
    BEGIN
        RAISERROR(27240, 16, 1) WITH NOWAIT
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
        IF EXISTS 
        (
            SELECT [name]
            FROM [internal].[customized_logging_levels]
            WHERE [name] = @level_name
        )
        BEGIN
            RAISERROR(27235, 16, 1, @level_name)
            RETURN 1
        END
    
        INSERT INTO [internal].[customized_logging_levels]
        (
            [name],
            [description],
            [profile_value],
            [events_value],
            [created_by_sid],
            [created_by_name],
            [created_time]
        )
        VALUES
        (
            @level_name,
            @level_description,
            @profile_value,
            @events_value,
            @caller_sid,
            @caller_name,
            SYSDATETIMEOFFSET()
        )
        
        SET @level_id = SCOPE_IDENTITY()
        
        
        
        
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
