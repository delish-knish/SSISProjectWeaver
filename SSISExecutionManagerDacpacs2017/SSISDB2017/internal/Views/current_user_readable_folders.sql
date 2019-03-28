
CREATE VIEW [internal].[current_user_readable_folders]
AS
SELECT     [object_id] AS [ID]
FROM       [catalog].[effective_object_permissions]
WHERE      [object_type] = 1
           AND  [permission_type] = 1
