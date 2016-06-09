CREATE FUNCTION [dbo].[func_GetETLPackageExecutionStatusesFromSSISDB] (@ExecutionId BIGINT)
RETURNS TABLE
AS
    RETURN (
      WITH EventMessage
           AS (SELECT
                 om.operation_id                    AS ExecutionId
                 ,em.package_name                   AS PackageName
                 ,om.message                        AS [Message]
                 ,om.message_type                   AS MessageType
                 ,o.status                          AS ETLExecutionStatusId
                 ,om.message_time					AS MessageDateTime
               FROM
                 [$(SSISDB)].internal.event_messages em (NOLOCK)
                 JOIN [$(SSISDB)].internal.operation_messages om (NOLOCK)
                   ON em.operation_id = om.operation_id
                 JOIN [$(SSISDB)].catalog.operations o (NOLOCK)
                   ON em.operation_id = o.operation_id
               WHERE
                em.operation_id = @ExecutionId)
      SELECT
         ep.ETLPackageId                                                AS ETLPackageId
         ,@ExecutionId                                                  AS SSISDBExecutionId
         ,o.status                                                      AS ETLExecutionStatusId
         ,CONVERT(DATETIME, ISNULL(es.start_time, ems.MessageDateTime)) AS StartDateTime --If the package hasn't completed, get the date from the messages. Data isn't written to catalog.executables until it has finished executing.
         ,CONVERT(DATETIME, ISNULL(es.end_time, ex.end_time))           AS EndDateTime
         ,CASE
            WHEN ems.MessageDateTime IS NOT NULL
                 AND es.execution_result IS NULL
                 AND eme.MessageDateTime IS NULL THEN IIF(ex.status = 7, 7, 5) --The package has started but hasn't completed or failed, so it is running
            WHEN ems.MessageDateTime IS NOT NULL
                 AND es.execution_result IS NULL
                 AND eme.MessageDateTime IS NOT NULL THEN 1 --The package started and there is no result but there is an error message (most likely validation error)
            ELSE es.execution_result
          END                                                           AS ETLPackageExecutionStatusId
         ,emf.Message                                                   AS ETLPackageLastMessage
         ,eme.Message                                                   AS ETLPackageFirstErrorMessage
         ,CAST(IIF(es.execution_result IS NULL, 1, 0) AS BIT)           AS MissingSSISDBExecutablesEntryInd
       FROM
         [ctl].ETLPackage ep WITH (NOLOCK)
         LEFT JOIN [$(SSISDB)].catalog.executables e WITH (NOLOCK)
                ON ep.SSISDBPackageName = e.package_name
                   AND e.package_path = '\Package'
                   AND e.execution_id = @ExecutionId
         LEFT JOIN [$(SSISDB)].catalog.executions ex WITH (NOLOCK)
                ON ex.execution_id = @ExecutionId
         LEFT JOIN [$(SSISDB)].catalog.operations o WITH (NOLOCK)
                ON e.execution_id = o.operation_id
         LEFT JOIN [$(SSISDB)].catalog.executable_statistics es WITH (NOLOCK)
                ON e.executable_id = es.executable_id
                   AND e.execution_id = es.execution_id
         CROSS APPLY (SELECT TOP 1
                        MessageDateTime
                      FROM
                        EventMessage em
                      WHERE
                       ep.SSISDBPackageName = em.PackageName
                      ORDER  BY
                       em.MessageDateTime ASC) ems --first message for the package
         CROSS APPLY (SELECT TOP 1
                        MessageDateTime
                        ,[Message]
                      FROM
                        EventMessage em
                      WHERE
                       ep.SSISDBPackageName = em.PackageName
                      ORDER  BY
                       em.MessageDateTime DESC) emf --last message for the package
         OUTER APPLY (SELECT TOP 1
                        MessageDateTime
                        ,[Message]
                      FROM
                        EventMessage em
                      WHERE
                       ep.SSISDBPackageName = em.PackageName
                       AND em.MessageType = 120 --Error
                      ORDER  BY
                       em.MessageDateTime ASC) eme --first error message for the package
      ) 
