


CREATE PROCEDURE [internal].[insert_operation]
        @operation_type     smallint,
        @created_time       datetimeoffset,
        @object_type        int,
        @object_id          bigint,
        @object_name        nvarchar(260),
        @status             int,
        @start_time         datetimeoffset,
        @end_time           datetimeoffset,
        @caller_sid         [internal].[adt_sid],
        @caller_name        [internal].[adt_sname],
        @process_id         int=null,
        @stopped_by_sid     [internal].[adt_sid],
        @stopped_by_name    [internal].[adt_sname],
        @operation_id       bigint output
AS
SET NOCOUNT ON
BEGIN
  DECLARE @operation_guid uniqueidentifier
  DECLARE @servername sysname
  DECLARE @machinename sysname

  SET @operation_guid = NEWID()
  SET @servername = CONVERT(sysname, SERVERPROPERTY('servername'))
  SET @machinename = CONVERT(sysname, SERVERPROPERTY('machinename'))


  INSERT INTO internal.operations (
        operation_type,
        created_time,
        object_type,
        [object_id],
        [object_name],
        [status],
        start_time,
        end_time,
        caller_sid,
        caller_name,
        process_id,
        stopped_by_sid,
        stopped_by_name,
        operation_guid,
        server_name,
        machine_name
        ) 
  VALUES (
        @operation_type,
        @created_time,
        @object_type,
        @object_id,
        @object_name,
        @status,
        @start_time,
        @end_time,
        @caller_sid,
        @caller_name,
        @process_id,
        @stopped_by_sid,
        @stopped_by_name,
        @operation_guid,
        @servername,
        @machinename
        )
  
  IF @@ROWCOUNT = 1
  BEGIN
    SET @operation_id = scope_identity()
    RETURN 0
  END
  ELSE BEGIN
    SET @operation_id = -1
    RETURN -1
  END
END

