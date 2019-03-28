CREATE FUNCTION [catalog].[get_operation_log_size]()
RETURNS bigint
AS 
BEGIN
    DECLARE @value bigint
    DECLARE @tmp_value bigint
    
    SET @value = 0
    
    SET @tmp_value = internal.get_space_used('internal.operation_messages')
    IF(@tmp_value < 0)
    BEGIN
        RETURN -1
    END  
    SET @value = @value + @tmp_value
    
    SET @tmp_value = internal.get_space_used('internal.operations')
    IF(@tmp_value < 0)
    BEGIN
        RETURN -1
    END  
    SET @value = @value + @tmp_value
    
    SET @tmp_value = internal.get_space_used('internal.executions')
    IF(@tmp_value < 0)
    BEGIN
        RETURN -1
    END  
    SET @value = @value + @tmp_value
        SET @tmp_value = internal.get_space_used('internal.validations')
    IF(@tmp_value < 0)
    BEGIN
        RETURN -1
    END  
    SET @value = @value + @tmp_value
    
    SET @tmp_value = internal.get_space_used('internal.extended_operation_info')
    IF(@tmp_value < 0)
    BEGIN
        RETURN -1
    END  
    SET @value = @value + @tmp_value
    
    SET @tmp_value = internal.get_space_used('internal.execution_parameter_values')
    IF(@tmp_value < 0)
    BEGIN
        RETURN -1
    END  
    SET @value = @value + @tmp_value    
    
    SET @tmp_value = internal.get_space_used('internal.event_messages')
    IF(@tmp_value < 0)
    BEGIN
        RETURN -1
    END  
    SET @value = @value + @tmp_value    
    
    SET @tmp_value = internal.get_space_used('internal.event_message_context')
    IF(@tmp_value < 0)
    BEGIN
        RETURN -1
    END  
    SET @value = @value + @tmp_value    
    
    SET @tmp_value = internal.get_space_used('internal.executable_statistics')
    IF(@tmp_value < 0)
    BEGIN
        RETURN -1
    END  
    SET @value = @value + @tmp_value    
    
    SET @tmp_value = internal.get_space_used('internal.executables')
    IF(@tmp_value < 0)
    BEGIN
        RETURN -1
    END  
    SET @value = @value + @tmp_value    

    RETURN @value
END
