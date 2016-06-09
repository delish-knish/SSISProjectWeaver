/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
PRINT 'Started populating reference tables'
----------------------------------------------------------------------------------
IF $(PopulateReferenceData) = 1
BEGIN
	PRINT 'Started Populate Reference Data.sql'
		:r "Populate Reference Data.sql"
	PRINT 'Completed Populate Reference Data.sql'
END
-----------------------------------------------------------------------------------
IF $(DeployPackageConfiguration) = 1
BEGIN
	PRINT 'Started Insert ETLPackage Configurations.sql'
		:r ".\Initial Deployment\Insert ETLPackage Configurations.sql"
	PRINT 'Completed Insert ETLPackage Configurations.sql'
END
-----------------------------------------------------------------------------------
PRINT 'Started Sync cfg.Configurations.sql'
		:r "Sync Configurations.sql"
PRINT 'Completed Sync cfg.Configurations.sql'

------------------------------------------------------------------------------------
PRINT 'Completed populating reference tables'