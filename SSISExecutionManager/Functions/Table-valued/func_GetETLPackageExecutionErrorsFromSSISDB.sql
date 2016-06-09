CREATE FUNCTION [dbo].[func_GetETLPackageExecutionErrorsFromSSISDB] (@ExecutionId BIGINT)
RETURNS TABLE
AS
    RETURN (
      WITH EventMessage
           AS (SELECT
                 o.operation_id                    AS ExecutionId
                 ,e.event_message_id               AS EventMessageId
                 ,e.package_name                   AS PackageName
                 ,e.message                        AS [Message]
                 ,e.message_type                   AS MessageType
                 ,o.status                         AS ETLExecutionStatusId
                 ,CAST(e.message_time AS DATETIME) AS MessageDateTime
               FROM
                 [$(SSISDB)].catalog.event_messages e WITH (NOLOCK)
                 JOIN [$(SSISDB)].catalog.operations o WITH (NOLOCK)
                   ON e.operation_id = o.operation_id
                 JOIN ctl.ETLBatchSSISDBExecutions ebe WITH (NOLOCK)
                   ON e.operation_id = ebe.SSISDBExecutionId
               WHERE
                e.operation_id = @ExecutionId
                AND e.message_type = 120)
      SELECT
         ep.ETLPackageId     AS ETLPackageId
         ,em.EventMessageId  AS EventMessageId
         ,em.MessageDateTime AS ErrorDateTime
         ,em.[Message]       AS ErrorMessage
       FROM
         [ctl].ETLPackage ep WITH (NOLOCK)
         JOIN [$(SSISDB)].catalog.executables e WITH (NOLOCK)
           ON ep.SSISDBPackageName = e.package_name
              AND e.package_path = '\Package'
              AND e.execution_id = @ExecutionId
         JOIN EventMessage em
           ON ep.SSISDBPackageName = em.PackageName) 
