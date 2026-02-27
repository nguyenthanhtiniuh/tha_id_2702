CREATE PROCEDURE [dbo].[usp_B20_ConvertCodeAsset]
	@_BranchCode VARCHAR(3) = 'I23'
AS
BEGIN
SET NOCOUNT ON;

DECLARE @_Id INT = NULL
	,@_Ws_Id VARCHAR(3) = ''
	,@_TableName VARCHAR(64) = ''
	,@_DocName VARCHAR(64) = ''
	,@_DataCode VARCHAR(16) = ''
	,@_nl CHAR(1) = CHAR(13)
	,@_StrExec VARCHAR(4000) = ''
	,@_Declare VARCHAR(4000) = ''
	,@_TableSource VARCHAR(128) = ''
	,@_BeginedAt DATETIME = NULL
	,@_message NVARCHAR(MAX) = N''
	,@_LangId TINYINT = 0
	,@_nUserId INT = 0
	,@_ParentId INT = 0
	,@_CheckParentId TINYINT = 0

SELECT @_BeginedAt = GETDATE()

DROP TABLE

IF EXISTS #tbl
	SELECT m.Id
		,m.ParentId
		,m.IsGroup
		,m.BranchCode
		,m.Code
		,m.AssetCodeMapToB10
		,m.DeptCodeOld
		,m.DeptCodeMapToB10
		,m.ProfitCenterCodeOld
		,m.ProfitCenterCodeMapToB10
		,m.ExpenseCatgCodeOld
		,m.ExpenseCatgCodeMapToB10
		,m.StageCodeOld
		,m.StageCodeMapToB10
		,CAST(NULL AS INT) AS AssetId
		,CAST(NULL AS TINYINT) AS TypeAsset
		,TerritoryCodeOld
		,TerritoryCodeMapToB10
		,ProductCodeOld
		,ProductCodeMapToB10
	INTO #tbl
	FROM B20MappingAsset m
	WHERE m.BranchCode = @_BranchCode
		AND ISNULL(IsActive, 0) = 1
		AND Type IN (
			'TS'
			,'CCDC'
			)

SELECT @_DocName = 'B20Asset'

BEGIN
	SELECT @_DataCode = DataCode
	FROM dbo.B00Branch
	WHERE BranchCode = @_BranchCode
END

SELECT @_TableSource = REPLACE(@_DocName, 'B20', 'B2' + @_DataCode)

SELECT @_StrExec = ' UPDATE #tbl SET AssetId = ASS.Id
								,TypeAsset=ass.Type FROM #tbl T LEFT JOIN ' + @_TableSource + ' ASS ON t.Code = ASS.Code ; ' + @_nl

EXEC (@_StrExec)

-- chạy chuyển đổi mã cũ qua mã mới  
DROP TABLE

IF EXISTS #tbl_AssetNew
	SELECT AssetId
		,Code
		,AssetCodeMapToB10
		,TypeAsset
	INTO #tbl_AssetNew
	FROM #tbl
	WHERE ISNULL(AssetCodeMapToB10, '') <> ''

--SELECT * FROM #tbl_AssetNew
SELECT *
FROM #tbl_AssetNew

SELECT @_StrExec = ''

SELECT @_StrExec = '	UPDATE ' + @_TableSource + '  
	SET Code = t.AssetCodeMapToB10      
	FROM ' + @_TableSource + ' ASS INNER JOIN #tbl_AssetNew   t ON t.AssetId = ASS.Id   
		  AND ASS.Code  <>  t.AssetCodeMapToB10      
	WHERE ass.Id IN (SELECT AssetId FROM #tbl_AssetNew )    
' + @_nl

--EXEC (@_StrExec)

PRINT @_StrExec
END 