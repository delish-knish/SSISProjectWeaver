DECLARE @pv binary(16)
BEGIN TRANSACTION
ALTER TABLE [ctl].[ETLPackage] DROP CONSTRAINT [FK_ETLPackage_EntryPointETLPackageId]
ALTER TABLE [ctl].[ETLPackage] DROP CONSTRAINT [FK_ETLPackage_SupportSeverityLevel]
SET IDENTITY_INSERT [ctl].[ETLPackage] ON
SET IDENTITY_INSERT [ctl].[ETLPackage] OFF
ALTER TABLE [ctl].[ETLPackage]
    ADD CONSTRAINT [FK_ETLPackage_EntryPointETLPackageId] FOREIGN KEY ([EntryPointETLPackageId]) REFERENCES [ctl].[ETLPackage] ([ETLPackageId])
ALTER TABLE [ctl].[ETLPackage]
    ADD CONSTRAINT [FK_ETLPackage_SupportSeverityLevel] FOREIGN KEY ([SupportSeverityLevelId]) REFERENCES [ref].[SupportSeverityLevel] ([SupportSeverityLevelId])
COMMIT TRANSACTION
