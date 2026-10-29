USE B10THACOIDACC;
GO



SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROC dbo.usp_Get_CPBH_CPQL_B7B10
    @_DocDate1 DATE = '' OUTPUT
  , @_DocDate2 DATE = '' OUTPUT
  , @_LstBranchCodeB10 VARCHAR(MAX) = ''
  , @_LstBranchCodeB7 VARCHAR(MAX) = ''
AS
BEGIN
    SET NOCOUNT ON;

    IF @_DocDate1 = ''
       AND @_DocDate2 = ''
        RETURN;

    SELECT @_DocDate2 = EOMONTH(@_DocDate2);
    SELECT @_DocDate1 = DATEFROMPARTS(YEAR(@_DocDate1), MONTH(@_DocDate1), '01');

    IF @_DocDate1 < '20260101'
       AND @_DocDate2 < '20260101'
    BEGIN
        EXEC usp_Get_QPBH_CPQL_B7_IND @_DocDate1 = @_DocDate1
                                    , @_DocDate2 = @_DocDate2;

        EXEC usp_Get_QPBH_CPQL_B7 @_LstBranchCodeB7 = @_LstBranchCodeB7
                                , @_DocDate1 = @_DocDate1
                                , @_DocDate2 = @_DocDate2;
    END;
    ELSE
    BEGIN
        EXEC usp_Get_QPBH_CPQL @_LstBranchCodeB10 = @_LstBranchCodeB10
                             , @_DocDate1 = @_DocDate1
                             , @_DocDate2 = @_DocDate2;

        EXEC usp_Get_QPBH_CPQL_B7 @_LstBranchCodeB7 = @_LstBranchCodeB7
                                , @_DocDate1 = @_DocDate1
                                , @_DocDate2 = @_DocDate2;
    END;
END;

GO
