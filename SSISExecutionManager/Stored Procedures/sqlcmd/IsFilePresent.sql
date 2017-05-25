CREATE PROCEDURE [sqlcmd].[IsFilePresent] @Path            VARCHAR(512),
                                          @ConditionMetInd BIT OUT
AS
	SET NOCOUNT ON;

    DECLARE @Result INT

    EXEC master.dbo.xp_fileexist
      @Path,
      @Result OUTPUT

    RETURN 0 
