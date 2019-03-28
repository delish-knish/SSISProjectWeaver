
CREATE VIEW [internal].[current_user_readable_operations]
AS
SELECT     [object_id] AS [ID]
FROM       [catalog].[effective_object_permissions]
WHERE      [object_type] = 4
           AND  [permission_type] = 1
