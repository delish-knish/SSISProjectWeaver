
CREATE PROCEDURE [internal].[update_worker_agent_status]
    @WorkerAgentId			UNIQUEIDENTIFIER,
	@PerfCounterList 		[internal].[machine_perf_counter_list_type]	READONLY,
	@MachinePropertyList 	[internal].[machine_property_list_type] READONLY,
	@Status 				INT = 0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	SET @Status = 0
	
	
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
	
	
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
    
    
    
    DECLARE @tran_count INT = @@TRANCOUNT;
    DECLARE @savepoint_name NCHAR(32);
    IF @tran_count > 0
    BEGIN
        SET @savepoint_name = REPLACE(CONVERT(NCHAR(36), NEWID()), N'-', N'');
        SAVE TRANSACTION @savepoint_name;
    END
    ELSE
        BEGIN TRANSACTION;                                                                                      
	BEGIN TRY				
		UPDATE [internal].[worker_agents]
		SET [LastOnlineTime]=SYSDATETIMEOFFSET(),
			[MachineName]= 
				CASE 
					WHEN EXISTS (SELECT * FROM @MachinePropertyList WHERE [PropertyName]='MachineName') THEN (SELECT [PropertyValue] FROM @MachinePropertyList WHERE [PropertyName]='MachineName')
					ELSE [MachineName]
				END,
			[UserAccount]=
				CASE 
					WHEN EXISTS (SELECT * FROM @MachinePropertyList WHERE [PropertyName]='UserAccount') THEN (SELECT [PropertyValue] FROM @MachinePropertyList WHERE [PropertyName]='UserAccount')
					ELSE [UserAccount]
				END,
			@Status = [IsEnabled]
		FROM [internal].[worker_agents] 
		WHERE [WorkerAgentId]=@WorkerAgentId
		
		IF @@ROWCOUNT = 0
		BEGIN
			INSERT INTO [internal].[worker_agents]([WorkerAgentId],[LastOnlineTime],[MachineName],[UserAccount]) VALUES		
			(@WorkerAgentId, SYSDATETIMEOFFSET(), 
			(SELECT [PropertyValue] FROM @MachinePropertyList WHERE [PropertyName]='MachineName'),
			(SELECT [PropertyValue] FROM @MachinePropertyList WHERE [PropertyName]='UserAccount'))
			SET @Status = 0
		END
				
		INSERT INTO [internal].[worker_agent_perfcounter] ([WorkerAgentId],[PerfCounterName], [PerfCounterValue],[TimeStamp])
		SELECT @WorkerAgentId, [PerfCounterName], [PerfCounterValue], [TimeStamp] FROM @PerfCounterList
		
		MERGE INTO [internal].[machine_properties] AS dst
		USING @MachinePropertyList AS src
		ON @WorkerAgentId = dst.WorkerAgentId AND src.[PropertyName] = dst.[PropertyName]
		WHEN MATCHED THEN UPDATE SET dst.[PropertyValue] = src.[PropertyValue]
		WHEN NOT MATCHED THEN INSERT VALUES(@WorkerAgentId, src.[PropertyName], src.[PropertyValue]);
		
	
        IF @tran_count = 0
            COMMIT TRANSACTION;                                                                                 
    END TRY
    BEGIN CATCH
        
        IF @tran_count = 0 
            ROLLBACK TRANSACTION;
        
        ELSE IF XACT_STATE() <> -1
            ROLLBACK TRANSACTION @savepoint_name;                                                                             
        THROW 
    END CATCH
	
	RETURN 0
END
