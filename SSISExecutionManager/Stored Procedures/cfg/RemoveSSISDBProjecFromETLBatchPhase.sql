CREATE PROCEDURE [cfg].[RemoveSSISDBProjecFromETLBatchPhase] @SSISDBFolderName  VARCHAR(128),
                                                             @SSISDBProjectName VARCHAR(128),
                                                             @ETLBatchPhaseId INT
AS
    DELETE epeps
    FROM   [ctl].[ETLBatchPhase_ETLPackage] epeps
           JOIN ctl.ETLPackage ep
             ON epeps.ETLPackageId = ep.ETLPackageId
    WHERE  SSISDBFolderName = @SSISDBFolderName
           AND SSISDBProjectName = @SSISDBProjectName
           AND [ETLBatchPhaseId] = @ETLBatchPhaseId

    RETURN 0 
