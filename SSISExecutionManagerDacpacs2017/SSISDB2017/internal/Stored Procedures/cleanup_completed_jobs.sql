
CREATE PROCEDURE [internal].[cleanup_completed_jobs]
	@minutesToKeep    INT = 60                                
WITH EXECUTE AS 'AllSchemaOwner'
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON	
	DECLARE @JobRowsAffected BIGINT
	DECLARE @DeleteBatchSize BIGINT
    DECLARE @DeleteTimeBar DATETIMEOFFSET
	DECLARE @JobIdSet TABLE([JobId] UNIQUEIDENTIFIER)
	SET @DeleteBatchSize = 1000
	SET @JobRowsAffected = @DeleteBatchSize
	
    IF (@minutesToKeep is null or @minutesToKeep < 0)
        SET @minutesToKeep = 60

    SET @DeleteTimeBar = DATEADD(MINUTE, -@minutesToKeep, SYSDATETIMEOFFSET())
	
	WHILE (@JobRowsAffected = @DeleteBatchSize)
	BEGIN
		BEGIN TRAN
		BEGIN TRY
			DELETE FROM @JobIdSet
				
			
			INSERT INTO @JobIdSet			
			SELECT TOP (@DeleteBatchSize) [JobId] FROM [internal].[tasks] GROUP BY [JobId]
			HAVING COUNT(*) > 0 AND COUNT(CASE WHEN [Status] <= 3 or [LastUpdatedTime] > @DeleteTimeBar THEN [Status] END) = 0
	
			
			INSERT INTO [internal].[jobs_History] 
			SELECT * FROM [internal].[jobs] WHERE [JobId] IN (SELECT * from @JobIdSet)
			
			
			INSERT INTO [internal].[tasks_history] 
			SELECT * FROM [internal].[tasks] WHERE [JobId] IN (SELECT * from @JobIdSet)
			
			
			INSERT INTO [internal].[job_worker_agents_history]
			SELECT * FROM [internal].[job_worker_agents] WHERE [JobId] IN (SELECT * from @JobIdSet)
			
			DELETE FROM [internal].[jobs] WHERE [JobId] IN (SELECT * from @JobIdSet)
			
			SELECT @JobRowsAffected = Count(*) FROM @JobIdSet
				
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			IF XACT_STATE() != 0
				ROLLBACK TRAN;
			THROW
		END CATCH
	END
	RETURN 0
END
