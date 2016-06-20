CREATE PROCEDURE [cfg].[AddSSISDBProjectToETLBatchPhase] @SSISDBFolderName  VARCHAR(128),
                                                         @SSISDBProjectName VARCHAR(128),
                                                         @ETLBatchPhaseId   INT
AS
    INSERT INTO [ctl].[ETLBatchPhase_ETLPackage]
                (ETLPackageId
                 ,[ETLBatchPhaseId])
    SELECT
      ep.ETLPackageId
      ,@ETLBatchPhaseId
    FROM
      ctl.ETLPackage ep
    WHERE
      SSISDBFolderName = @SSISDBFolderName
      AND SSISDBProjectName = @SSISDBProjectName

    RETURN 0 
