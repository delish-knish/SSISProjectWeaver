CREATE FUNCTION [catalog].[dm_execution_performance_counters](@execution_id bigint = NULL)
RETURNS @ret TABLE
([execution_id] bigint,
 [counter_name] sysname,
 [counter_value] bigint)
WITH EXECUTE AS CALLER
AS
BEGIN
    IF (@execution_id IS NULL)
    BEGIN
        DECLARE @current_execution_id bigint
        DECLARE @current_execution_guid uniqueidentifier
        DECLARE execution_cursor CURSOR LOCAL
            FOR SELECT [execution_id],[dump_id] FROM [catalog].[executions] WHERE [status] = 2
        OPEN execution_cursor
        FETCH NEXT FROM execution_cursor
            INTO @current_execution_id,@current_execution_guid
        WHILE (@@FETCH_STATUS = 0)
        BEGIN
            IF [internal].[check_permission]
            (
              4,
              @execution_id,      
              1
            ) = 1
            BEGIN
                INSERT INTO @ret
                SELECT [execution_id] ,
                       [counter_name] ,
                       [counter_value]
                FROM [internal].[get_execution_perf_counters](@current_execution_id,@current_execution_guid)        
            END
            FETCH NEXT FROM execution_cursor
                INTO @current_execution_id,@current_execution_guid           
        END
        CLOSE execution_cursor
        DEALLOCATE execution_cursor
    END
    ELSE
    BEGIN
        IF [internal].[check_permission]
        (
           4,
           @execution_id,      
           1
        ) = 1
        BEGIN
            DECLARE @execution_guid uniqueidentifier
            SELECT @execution_guid = [dump_id] FROM [catalog].[executions] WHERE [execution_id] = @execution_id AND [status] = 2
            IF (@execution_guid IS NOT NULL)
            BEGIN
                INSERT INTO @ret
                SELECT [execution_id] ,
                       [counter_name] ,
                       [counter_value]
                FROM [internal].[get_execution_perf_counters](@execution_id,@execution_guid)	
            END
        END
    END
    RETURN
END

