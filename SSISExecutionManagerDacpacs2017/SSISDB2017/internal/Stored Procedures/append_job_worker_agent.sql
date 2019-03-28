
CREATE PROCEDURE [internal].[append_job_worker_agent]
	@JobId     			UNIQUEIDENTIFIER,
	@WorkerAgentId		UNIQUEIDENTIFIER

WITH EXECUTE AS 'AllSchemaOwner'
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @GUID_All_Worker_Agents UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111'
		
	
	IF @JobId IS NULL
	BEGIN
		RAISERROR(27100, 16, 1, N'@JobId')
		RETURN 1
	END
	
	IF @WorkerAgentId IS NULL
	BEGIN
		RAISERROR(27100, 16, 1, N'@WorkerAgentId')
		RETURN 1
	END
	
	IF @WorkerAgentId = '11111111-1111-1111-1111-111111111111'
	BEGIN
		RAISERROR(27101, 16, 1, '11111111-1111-1111-1111-111111111111') WITH NOWAIT
		RETURN 1
	END
	
	IF EXISTS (SELECT [WorkerAgentId] FROM [internal].[job_worker_agents] WHERE [JobId]=@JobId AND [WorkerAgentId]=@GUID_All_Worker_Agents)
	BEGIN
		DECLARE @strJobId NVARCHAR(50)
		SET @strJobId = CONVERT(NVARCHAR(50), @JobId)
		RAISERROR(27251, 16, 1, @strJobId) WITH NOWAIT
		RETURN 1
	END
	
	BEGIN TRY
		INSERT INTO [internal].[job_worker_agents]([WorkerAgentId], [JobId]) 
		SELECT @WorkerAgentId, @JobId FROM [internal].[worker_agents] WHERE [WorkerAgentId]=@WorkerAgentId
	
		
		IF @@ROWCOUNT = 0
		BEGIN
			DECLARE @strWorkerAgentId NVARCHAR(50)
			SET @strWorkerAgentId = CONVERT(NVARCHAR(50), @WorkerAgentId)
			RAISERROR(27243, 16, 1, @strWorkerAgentId)
		END
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
	
	RETURN 0
END
	
