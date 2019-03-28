
CREATE PROCEDURE [internal].[update_task_status]
	@WorkerAgentId		UNIQUEIDENTIFIER,
	@TaskId				UNIQUEIDENTIFIER,
	@ExpiredTime		DATETIMEOFFSET,
	@Status				INT	OUTPUT

WITH EXECUTE AS 'AllSchemaOwner'
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	
	IF @WorkerAgentId IS NULL
	BEGIN
		RAISERROR(27100, 16, 1, N'@WorkerAgentId')
		RETURN 1
	END
	
	IF @TaskId IS NULL
	BEGIN
		RAISERROR(27100, 16, 1, N'@TaskId')
		RETURN 1
	END
	
	IF @Status IS NULL
	BEGIN
		RAISERROR(27100, 16, 1, N'@Status')
		RETURN 1
	END
	
	DECLARE @IsWorkerAgentEnabled BIT = NULL
	DECLARE @strWorkerAgentId NVARCHAR(50)
	SELECT @IsWorkerAgentEnabled =[IsEnabled] FROM [internal].[worker_agents]
	WHERE [WorkerAgentId]=@WorkerAgentId
	IF @@ROWCOUNT = 0
	BEGIN
		RAISERROR(27243, 16, 1) WITH NOWAIT
		RETURN 1
	END
	ELSE IF @IsWorkerAgentEnabled=0
	BEGIN
		SET @strWorkerAgentId = CONVERT(NVARCHAR(50), @WorkerAgentId)
		RAISERROR(27252, 16, 1, @strWorkerAgentId) WITH NOWAIT
		RETURN 1
	END																					
	
	BEGIN TRAN
	BEGIN TRY
		
		DECLARE @JobId UNIQUEIDENTIFIER = NULL
		DECLARE @RetStatus INT = NULL
			
		UPDATE [internal].[tasks]
		SET @JobId = [JobId],
			[LastUpdatedTime]=SYSDATETIMEOFFSET(),
			[ExpiredTime]=
			CASE 
				WHEN @Status=2 OR @Status=3 THEN @ExpiredTime
				ELSE NULL
			END,
			[Status]=
			CASE 
				WHEN @Status=5 OR @Status=2 OR @Status=3 THEN @Status
				WHEN [IsCancelled]=1 AND @Status > 3 AND @Status != 5 THEN 6
				WHEN [IsCancelled]=0 AND [MaxExecutedCount] > [ExecutedCount] AND @Status > 3 AND @Status != 5 THEN 1
				ELSE @Status
			END,
			@RetStatus=
			CASE 
				WHEN [IsCancelled]=1 AND (@Status=2 OR @Status=3) THEN 6
				WHEN [IsCancelled]=0 AND @Status > 3 AND @Status != 5 AND [MaxExecutedCount] > [ExecutedCount] THEN 1
				ELSE @Status
			END,
			[ReadyForDispatchTime]=
			CASE
				WHEN [IsCancelled]=0 AND @Status > 3 AND @Status != 5 AND [MaxExecutedCount] > [ExecutedCount] THEN SYSDATETIMEOFFSET()
				ELSE NULL
			END
		FROM [internal].[tasks]
		WHERE [TaskId] = @TaskId AND [WorkerAgentId]=@WorkerAgentId AND [Status]<=3 AND [Status] >= 2 AND @Status >= [Status]
		
		COMMIT TRAN
		
		IF @RetStatus IS NULL
		BEGIN
			DECLARE @strTaskId NVARCHAR(50)
			SET @strTaskId = CONVERT(NVARCHAR(50), @TaskId)
			RAISERROR(27246, 16, 1, @strTaskId) WITH NOWAIT
		END
		
		SET @Status=@RetStatus
		RETURN 0
	END TRY
	BEGIN CATCH
		IF XACT_STATE() != 0
			ROLLBACK TRAN;
		THROW
	END CATCH
END
