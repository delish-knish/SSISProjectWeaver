CREATE TYPE [internal].[decrypted_data_table] AS TABLE (
    [id]    BIGINT          NOT NULL,
    [value] VARBINARY (MAX) NULL);

