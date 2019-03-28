
CREATE VIEW [catalog].[execution_component_phases]
AS
SELECT   startPhase.[phase_stats_id] as [phase_stats_id],
         startPhase.[execution_id] as [execution_id],
         startPhase.[package_name] as [package_name],
         startPhase.[task_name] as [task_name],
         startPhase.[subcomponent_name] as [subcomponent_name],
         startPhase.[phase] as [phase],
         startPhase.[phase_time] as [start_time],
         endPhase.[phase_time] as [end_time],
         startPhase.[execution_path] as [execution_path]
FROM     [internal].[execution_component_phases] startPhase LEFT JOIN [internal].[execution_component_phases] endPhase
         ON startPhase.[phase_stats_id] != endPhase.[phase_stats_id]
         AND startPhase.[execution_id] = endPhase.[execution_id]
         AND startPhase.[sequence_id] = endPhase.[sequence_id]
WHERE    startPhase.[is_start] = 'True' AND (endPhase.[is_start] = 'False' OR endPhase.[is_start] is null)
         AND (startPhase.[execution_id] in (SELECT [id] FROM [internal].[current_user_readable_operations])
         OR (IS_MEMBER('ssis_admin') = 1)
         OR (IS_SRVROLEMEMBER('sysadmin') = 1))
         OR (IS_MEMBER('ssis_logreader') = 1)

