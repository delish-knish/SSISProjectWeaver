CREATE TABLE [internal].[alwayson_support_state] (
    [server_name] NVARCHAR (256) NOT NULL,
    [state]       TINYINT        NOT NULL,
    PRIMARY KEY CLUSTERED ([server_name] ASC)
);

