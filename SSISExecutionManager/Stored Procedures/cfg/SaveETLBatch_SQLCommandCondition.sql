CREATE PROCEDURE [cfg].[SaveETLBatch_SQLCommandCondition] @ETLBatchId   INT,
                                                            @SQLCommandId INT,
                                                            @EnabledInd   BIT,
															@NotificationOnConditionMetEnabledInd     BIT, 
															@NotificationOnConditionNotMetEnabledInd   BIT,
															@NotificationEmailConfigurationCd          BIT
AS
    MERGE [cfg].[ETLBatch_SQLCommandCondition] AS Target
    USING (SELECT
			@ETLBatchId
            ,@SQLCommandId
            ,@EnabledInd
			,@NotificationOnConditionMetEnabledInd
			,@NotificationOnConditionNotMetEnabledInd
			,@NotificationEmailConfigurationCd) AS source (ETLBatchId, SQLCommandId, EnabledInd, NotificationOnConditionMetEnabledInd, NotificationOnConditionNotMetEnabledInd, NotificationEmailConfigurationCd )
    ON target.ETLBatchId = source.ETLBatchId
       AND target.SQLCommandId = source.SQLCommandId
    WHEN Matched THEN
      UPDATE SET EnabledInd = source.EnabledInd
	  ,NotificationOnConditionMetEnabledInd = @NotificationOnConditionMetEnabledInd
	  ,NotificationOnConditionNotMetEnabledInd = @NotificationOnConditionNotMetEnabledInd
	  ,NotificationEmailConfigurationCd = @NotificationEmailConfigurationCd
                ,[LastUpdatedDate] = GETDATE()
                ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (ETLBatchId
             ,SQLCommandId
             ,EnabledInd
			 ,NotificationOnConditionMetEnabledInd
			 ,NotificationOnConditionNotMetEnabledInd
			 ,NotificationEmailConfigurationCd )
      VALUES( source.ETLBatchId
             ,source.SQLCommandId
             ,source.EnabledInd
			 ,source.NotificationOnConditionMetEnabledInd
			 ,source.NotificationOnConditionNotMetEnabledInd
			 ,source.NotificationEmailConfigurationCd );

    RETURN 0 
