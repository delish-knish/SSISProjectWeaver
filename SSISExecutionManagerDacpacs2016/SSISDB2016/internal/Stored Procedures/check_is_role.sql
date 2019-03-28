
CREATE PROCEDURE [internal].[check_is_role]
    @principal_id INTEGER,
    @is_role BIT OUTPUT
AS
BEGIN
    DECLARE @principal_type CHAR(1)
        
    SELECT @principal_type = [type] 
    FROM [sys].[database_principals] 
    WHERE [principal_id] = @principal_id

    IF @principal_type IS NULL
        RETURN 1
    
    IF @principal_type = 'R'
        SET @is_role = 1
    ELSE
        SET @is_role = 0
  
    RETURN 0
END
