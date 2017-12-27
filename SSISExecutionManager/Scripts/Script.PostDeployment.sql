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
PRINT 'Started populating database'
-----------------------------------------------------------------------------------
PRINT 'Started Sync cfg.Configurations.sql'
		:r "Sync Configurations.sql"
PRINT 'Completed Sync cfg.Configurations.sql'

PRINT 'Started Populate Reference Data.sql'
		:r "Populate Reference Data.sql"
PRINT 'Completed Populate Reference Data.sql'
-----------------------------------------------------------------------------------
/*IF $(DeployExample) = 1
BEGIN
	PRINT 'Started Setting Up Example Projects.sql'
		:r ".\Example 1 Setup\Configure SSIS Catalog and Deploy Example1 Projects.sql"
		:r ".\Example 1 Setup\Populate Example1 Metadata.sql"
		:r ".\Example 1 Setup\Create Example 1 SQL Agent Job.sql"
	PRINT 'Started Setting Up Example Projects.sql'
END*/
-----------------------------------------------------------------------------------

PRINT 'Completed populating database'