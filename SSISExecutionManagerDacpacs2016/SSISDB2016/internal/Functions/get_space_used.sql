
CREATE FUNCTION [internal].[get_space_used]
(
     @objname nvarchar(776)   
)
RETURNS bigint
AS 
BEGIN
    IF @objname IS NULL    
    BEGIN
        RETURN -1
    END
    
    DECLARE  @id int         
    DECLARE @type  character(2) 
    DECLARE @pages bigint          
            
    
    SELECT @id = [object_id], @type = [type] 
    FROM [sys].[objects] 
    WHERE object_id = object_id(@objname)

    
    
    IF (@id IS NULL OR @type  <> 'U')
    BEGIN
        RETURN -1
    END

    SELECT 
        @pages = SUM(in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
    FROM sys.dm_db_partition_stats
    WHERE object_id = @id;

    
    RETURN @pages * 8
    
END
