--Anything that is environment specific should use a SQLCMD variable at the project level

MERGE cfg.[Configuration] AS Target
USING (VALUES ('Email Recipients - Default','$(EmailRecipientsDefault)'),
			  ('Email Recipients - Monitors', '$(EmailRecipientsMonitors)'),
			  ('Minutes Back to Continue a Batch', '4320'),
			  ('Polling Delay in Minutes','5')
			  
			  	  ) AS Source (ConfigurationName, ConfigurationValue )
ON ( Target.ConfigurationName = Source.ConfigurationName )
--Don't update so that we don't overwrite a manual change
WHEN NOT MATCHED BY TARGET THEN
  INSERT (ConfigurationName
          ,ConfigurationValue)
  VALUES (ConfigurationName
          ,ConfigurationValue)
WHEN NOT MATCHED BY SOURCE THEN
  DELETE; 
