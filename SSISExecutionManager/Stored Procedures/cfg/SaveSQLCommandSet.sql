CREATE PROCEDURE [cfg].[SaveSQLCommandSet] @SQLCommandSetId          INT = NULL,
                                           @SQLCommandSetName        VARCHAR(250),
                                           @SQLCommandSetDescription VARCHAR(MAX)
AS
    MERGE [ctl].SQLCommandSet AS Target
    USING (SELECT
             @SQLCommandSetId
             ,@SQLCommandSetName
             ,@SQLCommandSetDescription) AS source ( SQLCommandSetId, SQLCommandSetName, SQLCommandSetDescription)
    ON target.SQLCommandSetId = source.SQLCommandSetId
    WHEN Matched THEN
      UPDATE SET SQLCommandSetName = source.SQLCommandSetName
                 ,SQLCommandSetDescription = source.SQLCommandSetDescription
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (SQLCommandSetName
              ,SQLCommandSetDescription )
      VALUES( source.SQLCommandSetName
              ,source.SQLCommandSetDescription );


    RETURN 0 
