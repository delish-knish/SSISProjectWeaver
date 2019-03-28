
CREATE VIEW [catalog].[effective_object_permissions]
AS

SELECT     [object_type],
           [object_id],
           [permission_type]
FROM       [internal].[current_user_object_permissions]
WHERE      [is_deny] = 0

UNION ALL

SELECT     op.[object_type],
           op.[object_id],
           CAST((op2.[permission_type] - 100) AS SmallInt) AS [permission_type]
FROM       [internal].[object_permissions] op INNER JOIN [internal].[object_folders] ofs
           ON op.[object_type] = ofs.[object_type] AND op.[object_id] = ofs.[object_id]
           INNER JOIN [internal].[current_user_object_permissions] op2 
           ON ofs.[folder_id] = op2.[object_id] AND op2.[object_type] = 1
WHERE      op2.[is_deny] = 0
           AND op2.[permission_type] > 100
           
           
           AND (     (op.[object_type] <> 3) 
                 OR (op2.[permission_type] <> 103)
               )

EXCEPT

SELECT     [object_type],
           [object_id],
           [permission_type]
FROM       [internal].[current_user_object_permissions]
WHERE      [is_deny] = 1

EXCEPT

SELECT     op.[object_type],
           op.[object_id],
           CAST((op2.[permission_type] - 100) AS SmallInt) AS [permission_type]
FROM       [internal].[object_permissions] op INNER JOIN [internal].[object_folders] ofs
           ON op.[object_type]=ofs.[object_type] and op.[object_id] = ofs.[object_id]
           INNER JOIN [internal].[current_user_object_permissions] op2 
           ON ofs.[folder_id] = op2.[object_id] AND op2.[object_type] = 1
WHERE      op2.[is_deny] = 1
           AND op2.[permission_type] > 100

