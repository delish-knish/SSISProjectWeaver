





CREATE PROCEDURE [internal].[check_data_type_value]
    @value      sql_variant,   
    @data_type  nvarchar(128)  
AS
BEGIN
    DECLARE @sql_type sysname
    DECLARE @converted_value sql_variant
    
    IF @data_type IS NULL
    BEGIN
        RAISERROR(27147, 16 , 1, @data_type) WITH NOWAIT
        RETURN 1
    END
    
    SET @sql_type = CONVERT(sysname, SQL_VARIANT_PROPERTY(@value, 'BaseType'));
    
    IF NOT EXISTS(SELECT [mapping_id] FROM [internal].[data_type_mapping]
                WHERE [ssis_data_type] = @data_type AND [sql_data_type] = @sql_type)
    BEGIN
        RAISERROR(27147, 16 , 1, @data_type) WITH NOWAIT
        RETURN 1    
    END 
    
    
    
    
    BEGIN TRY
        IF @data_type = 'boolean'
        BEGIN
            SET @converted_value = CONVERT(bit, @value)
        END

        ELSE IF @data_type = 'int16'
        BEGIN
            SET @converted_value =  CONVERT(smallint, @value)
        END
        
        ELSE IF @data_type = 'int32'
        BEGIN
            SET @converted_value = CONVERT(int,@value)
        END
        
        ELSE IF @data_type = 'int64'
        BEGIN
            SET @converted_value = CONVERT(bigint,@value)
        END   

        ELSE IF @data_type = 'byte'
        BEGIN
            SET @converted_value = CONVERT(tinyint, @value)
        END    
        
        ELSE IF @data_type = 'sbyte'
        BEGIN
            SET @converted_value = CONVERT(smallint, @value)
        END    
                
        ELSE IF @data_type = 'uint32'
        BEGIN
            SET @converted_value = CONVERT(sql_variant, CONVERT(bigint,  @value))
        END
        
        ELSE IF @data_type = 'uint64'
        BEGIN
            SET @converted_value = CONVERT(sql_variant, CONVERT(bigint, @value))
        END
        END TRY
    BEGIN CATCH
        THROW;
    END CATCH
        
    RETURN 0    
    
END
