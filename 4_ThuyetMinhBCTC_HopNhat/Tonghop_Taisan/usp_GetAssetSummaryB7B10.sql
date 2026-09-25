CREATE OR ALTER PROC usp_GetAssetSummaryB7B10
    @_DocDate1 DATE = '' OUTPUT
  , @_DocDate2 DATE = '' OUTPUT
  , @_LstBranchCodeB10 VARCHAR(MAX) = ''
  , @_LstBranchCodeB7 VARCHAR(MAX) = ''
AS
BEGIN
    SET NOCOUNT ON

    IF @_DocDate1 = ''
        SET @_DocDate1 = '20260101'
    IF @_DocDate2 = ''
        SET @_DocDate2 = GETDATE()


    SELECT @_DocDate2 = EOMONTH(@_DocDate2)
    SELECT @_DocDate1 = DATEFROMPARTS(YEAR(@_DocDate1), MONTH(@_DocDate1), '01')



    IF ISNULL(@_LstBranchCodeB10, '') <> ''
        EXEC usp_GetAssetSummaryB10 @_LstBranchCodeB10 = @_LstBranchCodeB10
                                  , @_DocDate1 = @_DocDate1
                                  , @_DocDate2 = @_DocDate2

    IF ISNULL(@_LstBranchCodeB7, '') <> ''
        EXEC usp_GetAssetSummaryB7 @_LstBranchCodeB7 = @_LstBranchCodeB7
                                 , @_DocDate1 = @_DocDate1
                                 , @_DocDate2 = @_DocDate2
END

GO

SET DATEFORMAT DMY
EXEC usp_GetAssetSummaryB7B10 @_DocDate1 = '01/01/2026 00:00:00.000'
                            , @_DocDate2 = '31/01/2026 00:00:00.000'
                            , @_LstBranchCodeB10 = 'I01'