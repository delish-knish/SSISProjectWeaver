CREATE TABLE [internal].[catalog_properties] (
    [property_name]  NVARCHAR (256) NOT NULL,
    [property_value] NVARCHAR (256) NOT NULL,
    CONSTRAINT [PK_ISServer_Property] PRIMARY KEY CLUSTERED ([property_name] ASC)
);

