
CREATE PROCEDURE [catalog].[stop_operation]
    @operation_id bigint                                
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @operation_guid uniqueIdentifier   
    DECLARE @process_id bigint
    DECLARE @return_value int
    DECLARE @stop_id bigint
    DECLARE @status int
    
    IF @operation_id IS NULL 
    BEGIN
       RAISERROR(27100, 16 , 11, 'operation_id') WITH NOWAIT
       RETURN 1
    END
    
    EXEC @return_value = [internal].[prepare_stop] 
                            @operation_id,
                            @process_id output, 
                            @operation_guid output,
                            @stop_id output

	DECLARE @job_id uniqueIdentifier = NULL
	
    IF @return_value = 0
    BEGIN
		DECLARE @operation_type int
		SELECT @operation_type = [operation_type] FROM [catalog].[operations] WHERE [operation_id] = @operation_id
		IF @operation_type = 200
		BEGIN
		SELECT @job_id = [job_id] FROM [internal].[executions] WHERE [execution_id]=@operation_id
		END
		ELSE IF (@operation_type = 300 OR @operation_type = 301)
		BEGIN
		SELECT @job_id = [job_id] FROM [internal].[validations] WHERE [validation_id]=@operation_id
		END
        BEGIN TRY
			
			IF (0 = 0 AND @job_id IS NULL)
			BEGIN
				EXEC @return_value=[internal].[stop_operation_internal] 
                    @operation_id, 
                    @process_id,
                    @operation_guid
				SET @status =
				CASE
					WHEN (@return_value = 0) THEN 7
					ELSE 4
				END

				UPDATE [internal].[operations] SET 
					[end_time]  = SYSDATETIMEOFFSET(),
					[status]    = @status
					WHERE operation_id    = @stop_id
			END
			
			ELSE
			BEGIN
				EXEC @return_value=[internal].[cancel_job] @job_id
				IF (@return_value = 0) 
				BEGIN
					DECLARE @input_data nvarchar(max)
					SET @input_data = (SELECT [InputData] FROM [internal].[tasks] WHERE [JobId] = @job_id)
					SET @input_data = JSON_MODIFY(@input_data, 'append $', 
						JSON_QUERY((SELECT 'stop_id' AS name, CONVERT(nvarchar(256), @stop_id) AS value For JSON PATH, WITHOUT_ARRAY_WRAPPER)))			
					UPDATE [internal].[tasks] SET [InputData] =  @input_data WHERE [JobId] = @job_id
				END
			END
        END TRY
        BEGIN CATCH         
            UPDATE [internal].[operations] SET 
                [end_time]  = SYSDATETIMEOFFSET(),
                [status]    = 4
                WHERE operation_id    = @stop_id;
            THROW;
        END CATCH
    END
        
    RETURN @return_value       
END
