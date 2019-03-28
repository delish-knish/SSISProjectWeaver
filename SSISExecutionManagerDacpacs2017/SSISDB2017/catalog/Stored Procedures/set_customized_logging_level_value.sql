
CREATE PROCEDURE [catalog].[set_customized_logging_level_value]
    @level_name NVARCHAR(128),
    @property_name NVARCHAR(128),
    @property_value bigint
AS
BEGIN
    SET NOCOUNT ON

    
    IF (IS_MEMBER('ssis_admin') = 0)
        AND (IS_SRVROLEMEMBER('sysadmin') = 0)
    BEGIN
        RAISERROR(27239, 16, 1) WITH NOWAIT
        RETURN 1
    END

    IF @level_name IS NULL
    BEGIN
        RAISERROR(27233, 16, 1) WITH NOWAIT
        RETURN 1
    END
    
    IF @property_value < 0
    BEGIN
        RAISERROR(27240, 16, 1) WITH NOWAIT
        RETURN 1
    END

    IF (@property_name = 'PROFILE')
    BEGIN
        UPDATE [internal].[customized_logging_levels]
        SET [profile_value] = @property_value
        WHERE [name] = @level_name
        
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR(27237, 16, 1, @level_name) WITH NOWAIT
            RETURN 1
        END
    END
    ELSE IF (@property_name = 'EVENTS')
    BEGIN
        UPDATE [internal].[customized_logging_levels]
        SET [events_value] = @property_value
        WHERE [name] = @level_name
        
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR(27237, 16, 1, @level_name) WITH NOWAIT
            RETURN 1
        END
    END
    ELSE 
    BEGIN
        RAISERROR(27101, 16 , 1, @property_name) WITH NOWAIT
        RETURN 1
    END

    RETURN 0
END
