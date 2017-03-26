CREATE FUNCTION [dbo].[func_GetETLPackageExecutionStatusesFromSSISDB] (@ExecutionId BIGINT)
RETURNS TABLE
AS
    RETURN (
      
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
         --,emf.Message                                                   AS ETLPackageLastMessage
         --,eme.Message                                                   AS ETLPackageFirstErrorMessage
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
         JOIN (select * from (SELECT
                 em.package_name                   AS PackageName
                 ,em.message_time					AS MessageDateTime
				 ,ROW_NUMBER() OVER (PARTITION BY em.package_name ORDER BY em.message_time) rownum
               FROM
                 [$(SSISDB)].catalog.event_messages em (NOLOCK)
               WHERE
                em.operation_id = @ExecutionId) t
				where rownum = 1) ems ON ep.SSISDBPackageName = ems.PackageName --first message for the package
		LEFT JOIN (select * from (SELECT
                 em.package_name                   AS PackageName
                 ,em.message_time					AS MessageDateTime
				 ,em.message
				 ,ROW_NUMBER() OVER (PARTITION BY em.package_name ORDER BY em.message_time ) rownum
               FROM
                 [$(SSISDB)].catalog.event_messages em (NOLOCK)
               WHERE
                em.operation_id = @ExecutionId
				AND em.message_type = 120 --Error
				) t
				where rownum = 1) eme ON ep.SSISDBPackageName = eme.PackageName --frist error message for the package
      ) 
