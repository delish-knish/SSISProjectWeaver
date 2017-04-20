--Anything that is environment specific should use a SQLCMD variable at the project level

MERGE cfg.[Configuration] AS Target
USING (VALUES ('EMAILDEF', 'Email Recipients - Default','$(EmailRecipientsDefault)'),
			  ('EMAILMON', 'Email Recipients - Monitors', '$(EmailRecipientsMonitors)'),
			  ('BATPOLDEL', 'ETL Batch Polling Delay','00:00:30'),
			  ('SQLCONPOLDEL', 'Default SQL Command Condition Evaluation Polling Delay','00:05:00'),
			  ('RPTDSBLPKG', 'Report Disabled Packages','True')
			  
			  	  ) AS Source (ConfigurationCd, ConfigurationName, ConfigurationValue )
ON ( Target.ConfigurationCd = Source.ConfigurationCd )
--Don't update so that we don't overwrite a manual change
WHEN NOT MATCHED BY TARGET THEN
  INSERT (ConfigurationCd
		  ,ConfigurationName
          ,ConfigurationValue)
  VALUES (ConfigurationCd
		  ,ConfigurationName
          ,ConfigurationValue)
--WHEN NOT MATCHED BY SOURCE THEN --DO NOT UNCOMMENT THIS. IT WILL REMOVE INCREMENTAL DATE CONFIGS.
--  DELETE
  ; 
