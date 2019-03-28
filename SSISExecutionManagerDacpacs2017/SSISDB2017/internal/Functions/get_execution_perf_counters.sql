CREATE FUNCTION [internal].[get_execution_perf_counters]
(@execution_id BIGINT NULL, @execution_guid UNIQUEIDENTIFIER NULL)
RETURNS 
     TABLE (
        [execution_id]  BIGINT         NULL,
        [counter_name]  NVARCHAR (128) NULL,
        [counter_value] BIGINT         NULL)
AS
 EXTERNAL NAME [ISSERVER].[Microsoft.SqlServer.IntegrationServices.Server.ExecPerfCounterApi].[GetExecPerfCounters]

