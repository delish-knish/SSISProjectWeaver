
CREATE PROCEDURE [catalog].[set_customized_logging_level_description]
    @level_name NVARCHAR(128),
    @level_description NVARCHAR(MAX)
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
    
    UPDATE [internal].[customized_logging_levels]
    SET [description] = @level_description
    WHERE [name] = @level_name
        
    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(27237, 16, 1, @level_name) WITH NOWAIT
        RETURN 1
    END
    ELSE 
    BEGIN
        RETURN 0
    END
END
