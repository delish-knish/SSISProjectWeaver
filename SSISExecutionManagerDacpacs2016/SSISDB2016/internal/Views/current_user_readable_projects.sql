
CREATE VIEW [internal].[current_user_readable_projects]
AS
SELECT     [object_id] AS [ID]
FROM       [catalog].[effective_object_permissions]
WHERE      [object_type] = 2
           AND  [permission_type] = 1
