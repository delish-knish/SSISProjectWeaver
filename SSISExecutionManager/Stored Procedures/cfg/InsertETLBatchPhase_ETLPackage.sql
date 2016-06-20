CREATE PROCEDURE [cfg].[InsertETLBatchPhase_ETLPackage] @ETLPackageId    INT,
															 @ETLBatchPhaseId INT
AS
    INSERT INTO [ctl].[ETLBatchPhase_ETLPackage]
                (ETLPackageId
                 ,[ETLBatchPhaseId])
    VALUES     (@ETLPackageId
                ,@ETLBatchPhaseId)

    RETURN 0 
