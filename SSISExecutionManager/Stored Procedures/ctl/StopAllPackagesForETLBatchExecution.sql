CREATE PROCEDURE [ctl].[StopAllPackagesForETLBatchExecution] @ETLBatchExecutionId INT
AS
    DECLARE @SSISDBExecutionId  BIGINT
            ,@SSISDBProjectName NVARCHAR (128)
            ,@ETLPackageId      INT
            ,@SSISDBPackageName NVARCHAR(260)
            ,@EventDescription  VARCHAR(MAX)
            --,@EmailRecipients   VARCHAR(MAX)
            --,@CRLF              NVARCHAR(MAX) = CHAR(13) + CHAR(10)
            --,@MailBody          NVARCHAR(MAX)
            --,@ServerName        NVARCHAR(MAX) = @@SERVERNAME;
    DECLARE PackageCursor CURSOR FAST_FORWARD FOR
      SELECT
        execution_id      AS SSISDBExecutionId
        ,project_name     AS SSISDBProjectName
        ,package_name     AS SSISDBPackageName
        ,exm.ETLPackageId AS ETLPackageId
      FROM
        [$(SSISDB)].[catalog].executions ex
        JOIN ctl.ETLBatchSSISDBExecutions exm
          ON ex.execution_id = exm.SSISDBExecutionId
      WHERE
        [status] = 2
        AND exm.ETLBatchExecutionId = @ETLBatchExecutionId

    OPEN PackageCursor

    FETCH NEXT FROM PackageCursor INTO @SSISDBExecutionId, @SSISDBProjectName, @SSISDBPackageName, @ETLPackageId

    WHILE @@FETCH_STATUS = 0
      BEGIN
          DECLARE @SQLStopPackageExecution NVARCHAR(MAX) = 'EXEC SSISDB.catalog.stop_operation @operation_id = '
            + CAST(@SSISDBExecutionId AS NVARCHAR(20));

          EXECUTE sp_executesql
            @SQLStopPackageExecution

          SET @EventDescription = 'Stopping SSISDB package execution Id '
                                  + CAST(@SSISDBExecutionId AS VARCHAR(20))
                                  + '[' + @SSISDBProjectName + '].['
                                  + @SSISDBPackageName + ']';

          EXEC [log].[InsertETLBatchExecutionEvent]
            21,
            @ETLBatchExecutionId,
            @ETLPackageId,
            @EventDescription;

          FETCH NEXT FROM PackageCursor INTO @SSISDBExecutionId, @SSISDBProjectName, @SSISDBPackageName, @ETLPackageId
      END

    CLOSE PackageCursor

    DEALLOCATE PackageCursor

    RETURN 0 
