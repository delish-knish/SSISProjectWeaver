-- =============================================================
-- Author:		Mike D.
-- Create date: 02/04/11
-- Description:	Returns time in format HHMMSS
-- =============================================================
CREATE FUNCTION [dbo].[func_GetTimeAsInt](@DateTime DATETIME)
RETURNS INT
AS
BEGIN
	DECLARE @Hours   SMALLINT = 0
	DECLARE @Minutes SMALLINT = 0
	DECLARE @Seconds SMALLINT = 0
	DECLARE @Time    VARCHAR(6)
	
	SET @Hours   = DATEPART(hour,   @DateTime)
	SET @Minutes = DATEPART(minute, @DateTime) --+ 1
	SET @Seconds = DATEPART(second, @DateTime)
	
	IF @Seconds >= 60
		BEGIN
			SET @Minutes = @Minutes + (@Seconds - 60)
			SET @Seconds = 00
		END
	
	IF @Minutes >= 60 
		BEGIN
			SET @Hours = @Hours + (@Minutes - 60)
			SET @Minutes = 00
		END
		
	IF @Hours > 24
		SET @Hours = @Hours - 24
	
	SET @Time = RIGHT('00' + CONVERT(VARCHAR(2), @Hours), 2)
	           + RIGHT('00' + CONVERT(VARCHAR(2), @Minutes), 2)
	           + RIGHT('00' + CONVERT(VARCHAR(2), @Seconds), 2)
	
	RETURN RIGHT('000000' + CONVERT(VARCHAR(6), @Time), 6)
END