CREATE FUNCTION [dbo].[func_GetLastPackageExecutionStatus] (@SSISDBPackageName VARCHAR (260)
															)
RETURNS VARCHAR(50)
AS
  BEGIN
      DECLARE @ReturnValue VARCHAR(50) = (SELECT
           PackageExecutionStatus
         FROM
           rpt.ETLPackagesForLatestBatch
         WHERE
          SSISDBPackageName = @SSISDBPackageName
		  )

      RETURN @ReturnValue
  END 
