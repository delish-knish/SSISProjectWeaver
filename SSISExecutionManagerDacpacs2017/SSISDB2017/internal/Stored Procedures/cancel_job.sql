
CREATE PROCEDURE [internal].[cancel_job]
	@JobId     UNIQUEIDENTIFIER

WITH EXECUTE AS 'AllSchemaOwner'
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	
	IF @JobId IS NULL
	BEGIN
		RAISERROR(27100, 16, 1, N'@JobId')
		RETURN 1
	END
	
	BEGIN TRAN
	BEGIN TRY
		DECLARE @IsJobExist BIT = 0
		
		UPDATE [internal].[tasks] SET 
			[Status]=
				CASE 
					WHEN [Status] = 2 OR [Status] = 3 OR [Status]=5 THEN [Status]
					ELSE 6
				END,
			[ReadyForDispatchTime] = NULL,
			[LastUpdatedTime]=SYSDATETIMEOFFSET(),
			[IsCancelled] = 1
		WHERE [JobId] = @JobId 
	
		UPDATE [internal].[jobs] SET [LastUpdatedTime]=SYSDATETIMEOFFSET(), [IsCancelled] = 1, @IsJobExist = 1 WHERE [JobId] = @JobId
		
		IF @IsJobExist = 0
			BEGIN
				DECLARE @strJobId NVARCHAR(50)
				SET @strJobId = CONVERT(NVARCHAR(50), @JobId)
				RAISERROR(27242, 16, 1, @strJobId) WITH NOWAIT
			END
			
		COMMIT TRAN	
    RETURN 0
	END TRY
	BEGIN CATCH
		IF XACT_STATE() != 0
			ROLLBACK TRAN;
		THROW
	END CATCH
END
