CREATE TABLE [internal].[catalog_encryption_keys] (
    [key_id]   BIGINT           IDENTITY (1, 1) NOT NULL,
    [key_name] NVARCHAR (255)   NOT NULL,
    [KEY]      VARBINARY (8000) NOT NULL,
    [IV]       VARBINARY (8000) NOT NULL,
    CONSTRAINT [PK_Encryption_Keys] PRIMARY KEY CLUSTERED ([key_id] ASC)
);

