CREATE ROLE [ssis_admin]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [AllSchemaOwner];

