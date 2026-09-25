USE B10THACOIDACC
GO

CREATE OR ALTER PROC usp_Run_GVPR_ByBranch
    @_BranchCode NVARCHAR(3) = N''
  , @_RunAll INT = 0
AS
BEGIN

    DECLARE @_Year INT = '2026'

    DECLARE @_Month INT

    DECLARE @_DocDate1 DATE
    DECLARE @_DocDate2 DATE



    SELECT @_Month = 3

    IF @_RunAll = 1
    BEGIN
        SELECT @_DocDate1 = '20260101'
        SELECT @_DocDate2 = '20260831'
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
        PRINT N'DONE=>Sản phẩm hoàn thiện'

        --Sản lượng bán hàng
        EXEC usp_ZCPTC_SanLuongBanHang @_DocDate = @_DocDate_Filer
                                     , @_nUserId = 1213
                                     , @_LangId = 0
                                     , @_BranchCode = @_BranchCode
                                     , @_FiscalYear = '2026'
                                     , @_CommandKey = 'GIA_THANH_CPTC'
                                     , @_CurrencyCode0 = 'VND'
        PRINT N'DONE=>Sản lượng bán hàng'

        --Xác định sản phầm phân rã
        EXEC usp_ZPL_XacDinhThanhPhamPhanRa @_DocDate = @_DocDate_Filer
                                          , @_nUserId = 1213
                                          , @_LangId = 0
                                          , @_BranchCode = @_BranchCode
                                          , @_FiscalYear = '2026'
                                          , @_CommandKey = 'GIA_THANH_CPTC'
                                          , @_CurrencyCode0 = 'VND'
        PRINT N'DONE=>--Xác định sản phầm phân rã'

        --Phân rã yếu tố Giá thành
        EXEC usp_ZPL_PhanRaYeuTo_TuyenTinh @_DocDate = @_DocDate_Filer
                                         , @_nUserId = 1213
                                         , @_LangId = 0
                                         , @_BranchCode = @_BranchCode
                                         , @_FiscalYear = '2026'
                                         , @_CurrencyCode0 = 'VND'
        PRINT N'DONE=>--Phân rã yếu tố Giá thành'

        --Phân rã giá vốn bán hàng theo yếu tố giá thành
        EXEC usp_ZCPTC_PhanRaGiaVon @_DocDate = @_DocDate_Filer
                                  , @_BranchCode = @_BranchCode
                                  , @_CurrencyCode0 = 'VND'
                                  , @_FiscalYear = '2026'
                                  , @_nUserId = 1213
                                  , @_LangId = 0
        PRINT N'DONE=>--Phân rã giá vốn bán hàng theo yếu tố giá thành'

        --Xác định chi phí hoạt động
        EXEC usp_B30ZExpenseCPTC_CollectionData @_DocDate = @_DocDate_Filer
                                              , @_StageId = '17652682'
                                              , @_FiscalYear = '2026'
                                              , @_CurrencyCode0 = 'VND'
                                              , @_nUserId = 1213
                                              , @_LangId = 0
                                              , @_BranchCode = @_BranchCode
                                              , @_CommandKey = 'GIA_THANH_CPTC'
        PRINT N'DONE=>--Xác định chi phí hoạt động'


        --Kết chuyển chi phí trực tiếp
        EXEC usp_ZCPTC_DirectCost @_DocDate = @_DocDate_Filer
                                , @_StageId = 17652682
                                , @_BranchCode = @_BranchCode
                                , @_FiscalYear = '2026'
                                , @_nUserId = 1213
                                , @_LangId = 0
                                , @_CommandKey = 'GIA_THANH_CPTC'
        PRINT N'DONE=>--Kết chuyển chi phí trực tiếp'

        --Phân bổ chi phí theo hệ số
        EXEC usp_ZCPTC_AllocateCost @_DocDate = @_DocDate_Filer
                                  , @_StageId = 17652682
                                  , @_BranchCode = @_BranchCode
                                  , @_FiscalYear = '2026'
                                  , @_nUserId = 1213
                                  , @_LangId = 0
                                  , @_CommandKey = 'GIA_THANH_CPTC'
        PRINT N'DONE=>--Phân bổ chi phí theo hệ số'

        SELECT N'DONE'
             , @_DocDate_Filer
             , @_BranchCode

    END;
    DROP TABLE IF EXISTS #tbl
END
GO

GO
DROP TABLE IF EXISTS #T_Branch
SELECT BranchCode
INTO #T_Branch
FROM dbo.B00Branch
WHERE BranchCode IN
      (
          SELECT *
          --FROM STRING_SPLIT('I01,I02,I10,I11,I12,I14,I15,I17,I19,I20,I24,I25,I26,I27,I29,I30', ',')
          --FROM STRING_SPLIT('I09', ',')
          FROM STRING_SPLIT('I10', ',')
      )

--WHERE BranchCode IN ( 'I09', 'I10', 'I11', 'I12', 'I14', 'I17', 'I19', 'I20', 'I25', 'I26' )

ORDER BY BranchCode ASC

DECLARE @_BranchCode_Filter NVARCHAR(3) = ''
WHILE EXISTS (SELECT * FROM #T_Branch)
BEGIN

    SELECT TOP (1)
           @_BranchCode_Filter = BranchCode
    FROM #T_Branch
    ORDER BY BranchCode

    DELETE #T_Branch
    WHERE BranchCode = @_BranchCode_Filter

    EXEC usp_Run_GVPR_ByBranch @_BranchCode = @_BranchCode_Filter
                             , @_RunAll = 1

END