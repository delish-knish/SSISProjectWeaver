
CREATE PROCEDURE [internal].[pull_task]
	@WorkerAgentId 		UNIQUEIDENTIFIER

WITH EXECUTE AS 'AllSchemaOwner'
AS
BEGIN
	SET XACT_ABORT ON
    SET NOCOUNT ON
	
	
	IF @WorkerAgentId IS NULL
	BEGIN
		RAISERROR(27100, 16, 1, N'@WorkerAgentId')
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

    DECLARE @TaskId UNIQUEIDENTIFIER, 
			@JobId UNIQUEIDENTIFIER, 
			@TaskType INT, 
			@MaxExecutedCount INT, 
			@ExecutedCount INT, 
			@InputData NVARCHAR(max),
			@Status INT, 
			@ReadyForDispatchTime DATETIMEOFFSET, 
			@LastUpdatedTime DATETIMEOFFSET, 
			@Priority INT, 
			@IsCritical BIT, 
			@ExpiredTime DATETIMEOFFSET,
			@CreatedTime DATETIMEOFFSET,
			@CreateWorkerAgentId UNIQUEIDENTIFIER
			
	DECLARE @GUID_All_Worker_Agents	UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111'
	
    BEGIN TRAN
	BEGIN TRY
		SELECT TOP 1
			@TaskId=t.[TaskId], 
			@JobId=t.[JobId], 
			@TaskType=t.[TaskType], 
			@MaxExecutedCount=t.[MaxExecutedCount],
			@ExecutedCount=t.[ExecutedCount], 
			@InputData=t.[InputData],
			@Status=t.[Status],
			@ReadyForDispatchTime = t.[ReadyForDispatchTime],
			@LastUpdatedTime=t.[LastUpdatedTime],
			@Priority=t.[Priority],
			@IsCritical=t.[IsCritical],
			@ExpiredTime=t.[ExpiredTime],
			@CreatedTime=t.[CreatedTime],
			@CreateWorkerAgentId = t.[CreateWorkerAgentId]
		FROM [internal].[tasks] t WITH (UPDLOCK, READPAST) 
		WHERE [ReadyForDispatchTime] IS NOT NULL 
		AND [JobId] IN (SELECT [JobId] FROM [internal].[job_worker_agents] WHERE [WorkerAgentId]=@GUID_All_Worker_Agents 
						UNION ALL
						SELECT [JobId] FROM [internal].[job_worker_agents] WHERE [WorkerAgentId]=@WorkerAgentId)
		ORDER BY [ReadyForDispatchTime]
			
	
		IF @TaskId IS NOT NULL
		BEGIN
			
			
			SET @LastUpdatedTime = SYSDATETIMEOFFSET()
			SET @ReadyForDispatchTime = NULL
			SET @Status = 2
			SET @ExecutedCount = @ExecutedCount + 1
			SET @ExpiredTime = DATEADD(MINUTE, 5, SYSDATETIMEOFFSET())
			UPDATE [internal].[tasks]
			SET [ExecutedCount] = @ExecutedCount, [LastUpdatedTime] = @LastUpdatedTime, [WorkerAgentId] = @WorkerAgentId, [ReadyForDispatchTime]=@ReadyForDispatchTime, [Status]=@Status, [ExpiredTime]=@ExpiredTime,
				[LastPickupTime] = SYSDATETIMEOFFSET()
			WHERE [TaskId] = @TaskId

			SELECT 
				@TaskId as [TaskId], 
				@JobId as [JobId], 
				@TaskType as [TaskType], 
				@MaxExecutedCount as [MaxExecutedCount],
				@ExecutedCount as [ExecutedCount],
				@InputData as [InputData], 
				@Status as [Status], 
				@ReadyForDispatchTime as [ReadyForDispatchTime],
				@LastUpdatedTime as [LastUpdatedTime], 
				@Priority as [Priority],
				@IsCritical as [IsCritical],
				@ExpiredTime as [ExpiredTime],
				@CreatedTime as [CreatedTime],
				@WorkerAgentId as [WorkerAgentId],
				@CreateWorkerAgentId as [CreateWorkerAgentId]
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
