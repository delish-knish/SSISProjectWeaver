
CREATE PROCEDURE [internal].[create_task]
  @TaskId					UNIQUEIDENTIFIER	OUTPUT,
  @JobId					UNIQUEIDENTIFIER,
  @TaskType					INT,
  @MaxExecutedCount 		INT = 1, 
  @InputData				NVARCHAR(MAX) = NULL,
  @CreateWorkerAgentId		UNIQUEIDENTIFIER = NULL

WITH EXECUTE AS 'AllSchemaOwner'
AS
BEGIN
	SET NOCOUNT ON
	
	
	IF @JobId IS NULL
	BEGIN
		RAISERROR(27100, 16, 1, N'@JobId')
		RETURN 1
	END
	
	IF @TaskType IS NULL
	BEGIN
		RAISERROR(27100, 16, 1, N'@TaskType')
		RETURN 1
	END
		
	IF @CreateWorkerAgentId IS NOT NULL
	BEGIN
		
	DECLARE @IsWorkerAgentEnabled BIT = NULL
	DECLARE @strWorkerAgentId NVARCHAR(50)
	SELECT @IsWorkerAgentEnabled =[IsEnabled] FROM [internal].[worker_agents]
	WHERE [WorkerAgentId]=@CreateWorkerAgentId
	IF @@ROWCOUNT = 0
	BEGIN
		RAISERROR(27243, 16, 1) WITH NOWAIT
		RETURN 1
	END
	ELSE IF @IsWorkerAgentEnabled=0
	BEGIN
		SET @strWorkerAgentId = CONVERT(NVARCHAR(50), @CreateWorkerAgentId)
		RAISERROR(27252, 16, 1, @strWorkerAgentId) WITH NOWAIT
		RETURN 1
	END																					
	END
	
	SET @TaskId = NEWID()
	INSERT [internal].[tasks] ([TaskId], [JobId], [TaskType], [MaxExecutedCount], [InputData], [ReadyForDispatchTime], [Status], [CreatedTime], [LastUpdatedTime], [CreateWorkerAgentId])
	SELECT @TaskId, @JobId, @TaskType, @MaxExecutedCount, @InputData, SYSDATETIMEOFFSET(), 1, SYSDATETIMEOFFSET(), SYSDATETIMEOFFSET(), @CreateWorkerAgentId 
	FROM [internal].[jobs] WHERE [JobId]=@JobId AND [IsCancelled]=0
	
	IF @@ROWCOUNT = 0
	BEGIN
		DECLARE @strJobId NVARCHAR(50)
		SET @strJobId = CONVERT(NVARCHAR(50), @JobId)
		RAISERROR(27242, 16, 1, @strJobId) WITH NOWAIT
		RETURN 1
	END
	RETURN 0
END
