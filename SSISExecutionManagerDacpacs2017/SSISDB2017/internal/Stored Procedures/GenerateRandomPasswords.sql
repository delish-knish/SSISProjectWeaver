
CREATE PROCEDURE [internal].[GenerateRandomPasswords] (
	@pLength int = 32, 
	@charset varchar(max),
	@password varchar(max) out
)
AS
BEGIN
SET NOCOUNT ON

SET @password = ''
DECLARE @i INT = @pLength
WHILE (@i > 0)
BEGIN
	SET @password = @password + SUBSTRING(@charset, CONVERT(INT, len(@charset)*RAND()) + 1 , 1)
	SET @i -= 1 
END
END
