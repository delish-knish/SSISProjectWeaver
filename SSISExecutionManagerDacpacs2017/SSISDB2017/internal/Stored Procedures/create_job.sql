
CREATE PROCEDURE [internal].[create_job]
	@JobId     				UNIQUEIDENTIFIER OUTPUT,
	@JobType 				INT,
	@InputData				NVARCHAR(MAX) = NULL,
	@Creator				NVARCHAR(256),
	@UseAllWorkerAgents		BIT = 0

WITH EXECUTE AS 'AllSchemaOwner'
AS
BEGIN
	SET XACT_ABORT ON
	SET NOCOUNT ON
	
	
	IF @JobType IS NULL
	BEGIN
		RAISERROR(27100, 16, 1, N'@JobType')
		RETURN 1
	END
	
	IF @Creator IS NULL
	BEGIN
		RAISERROR(27100, 16, 1, N'@Creator')
		RETURN 1
	END
	IF LEN(@Creator) = 0
	BEGIN
		RAISERROR(27102, 16, 1, N'@Creator')
		RETURN 1
	END	
		
	DECLARE @GUID_All_Worker_Agents UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111'
	SET @JobId =  NEWID()
	
	BEGIN TRAN
	BEGIN TRY
		INSERT [internal].[jobs]([JobId], [JobType], [InputData], [Creator])
		VALUES (@JobId, @JobType, @InputData, @Creator)
			
		IF @UseAllWorkerAgents = 1
			INSERT INTO [internal].[job_worker_agents]([WorkerAgentId], [JobId]) VALUES (@GUID_All_Worker_Agents, @JobId)	
		
		COMMIT TRAN
		RETURN 0
	END TRY
	BEGIN CATCH
		IF XACT_STATE() != 0
			ROLLBACK TRAN;
		THROW
	END CATCH
END
