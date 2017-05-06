CREATE FUNCTION [dbo].[func_IsETLPackageRunning] (@FolderName  VARCHAR(128),
                                                  @ProjectName VARCHAR(128),
                                                  @PackageName VARCHAR(260))
RETURNS BIT
AS
  BEGIN
      DECLARE @ReturnVal BIT;

      SELECT
        @ReturnVal = IIF(SUM([execution_id]) > 0, 1, 0) 
      FROM
        [$(SSISDB)].[catalog].[executions]
      WHERE
        [status] = 2
        AND [folder_name] = @FolderName
        AND [project_name] = @ProjectName
        AND [package_name] = @PackageName

      RETURN @ReturnVal
  END 
