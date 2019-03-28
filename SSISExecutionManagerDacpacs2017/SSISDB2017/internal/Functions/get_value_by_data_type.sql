





CREATE FUNCTION [internal].[get_value_by_data_type]
(
    @input_value varbinary(MAX),
    @data_type   nvarchar(128)
    )
RETURNS sql_variant 
AS
BEGIN
    DECLARE @value sql_variant
    IF @input_value IS NULL
    BEGIN
        RETURN NULL
    END
    
    IF @data_type = 'boolean'
    BEGIN
        SET @value = CONVERT(sql_variant, CONVERT(bit, @input_value))
    END

    ELSE IF @data_type = 'int16'
    BEGIN
        SET @value = CONVERT(sql_variant,  CONVERT(smallint, @input_value))
    END
    
    ELSE IF @data_type = 'int32'
    BEGIN
        SET @value = CONVERT(sql_variant,  CONVERT(int,@input_value))
    END
    
    ELSE IF @data_type = 'int64'
    BEGIN
        SET @value = CONVERT(sql_variant,  CONVERT(bigint,@input_value))
    END   

    ELSE IF @data_type = 'byte'
    BEGIN
        SET @value = CONVERT(sql_variant, CONVERT(tinyint, @input_value))
    END    
    
    ELSE IF @data_type = 'sbyte'
    BEGIN
        SET @value = CONVERT(sql_variant, CONVERT(smallint, @input_value))
    END    
    
    ELSE IF @data_type = 'double'
    BEGIN
        SET @value = CONVERT(sql_variant, CONVERT(float, CONVERT(decimal(38,18), @input_value)))
    END
    
    ELSE IF @data_type = 'datetime'
    BEGIN
        SET @value = CONVERT(sql_variant,  CONVERT(datetime2, @input_value))
    END     
       
    ELSE IF @data_type = 'single'
    BEGIN
        SET @value = CONVERT(sql_variant, CONVERT(float, CONVERT(decimal(38,18), @input_value)))
    END

    ELSE IF @data_type = 'decimal'
    BEGIN
        SET @value = CONVERT(sql_variant,  CONVERT(decimal(38,18), @input_value))
    END
   
    ELSE IF @data_type = 'string'
    BEGIN
        SET @value = CONVERT(sql_variant, CONVERT(nvarchar(4000), @input_value))
    END
    
    ELSE IF @data_type = 'uint32'
    BEGIN
        SET @value = CONVERT(sql_variant, CONVERT(int,  @input_value))
    END
    
    ELSE IF @data_type = 'uint64'
    BEGIN
        SET @value = CONVERT(sql_variant, CONVERT(bigint, @input_value))
    END          
    ELSE
    BEGIN
        SET @value = NULL
    END
    
    RETURN @value
END
