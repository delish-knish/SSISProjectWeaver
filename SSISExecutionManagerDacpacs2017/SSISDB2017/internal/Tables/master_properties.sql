CREATE TABLE [internal].[master_properties] (
    [property_name]  NVARCHAR (256) NOT NULL,
    [property_value] NVARCHAR (MAX) NOT NULL,
    CONSTRAINT [PK_Master_Property] PRIMARY KEY CLUSTERED ([property_name] ASC)
);

