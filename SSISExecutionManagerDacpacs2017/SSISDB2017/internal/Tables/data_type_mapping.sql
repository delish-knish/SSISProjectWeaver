CREATE TABLE [internal].[data_type_mapping] (
    [mapping_id]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [ssis_data_type] NVARCHAR (128) NOT NULL,
    [sql_data_type]  NVARCHAR (128) NOT NULL,
    CONSTRAINT [PK_Data_Type_Mapping] PRIMARY KEY CLUSTERED ([mapping_id] ASC),
    CONSTRAINT [Unique_data_type_mapping] UNIQUE NONCLUSTERED ([ssis_data_type] ASC, [sql_data_type] ASC)
);

