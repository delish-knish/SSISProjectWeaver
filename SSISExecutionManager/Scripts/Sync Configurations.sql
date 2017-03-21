--Anything that is environment specific should use a SQLCMD variable at the project level

MERGE cfg.[Configuration] AS Target
USING (VALUES ('Email Recipients - Default','$(EmailRecipientsDefault)'),
			  ('Email Recipients - Monitors', '$(EmailRecipientsMonitors)'),
			  ('ETL Batch Polling Delay','00:00:05'),
			  ('Default SQL Command Trigger Polling Delay','00:05:00'),
			  ('Report Disabled Packages','True')
			  
			  	  ) AS Source (ConfigurationName, ConfigurationValue )
ON ( Target.ConfigurationName = Source.ConfigurationName )
--Don't update so that we don't overwrite a manual change
WHEN NOT MATCHED BY TARGET THEN
  INSERT (ConfigurationName
          ,ConfigurationValue)
  VALUES (ConfigurationName
          ,ConfigurationValue)
WHEN NOT MATCHED BY SOURCE THEN
  DELETE
  ; 
