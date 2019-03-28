
CREATE VIEW [internal].[object_folders]
AS
SELECT     2 AS [object_type],
           p.[project_id] AS [object_id], 
           p.[name] AS [object_name], 
           p.[folder_id], 
           f.[name] AS [folder_name]
FROM       [internal].[projects] p INNER JOIN [internal].[folders] f ON p.[folder_id] = f.[folder_id] 
Union ALL
SELECT     3 AS [object_type], 
           e.[environment_id] AS [object_id], 
           e.[environment_name] AS [object_name], 
           e.[folder_id], 
           f.[name] AS [folder_name]
FROM       [internal].[environments] e INNER JOIN [internal].[folders] f ON e.[folder_id] = f.[folder_id]
