USE B10THACOIDACC
GO
DECLARE @_BranchCode NVARCHAR(3) = N'I20';

DECLARE @_Year INT = '2026'

DECLARE @_Month INT

DECLARE @_RunAll_To_3107 INT = 0
DECLARE @_DocDate1 DATE
DECLARE @_DocDate2 DATE

SELECT @_RunAll_To_3107 = 1

SELECT @_Month = 3

IF @_RunAll_To_3107 = 1
BEGIN
    SELECT @_DocDate1 = '20260101'
    SELECT @_DocDate2 = '20260731'
END
ELSE
BEGIN
    SELECT @_DocDate1 = DATEFROMPARTS(@_Year, @_Month, '01')
    SELECT @_DocDate2 = EOMONTH(@_DocDate1)
END

DECLARE @_DocDate_Filer DATE

DROP TABLE IF EXISTS #tbl;
;WITH M
AS (SELECT DATEFROMPARTS(YEAR(@_DocDate1), MONTH(@_DocDate1), 1) AS DocDate
    UNION ALL
    SELECT DATEADD(MONTH, 1, M.DocDate)
    FROM M
    WHERE M.DocDate < DATEFROMPARTS(YEAR(@_DocDate2), MONTH(@_DocDate2), 1))
SELECT *
     , 0 AS _Scan
INTO #tbl
FROM M;
 
; WHILE EXISTS (SELECT * FROM #tbl WHERE _Scan = 0)
BEGIN

    SELECT TOP (1)
           @_DocDate_Filer = DocDate
    FROM #tbl
    WHERE _Scan = 0
    ORDER BY DocDate ASC;
    UPDATE #tbl
    SET _Scan = 1
    WHERE DocDate = @_DocDate_Filer;

    --Sản phẩm hoàn thiện
    EXEC usp_ZPL_ThanhPhamPhanRa @_DocDate = @_DocDate_Filer
                               , @_nUserId = 1213
                               , @_LangId = 0
                               , @_BranchCode = @_BranchCode
                               , @_FiscalYear = '2026'
                               , @_CommandKey = 'GIA_THANH_CPTC'
                               , @_CurrencyCode0 = 'VND'

    --Sản lượng bán hàng
    EXEC usp_ZCPTC_SanLuongBanHang @_DocDate = @_DocDate_Filer
                                 , @_nUserId = 1213
                                 , @_LangId = 0
                                 , @_BranchCode = @_BranchCode
                                 , @_FiscalYear = '2026'
                                 , @_CommandKey = 'GIA_THANH_CPTC'
                                 , @_CurrencyCode0 = 'VND'

    --Xác định sản phầm phân rã
    EXEC usp_ZPL_XacDinhThanhPhamPhanRa @_DocDate = @_DocDate_Filer
                                      , @_nUserId = 1213
                                      , @_LangId = 0
                                      , @_BranchCode = @_BranchCode
                                      , @_FiscalYear = '2026'
                                      , @_CommandKey = 'GIA_THANH_CPTC'
                                      , @_CurrencyCode0 = 'VND'

    --Phân rã yếu tố Giá thành
    EXEC usp_ZPL_PhanRaYeuTo2 @_DocDate = @_DocDate_Filer
                            , @_nUserId = 1213
                            , @_LangId = 0
                            , @_BranchCode = @_BranchCode
                            , @_FiscalYear = '2026'
                            , @_CurrencyCode0 = 'VND'

    --Phân rã giá vốn bán hàng theo yếu tố giá thành
    EXEC usp_ZCPTC_PhanRaGiaVon @_DocDate = @_DocDate_Filer
                              , @_BranchCode = @_BranchCode
                              , @_CurrencyCode0 = 'VND'
                              , @_FiscalYear = '2026'
                              , @_nUserId = 1213
                              , @_LangId = 0

    --Xác định chi phí hoạt động
    EXEC usp_B30ZExpenseCPTC_CollectionData @_DocDate = '01/02/2026 00:00:00.000'
                                          , @_StageId = '17652682'
                                          , @_FiscalYear = '2026'
                                          , @_CurrencyCode0 = 'VND'
                                          , @_nUserId = 1213
                                          , @_LangId = 0
                                          , @_BranchCode = @_BranchCode
                                          , @_CommandKey = 'GIA_THANH_CPTC'

    --Kết chuyển chi phí trực tiếp
    EXEC usp_ZCPTC_DirectCost @_DocDate = @_DocDate_Filer
                            , @_StageId = 17652682
                            , @_BranchCode = @_BranchCode
                            , @_FiscalYear = '2026'
                            , @_nUserId = 1213
                            , @_LangId = 0
                            , @_CommandKey = 'GIA_THANH_CPTC'

    --Phân bổ chi phí theo hệ số
    EXEC usp_ZCPTC_AllocateCost @_DocDate = @_DocDate_Filer
                              , @_StageId = 17652682
                              , @_BranchCode = @_BranchCode
                              , @_FiscalYear = '2026'
                              , @_nUserId = 1213
                              , @_LangId = 0
                              , @_CommandKey = 'GIA_THANH_CPTC'
END;