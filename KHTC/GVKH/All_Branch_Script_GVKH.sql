declare @_BranchCode nvarchar(3) = N'I02';

declare @_DocDate1 date = '20260101';
declare @_DocDate2 date = getdate();

declare @_DocDate_Filer date = getdate();

drop table if exists #tbl;
with M
as (select datefromparts(year(@_DocDate1), month(@_DocDate1), 1) as DocDate
    union all
    select dateadd(month, 1, M.DocDate)
    from M
    where M.DocDate < datefromparts(year(@_DocDate2), month(@_DocDate2), 1))
select *
     , 0 as _Scan
into #tbl
from M;



while exists (select * from #tbl where _Scan = 0)
begin

    select top (1)
           @_DocDate_Filer = DocDate
    from #tbl
    where _Scan = 0
    order by DocDate asc;

    update #tbl
    set _Scan = 1
    where DocDate = @_DocDate_Filer;

    exec usp_ZPL_ThanhPhamPhanRa @_DocDate = @_DocDate_Filer
                               , @_nUserId = 1213
                               , @_LangId = 0
                               , @_BranchCode = @_BranchCode
                               , @_FiscalYear = '2026'
                               , @_DataCode = default
                               , @_CommandKey = 'GIA_THANH_CPTC'
                               , @_CurrencyCode0 = 'VND'
                               , @_ResultType = default
                               , @_IsTest = default;
    exec usp_ZCPTC_SanLuongBanHang @_DocDate = @_DocDate_Filer
                                 , @_nUserId = 1213
                                 , @_LangId = 0
                                 , @_BranchCode = @_BranchCode
                                 , @_FiscalYear = '2026'
                                 , @_DataCode = default
                                 , @_CommandKey = 'GIA_THANH_CPTC'
                                 , @_CurrencyCode0 = 'VND'
                                 , @_ResultType = default
                                 , @_IsTest = default;
    exec usp_ZPL_XacDinhThanhPhamPhanRa @_DocDate = @_DocDate_Filer
                                      , @_nUserId = 1213
                                      , @_LangId = 0
                                      , @_BranchCode = @_BranchCode
                                      , @_FiscalYear = '2026'
                                      , @_DataCode = default
                                      , @_CommandKey = 'GIA_THANH_CPTC'
                                      , @_CurrencyCode0 = 'VND'
                                      , @_IsTest = default;
    exec usp_ZPL_PhanRaYeuTo2 @_DocDate = @_DocDate_Filer
                            , @_nUserId = 1213
                            , @_LangId = 0
                            , @_BranchCode = @_BranchCode
                            , @_FiscalYear = '2026'
                            , @_DataCode = default
                            , @_CommandKey = default
                            , @_CurrencyCode0 = 'VND'
                            , @_IsTest = default;
    exec usp_ZCPTC_PhanRaGiaVon @_DocDate = @_DocDate_Filer
                              , @_BranchCode = @_BranchCode
                              , @_CurrencyCode0 = 'VND'
                              , @_FiscalYear = '2026'
                              , @_nUserId = 1213
                              , @_LangId = 0
                              , @_CommandKey = default
                              , @_ResultType = default
                              , @_IsTest = default;

end;