CREATE PROCEDURE [cfg].[SaveETLPackageGroup_ETLPackage_SQLCommandCondition] @ETLPackageGroupId   INT,
                                                            @ETLPackageId INT,
                                                            @SQLCommandId INT,
                                                            @EnabledInd   BIT,
															@NotificationOnConditionMetEnabledInd     BIT, 
															@NotificationOnConditionNotMetEnabledInd   BIT,
															@NotificationEmailConfigurationCd          BIT
AS
	DECLARE @ETLPackageGroup_ETLPackageId INT = (
	SELECT
		ETLPackageGroup_ETLPackageId
	FROM 
		ETLPackageGroup_ETLPackage
	WHERE
		ETLPackageGroupId = @ETLPackageGroupId
		AND ETLPackageId = @ETLPackageId)

	IF @ETLPackageGroup_ETLPackageId IS NULL
            THROW 50100, 'The package group/package configuration does not exist.', 1;

    MERGE [cfg].[ETLPackageGroup_ETLPackage_SQLCommandCondition] AS Target
    USING (SELECT
			@ETLPackageGroup_ETLPackageId
            ,@SQLCommandId
            ,@EnabledInd
			,@NotificationOnConditionMetEnabledInd
			,@NotificationOnConditionNotMetEnabledInd
			,@NotificationEmailConfigurationCd) AS source (ETLPackageGroup_ETLPackageId, SQLCommandId, EnabledInd, NotificationOnConditionMetEnabledInd, NotificationOnConditionNotMetEnabledInd, NotificationEmailConfigurationCd )
    ON target.ETLPackageGroup_ETLPackageId = source.ETLPackageGroup_ETLPackageId
       AND target.SQLCommandId = source.SQLCommandId
    WHEN Matched THEN
      UPDATE SET EnabledInd = source.EnabledInd
	  ,NotificationOnConditionMetEnabledInd = @NotificationOnConditionMetEnabledInd
	  ,NotificationOnConditionNotMetEnabledInd = @NotificationOnConditionNotMetEnabledInd
	  ,NotificationEmailConfigurationCd = @NotificationEmailConfigurationCd
                ,[LastUpdatedDate] = GETDATE()
                ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (ETLPackageGroup_ETLPackageId
             ,SQLCommandId
             ,EnabledInd
			 ,NotificationOnConditionMetEnabledInd
			 ,NotificationOnConditionNotMetEnabledInd
			 ,NotificationEmailConfigurationCd )
      VALUES( source.ETLPackageGroup_ETLPackageId
             ,source.SQLCommandId
             ,source.EnabledInd
			 ,source.NotificationOnConditionMetEnabledInd
			 ,source.NotificationOnConditionNotMetEnabledInd
			 ,source.NotificationEmailConfigurationCd );

    RETURN 0 
