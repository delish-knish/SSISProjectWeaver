CREATE PROCEDURE [cfg].[SaveETLPackageSet] @ETLPackageSetId          INT = NULL,
                                           @ETLPackageSetName        VARCHAR(250),
                                           @ETLPackageSetDescription VARCHAR(MAX)
AS
    MERGE [ctl].ETLPackageSet AS Target
    USING (SELECT
             @ETLPackageSetId
             ,@ETLPackageSetName
             ,@ETLPackageSetDescription) AS source ( ETLPackageSetId, ETLPackageSetName, ETLPackageSetDescription)
    ON target.ETLPackageSetId = source.ETLPackageSetId
    WHEN Matched THEN
      UPDATE SET ETLPackageSetName = source.ETLPackageSetName
                 ,ETLPackageSetDescription = source.ETLPackageSetDescription
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (ETLPackageSetName
              ,ETLPackageSetDescription )
      VALUES( source.ETLPackageSetName
              ,source.ETLPackageSetDescription );


    RETURN 0 
