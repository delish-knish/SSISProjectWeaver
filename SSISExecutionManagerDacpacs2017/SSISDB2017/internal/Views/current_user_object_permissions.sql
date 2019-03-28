
CREATE VIEW [internal].[current_user_object_permissions]
AS
SELECT     obj.[object_type],
           obj.[object_id],
           obj.[permission_type], 
           obj.[sid],
           obj.[is_role],
           obj.[is_deny]
FROM       [internal].[object_permissions] AS obj INNER JOIN [sys].[database_principals] AS pri
ON obj.[sid] = pri.[sid]
WHERE     
((pri.[type] = 'S' OR pri.[type] = 'U') AND obj.[sid] = USER_SID (DATABASE_PRINCIPAL_ID()))
OR
((pri.[type] = 'G' OR pri.[type] = 'R') AND IS_MEMBER(pri.name)=1)
	
