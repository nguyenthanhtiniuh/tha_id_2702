DECLARE @_BranchCode NVARCHAR(3) = N'I14';
DECLARE @_DocDate1 DATE = '20260101';
DECLARE @_DocDate2 DATE = '20260630';
DECLARE @_DocDate_Filer DATE = GETDATE();
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


WHILE EXISTS (SELECT * FROM #tbl WHERE _Scan = 0)
BEGIN
    SELECT TOP (1)
           @_DocDate_Filer = DocDate
    FROM #tbl
    WHERE _Scan = 0
    ORDER BY DocDate ASC;
    UPDATE #tbl
    SET _Scan = 1
    WHERE DocDate = @_DocDate_Filer;
    EXEC usp_ZPL_ThanhPhamPhanRa @_DocDate = @_DocDate_Filer
                               , @_nUserId = 1213
                               , @_LangId = 0
                               , @_BranchCode = @_BranchCode
                               , @_FiscalYear = '2026'
                               , @_DataCode = DEFAULT
                               , @_CommandKey = 'GIA_THANH_CPTC'
                               , @_CurrencyCode0 = 'VND'
                               , @_ResultType = DEFAULT
                               , @_IsTest = DEFAULT;
    EXEC usp_ZCPTC_SanLuongBanHang @_DocDate = @_DocDate_Filer
                                 , @_nUserId = 1213
                                 , @_LangId = 0
                                 , @_BranchCode = @_BranchCode
                                 , @_FiscalYear = '2026'
                                 , @_DataCode = DEFAULT
                                 , @_CommandKey = 'GIA_THANH_CPTC'
                                 , @_CurrencyCode0 = 'VND'
                                 , @_ResultType = DEFAULT
                                 , @_IsTest = DEFAULT;
    EXEC usp_ZPL_XacDinhThanhPhamPhanRa @_DocDate = @_DocDate_Filer
                                      , @_nUserId = 1213
                                      , @_LangId = 0
                                      , @_BranchCode = @_BranchCode
                                      , @_FiscalYear = '2026'
                                      , @_DataCode = DEFAULT
                                      , @_CommandKey = 'GIA_THANH_CPTC'
                                      , @_CurrencyCode0 = 'VND'
                                      , @_IsTest = DEFAULT;
    EXEC usp_ZPL_PhanRaYeuTo2 @_DocDate = @_DocDate_Filer
                            , @_nUserId = 1213
                            , @_LangId = 0
                            , @_BranchCode = @_BranchCode
                            , @_FiscalYear = '2026'
                            , @_DataCode = DEFAULT
                            , @_CommandKey = DEFAULT
                            , @_CurrencyCode0 = 'VND'
                            , @_IsTest = DEFAULT;
    EXEC usp_ZCPTC_PhanRaGiaVon @_DocDate = @_DocDate_Filer
                              , @_BranchCode = @_BranchCode
                              , @_CurrencyCode0 = 'VND'
                              , @_FiscalYear = '2026'
                              , @_nUserId = 1213
                              , @_LangId = 0
                              , @_CommandKey = DEFAULT
                              , @_ResultType = DEFAULT
                              , @_IsTest = DEFAULT;
END;