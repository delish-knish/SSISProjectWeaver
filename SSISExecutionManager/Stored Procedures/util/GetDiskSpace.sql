CREATE PROCEDURE [util].[GetDiskSpace]
AS
    SELECT DISTINCT
      volume_mount_point
      ,total_bytes / POWER(1024, 3)                                                                                                                                               AS TotalGB
      ,available_bytes / POWER(1024, 3)                                                                                                                                           AS AvailableGB
      ,( CAST(total_bytes / POWER(1024, 3)AS DECIMAL(6, 2)) - CAST(available_bytes / POWER(1024, 3)AS DECIMAL(6, 2)) ) / CAST(total_bytes / POWER(1024, 3)AS DECIMAL(6, 2)) * 100 AS PctFree
    FROM
      sys.master_files AS f
      CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id);

    RETURN 0 
