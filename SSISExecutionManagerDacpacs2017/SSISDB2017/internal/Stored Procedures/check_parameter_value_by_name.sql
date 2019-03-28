
CREATE PROCEDURE [internal].[check_parameter_value_by_name]
    @value      sql_variant,   
    @parameter_name     sysname 
AS
BEGIN
    IF @parameter_name = 'LOGGING_LEVEL'
    BEGIN
        DECLARE @converted_value int
        SET @converted_value = CONVERT(int,@value)
        IF ((@converted_value < 0 OR @converted_value > 4)
            AND @converted_value <> 100)
        BEGIN
            RAISERROR(27217, 16 , 1, @converted_value) WITH NOWAIT
            RETURN 1 
        END
    END
    
    IF @parameter_name = 'CUSTOMIZED_LOGGING_LEVEL'
    BEGIN
        DECLARE @level_name NVARCHAR(128)
        SET @level_name = CONVERT(NVARCHAR(128),@value)
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
    END

    RETURN 0
END

