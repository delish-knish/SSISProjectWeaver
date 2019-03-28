
CREATE VIEW [internal].[execution_info]
AS
SELECT     execs.[execution_id], 
           execs.[folder_name], 
           execs.[project_name], 
           execs.[package_name],
           execs.[reference_id],
           execs.[reference_type], 
           execs.[environment_folder_name], 
           execs.[environment_name], 
           execs.[project_lsn], 
           execs.[executed_as_sid], 
           execs.[executed_as_name], 
           execs.[use32bitruntime],  
           opers.[operation_type], 
           opers.[created_time],  
           opers.[object_type], 
           opers.[object_id],
           opers.[status], 
           opers.[start_time], 
           opers.[end_time],  
           opers.[caller_sid], 
           opers.[caller_name], 
           opers.[process_id], 
           opers.[stopped_by_sid], 
           opers.[stopped_by_name],
           opers.[operation_guid] as [dump_id],
           opers.[server_name],
           opers.[machine_name]
FROM       [internal].[executions] execs INNER JOIN [internal].[operations] opers 
           ON execs.[execution_id]= opers.[operation_id]
WHERE      opers.[operation_id] in (SELECT id FROM [internal].[current_user_readable_operations])
           OR (IS_MEMBER('ssis_admin') = 1)
           OR (IS_SRVROLEMEMBER('sysadmin') = 1)

