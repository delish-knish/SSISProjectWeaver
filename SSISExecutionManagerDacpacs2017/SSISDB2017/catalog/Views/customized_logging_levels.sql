
CREATE VIEW [catalog].[customized_logging_levels]
AS
SELECT     [level_id],
           [name],
           [description],
           [profile_value],
           [events_value],
           [created_by_sid],
           [created_by_name],
           [created_time]
FROM       [internal].[customized_logging_levels]
