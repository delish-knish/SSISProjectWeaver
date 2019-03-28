
CREATE PROCEDURE [internal].[create_execution_job]
		@execution_id bigint,		 
		@caller_name  nvarchar(256), 
		@retry_count  int	     
WITH EXECUTE AS 'AllSchemaOwner'
AS
	SET NOCOUNT ON

	DECLARE @return_value bit
	DECLARE @input_data nvarchar(max)
	DECLARE	@job_id uniqueidentifier 
	DECLARE	@task_id uniqueidentifier 
	DECLARE @max_executed_count int 
	DECLARE @use32bitruntime bit
	
	SELECT @use32bitruntime = [use32bitruntime], @job_id = [job_id] 
	FROM [internal].[executions] WHERE [execution_id]=@execution_id
	
	

	CREATE TABLE #inputs (name nvarchar(20), value nvarchar(256))
	INSERT INTO #inputs values ('execution_id', CONVERT(nvarchar(256), @execution_id))
	INSERT INTO #inputs values ('use32bitruntime', CONVERT(nvarchar(256), @use32bitruntime))
	
	SET @input_data = (select name, value FROM #inputs For JSON PATH)

	IF @job_id IS NULL
	BEGIN
		RAISERROR(27255, 16, 1) WITH NOWAIT
		RETURN 1
	END
	
	SET @max_executed_count = @retry_count + 1
	EXEC @return_value = [internal].[create_task]
			@task_id out,
			@job_id,
			0,
			@max_executed_count,
			@input_data,
			null

	if(@return_value <> 0)
	BEGIN
		RAISERROR(27245, 16, 1) WITH NOWAIT
		RETURN 1
	END
		
