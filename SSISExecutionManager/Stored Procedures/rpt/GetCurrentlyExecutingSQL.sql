CREATE PROCEDURE [rpt].[GetCurrentlyExecutingSQL]
AS
    SELECT
      r.start_time                                                  [Start Time]
      ,session_id                                                   [SPID]
      ,DB_NAME(database_id)                                         [Database]
      ,SUBSTRING(t.text, ( r.statement_start_offset / 2 ) + 1, CASE
                                                                 WHEN statement_end_offset = -1
                                                                       OR statement_end_offset = 0 THEN ( DATALENGTH(t.text) - r.statement_start_offset / 2 ) + 1
                                                                 ELSE ( r.statement_end_offset - r.statement_start_offset ) / 2 + 1
                                                               END) [Executing SQL]
      ,status
      ,command
      ,wait_type
      ,wait_time
      ,wait_resource
      ,last_wait_type
    FROM
      master.sys.dm_exec_requests r
      OUTER APPLY master.sys.dm_exec_sql_text(sql_handle) t
    WHERE
      session_id <> @@SPID -- don't show this query
      AND session_id > 50 -- don't show system queries
    ORDER  BY
      r.start_time

    RETURN 0 
