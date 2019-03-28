CREATE TYPE [internal].[adt_event_data] AS TABLE (
    [event_data_type_name] [internal].[adt_name] NOT NULL,
    [event_data_value]     SQL_VARIANT           NULL);

