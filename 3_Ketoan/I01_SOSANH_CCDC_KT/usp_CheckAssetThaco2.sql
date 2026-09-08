declare @p17 nvarchar(max)
 
declare @p18 varchar(max)
 
exec usp_CheckAssetThaco2 @_DocDate1='2026-07-01 00:00:00.208823700',@_DocDate2='2026-07-31 00:00:00.208823708',@_nUserId=default,@_LangId=0,@_DefinitionTableName='B10CheckAsset2',@_ConsolCode=default,@_Not_ConsolCode=default,@_Not_BranchCode=default,@_Not_RouteCode=default,@_BranchCode1=default,@_Not_BranchCode1=default,@_Not_BranchCode1Detail=default,@_CheckType=default,@_ReportType=default,@_BranchCode='I01',@_CurrencyCode0='VND',@_LAYOUT_XML=@p17 output,@_StrTime=@p18 output,@_Test=default,@_NewVer=1,@_BranchReportId=default
 