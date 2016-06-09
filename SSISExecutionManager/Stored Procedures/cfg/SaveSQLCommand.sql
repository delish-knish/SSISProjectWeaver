CREATE PROCEDURE [cfg].[SaveSQLCommand] @SQLCommandId                   INT = NULL,
                                        @SQLCommandName                 VARCHAR(128),
                                        @SQLCommand                     NVARCHAR(MAX),
                                        @SQLCommandDescription          VARCHAR(MAX),
                                        @RequiresETLBatchIdParameterInd BIT
AS
    MERGE [ctl].SQLCommand AS Target
    USING (SELECT
             @SQLCommandId
             ,@SQLCommandName
             ,@SQLCommand
             ,@SQLCommandDescription
             ,@RequiresETLBatchIdParameterInd) AS source ( SQLCommandId, SQLCommandName, SQLCommand, SQLCommandDescription, RequiresETLBatchIdParameterInd)
    ON target.SQLCommandId = source.SQLCommandId
    WHEN Matched THEN
      UPDATE SET SQLCommandName = source.SQLCommandName
                 ,SQLCommand = source.SQLCommand
                 ,SQLCommandDescription = source.SQLCommandDescription
                 ,RequiresETLBatchIdParameterInd = source.RequiresETLBatchIdParameterInd
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (SQLCommandName
              ,SQLCommand
              ,SQLCommandDescription
              ,RequiresETLBatchIdParameterInd )
      VALUES(  source.SQLCommandName
              ,source.SQLCommand
              ,source.SQLCommandDescription
              ,source.RequiresETLBatchIdParameterInd );


    RETURN 0 
