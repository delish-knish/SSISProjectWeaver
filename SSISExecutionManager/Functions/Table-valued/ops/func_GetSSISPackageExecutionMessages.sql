CREATE FUNCTION [ops].[func_GetSSISPackageExecutionMessages] (@MessageType SMALLINT,
                                                              @ExecutionId BIGINT)
RETURNS TABLE
AS
    RETURN
      (SELECT DISTINCT
         om.operation_message_id
         ,o.[object_name]
         ,IIF(@ExecutionId IS NULL, 'N/A', e.package_name) AS package_name
         ,CAST(om.[message_time] AS DATETIME)              AS [message_time]
         ,om.[message]
       FROM
         [$(SSISDB)].catalog.[operation_messages] om
         JOIN [$(SSISDB)].catalog.operations o
           ON om.operation_id = o.operation_id
         JOIN [$(SSISDB)].catalog.executions e
           ON o.process_id = e.process_id
       WHERE
        message_type = @MessageType
        AND ( e.execution_id = @ExecutionId
               OR @ExecutionId IS NULL )) 
