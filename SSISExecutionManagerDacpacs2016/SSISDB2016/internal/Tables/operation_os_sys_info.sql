CREATE TABLE [internal].[operation_os_sys_info] (
    [info_id]                      BIGINT IDENTITY (1, 1) NOT NULL,
    [operation_id]                 BIGINT NOT NULL,
    [total_physical_memory_kb]     BIGINT NOT NULL,
    [available_physical_memory_kb] BIGINT NULL,
    [total_page_file_kb]           BIGINT NULL,
    [available_page_file_kb]       BIGINT NOT NULL,
    [cpu_count]                    INT    NOT NULL,
    CONSTRAINT [PK_Operation_Os_Sys_Info] PRIMARY KEY CLUSTERED ([info_id] ASC),
    CONSTRAINT [FK_OssysInfo_Operations] FOREIGN KEY ([operation_id]) REFERENCES [internal].[operations] ([operation_id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_OsSysInfo_Operation_id]
    ON [internal].[operation_os_sys_info]([operation_id] ASC);

