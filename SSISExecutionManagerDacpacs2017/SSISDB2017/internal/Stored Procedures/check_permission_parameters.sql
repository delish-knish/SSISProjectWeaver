
CREATE PROCEDURE [internal].[check_permission_parameters]
    @object_type SMALLINT,
    @object_id BIGINT,
    @principal_id INTEGER,
    @permission_type SMALLINT,
    @is_role BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @ret INTEGER
    DECLARE @id_string NVarChar(32)
    
    
    IF (@object_type IS NULL)
      OR (@object_id IS NULL)
      OR (@principal_id IS NULL)
      OR (@permission_type IS NULL)
    BEGIN
        RAISERROR(27138,16,1) WITH NOWAIT
        RETURN 1
    END
    
    IF @object_type NOT IN 
    ( 1,
      2,
      3,
      4
    )
    BEGIN
        RAISERROR(27101,16,1,N'object_type') WITH NOWAIT
        RETURN 1
    END
    
    IF @permission_type NOT IN 
    (
      1,
      2,
      3,
      4,
      100,
      101,
      102,
      103,
      104
    )
    BEGIN
        RAISERROR(27101,16,1,N'permission_type') WITH NOWAIT
        RETURN 1
    END
    
    IF  (     @object_type <> 2 
          AND @permission_type = 3
        )
     OR (    @object_type <> 1
         AND @permission_type >= 100
        )
    BEGIN
        RAISERROR(27191,16,1,@permission_type,@object_type) WITH NOWAIT
        RETURN 1
    END
    
    SET @id_string = CAST(@object_id AS NVARCHAR(32))
    IF @object_type = 1
    BEGIN
        IF NOT EXISTS
        (
            SELECT [folder_id]
            FROM [catalog].[folders]
            WHERE [folder_id] = @object_id
        )
        BEGIN
            RAISERROR(27104,16,1,@id_string) WITH NOWAIT
            RETURN 1
        END
    END
    ELSE IF @object_type = 2
    BEGIN
        IF NOT EXISTS
        (
            SELECT [project_id]
            FROM [catalog].[projects]
            WHERE [project_id] = @object_id
        )
        BEGIN
            RAISERROR(27109,16,1,@id_string) WITH NOWAIT
            RETURN 1
        END
    END
    ELSE IF @object_type = 3
    BEGIN
        IF NOT EXISTS
        (
            SELECT [environment_id]
            FROM [catalog].[environments]
            WHERE [environment_id] = @object_id
        )
        BEGIN
            RAISERROR(27182,16,1,@id_string) WITH NOWAIT
            RETURN 1
        END
    END
    ELSE
    BEGIN
        IF NOT EXISTS
        (
            SELECT [operation_id]
            FROM [catalog].[operations]
            WHERE [operation_id] = @object_id
        )
        BEGIN
            
            RAISERROR(27105,16,1,@object_id) WITH NOWAIT
            RETURN 1
        END
    END
    
    EXEC @ret = [internal].[check_is_role] @principal_id,@is_role OUTPUT
    IF @ret <> 0
    BEGIN
        RAISERROR(27101,16,1,N'principal_id') WITH NOWAIT
        RETURN 1
    END
    
    IF [internal].[check_permission](@object_type,@object_id,4) = 0
    BEGIN
        RAISERROR(27192,16,1) WITH NOWAIT
        RETURN 1
    END
    
    RETURN 0
END
