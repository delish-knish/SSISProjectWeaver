CREATE TYPE [internal].[machine_perf_counter_list_type] AS TABLE (
    [PerfCounterName]  NVARCHAR (MAX)     NOT NULL,
    [PerfCounterValue] FLOAT (53)         NOT NULL,
    [TimeStamp]        DATETIMEOFFSET (7) NOT NULL);

