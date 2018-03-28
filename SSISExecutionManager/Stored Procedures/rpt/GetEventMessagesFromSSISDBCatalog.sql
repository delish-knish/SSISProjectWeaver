CREATE PROCEDURE [rpt].[GetEventMessagesFromSSISDBCatalog] @SSISDBExecutionId BIGINT
AS
    SELECT
      *
    FROM
      [$(SSISDB)].catalog.event_messages
    WHERE
      operation_id = @SSISDBExecutionId
    ORDER  BY
      message_time DESC

    RETURN 0 
