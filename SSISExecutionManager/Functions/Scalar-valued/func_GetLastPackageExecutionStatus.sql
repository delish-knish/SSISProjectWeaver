CREATE FUNCTION [dbo].[func_GetLastPackageExecutionStatus] (@ETLBatchExecutionId INT,
                                                            @ETLPackageId        INT)
RETURNS INT
AS
  BEGIN
      DECLARE @ReturnValue        INT
              ,@SSISDBExecutionId BIGINT

      SELECT TOP 1
        @SSISDBExecutionId = [SSISDBExecutionId]
      FROM
        [ctl].[ETLBatchSSISDBExecutions] WITH (NOLOCK)
      WHERE
        [ETLBatchExecutionId] = @ETLBatchExecutionId
        AND ETLPackageId = @ETLPackageId
      ORDER  BY
        CreatedDate DESC

      SET @ReturnValue = (SELECT
                            ETLPackageExecutionStatusId
                          FROM
                            [dbo].[func_GetETLPackageExecutionStatusesFromSSISDB] (@SSISDBExecutionId)
                          WHERE
                           ETLPackageId = @ETLPackageId)

      RETURN @ReturnValue
  END 
