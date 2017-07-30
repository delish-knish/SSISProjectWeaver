CREATE PROCEDURE [sqlcmd].[IsFilePresent] @Path            VARCHAR(512),
                                          @ConditionMetInd BIT OUT
AS
    SET NOCOUNT ON;

    DECLARE @Result INT

    EXEC master.dbo.xp_fileexist
      @Path,
      @Result OUTPUT

    SET @ConditionMetInd = CAST(@Result AS BIT);

    RETURN 0 
