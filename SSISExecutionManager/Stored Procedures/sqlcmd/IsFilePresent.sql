CREATE PROCEDURE [sqlcmd].[IsFilePresent] @Path            VARCHAR(512),
                                          @ConditionMetInd BIT OUT
AS
    DECLARE @Result INT

    EXEC master.dbo.xp_fileexist
      @Path,
      @Result OUTPUT

    (SELECT
       @Result AS ConditionMetInd)

    RETURN 0 
