CREATE FUNCTION [dbo].[func_GetConfigurationValue] (@ConfigurationName VARCHAR(250))
RETURNS VARCHAR(MAX)
AS
  BEGIN
      DECLARE @ReturnValue VARCHAR(MAX) = (SELECT
           ConfigurationValue
         FROM
           cfg.Configuration
         WHERE
          ConfigurationName = @ConfigurationName);

      RETURN @ReturnValue;
  END 
