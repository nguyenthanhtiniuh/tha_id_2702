DECLARE @_DataCode VARCHAR(4) = ''
DECLARE @_BranchCode VARCHAR(3) = 'I14'
-------------------------------------
DROP TABLE IF EXISTS #tableName;

CREATE TABLE #tableName
(
    KMP_NEW VARCHAR(512)
  , STT VARCHAR(512)
  , ROWID VARCHAR(512)
);

INSERT INTO #tableName
(
    KMP_NEW
  , STT
  , ROWID
)
VALUES
('C0505', 'I140008233', 'I140022719PK')
, ('C0505', 'I140010753NM', 'I140044767NM')
, ('C0505', 'I140012065', 'I140058603PK')
, ('C0505', 'I140016175NM', 'I140076779NM')
, ('C0505', 'I140027049NM', 'I140128493NM')
, ('C0505', 'I140033911NM', 'I140168513NM')
, ('C0505', 'I140043285', 'I140224081PK')
, ('C0505', 'I140049505', 'I147354235NM')
, ('C0505', 'I140051695', 'I140269139PK')
, ('C0505', 'I140006819', 'I146790409NM')
, ('C0505', 'I140006881', 'I146791307NM')
, ('C0505', 'I140008235', 'I140022725PK')
, ('C0505', 'I140010339', 'I146879137NM')
, ('C0505', 'I140010501', 'I146883435NM')
, ('C0505', 'I140010753NM', 'I140044769NM')
, ('C0505', 'I140016175NM', 'I140076781NM')
, ('C0505', 'I140016175NM', 'I140076783NM')
, ('C0505', 'I140016501', 'I146974799NM')
, ('C0505', 'I140016511', 'I146974991NM')
, ('C0505', 'I140027049NM', 'I140128497NM')
, ('C0505', 'I140027049NM', 'I140128495NM')
, ('C0505', 'I140027335', 'I147112903NM')
, ('C0505', 'I140027335', 'I147112901NM')
, ('C0505', 'I140027625', 'I147124311NM')
, ('C0505', 'I140027627', 'I147124321NM')
, ('C0505', 'I140027641', 'I147124335NM')
, ('C0505', 'I140033911NM', 'I140168517NM')
, ('C0505', 'I140033911NM', 'I140168515NM')
, ('C0505', 'I140033971', 'I147176223NM')
, ('C0505', 'I140033975', 'I147176233NM')
, ('C0505', 'I140041781', 'I147269167NM')
, ('C0505', 'I140041787', 'I147269175NM')
, ('C0505', 'I140049837', 'I147364491NM')
, ('C0505', 'I140049989', 'I147372437NM');
DROP TABLE IF EXISTS #tbl
SELECT kmp.KMP_NEW
     , kmp.STT
     , kmp.ROWID
     , ca.Id AS ExpenseCatgId
INTO #tbl
FROM #tableName                                  AS kmp
    LEFT JOIN B10THACOID_Data.dbo.B20ExpenseCatg AS ca
        ON kmp.KMP_NEW = ca.Code

--SELECT * FROM #tbl RETURN 
------------------------------ 
UPDATE #tableName
SET KMP_NEW = TRIM(KMP_NEW)
WHERE KMP_NEW IS NOT NULL
------------------------------
UPDATE #tableName
SET STT = TRIM(STT)
WHERE STT IS NOT NULL
------------------------------
UPDATE #tableName
SET ROWID = TRIM(ROWID)
WHERE ROWID IS NOT NULL
------------------------------
SELECT TOP (1)
       @_DataCode = DataCode
FROM dbo.B00Branch AS bt
WHERE BranchCode = @_BranchCode
ORDER BY BranchCode ASC
------------------------------
DROP TABLE IF EXISTS #tbl_Ct0_TableName_Branch;
;WITH cte_dmct
AS (SELECT TOP (0)
           doccode
    FROM dbo.B30GeneralLedger
    WHERE RowId IN
          (
              SELECT ROWID FROM #tbl
          ))
SELECT REPLACE(Ct0_TableName, '0', @_DataCode) AS Ct0_TableName_Branch
INTO #tbl_Ct0_TableName_Branch
FROM dbo.B00DmCt
WHERE Ma_Ct IN
      (
          SELECT * FROM cte_dmct
      )
-------------------------------------
DECLARE @_StrExec NVARCHAR(MAX) = ''
SELECT @_StrExec
    = ';WITH cte_dmct
AS (SELECT DISTINCT DocCode FROM dbo.B3' + @_DataCode
      + 'GeneralLedger WHERE RowId IN ( SELECT rowid FROM #tbl )) SELECT  Ct0_TableName  AS Ct0_TableName_Branch  
FROM B10THACOID.dbo.B00DmCt WHERE Ma_Ct IN ( SELECT DocCode FROM cte_dmct) '
-------------------------------------
INSERT INTO #tbl_Ct0_TableName_Branch
EXEC (@_StrExec)
------------------------------------- 
UPDATE #tbl_Ct0_TableName_Branch
SET Ct0_TableName_Branch = REPLACE(Ct0_TableName_Branch, '0', @_DataCode)
------------------------------------ 
DECLARE @_Tbl_Check TABLE
(
    Account NVARCHAR(24)
)
------------------------------
DECLARE @_StrExec_GeneralLedger NVARCHAR(MAX) = ''
SELECT @_StrExec_GeneralLedger
    = ' UPDATE ct0 SET ct0.ExpenseCatgId = t.ExpenseCatgId
FROM ' + REPLACE('B30GeneralLedger', '0', @_DataCode)
      + ' AS ct0 INNER JOIN #tbl AS t ON ct0.Stt=t.Stt AND ct0.RowId=t.RowId
WHERE ct0.RowId IN (SELECT RowId FROM #tbl) 
 AND ( ( (account LIKE ''641%'') OR (account LIKE ''642%'') ) OR ( ( (crspaccount LIKE ''641%'') OR crspaccount LIKE ''642%'' ) ) ) ; '
------------------------------
--PRINT @_StrExec_GeneralLedger
--RETURN
EXEC (@_StrExec_GeneralLedger)
------------------------------
SELECT @_StrExec
    = STRING_AGG(
                    'UPDATE ct0 SET ct0.ExpenseCatgId=t.ExpenseCatgId
					FROM ' + Ct0_TableName_Branch
                    + ' AS ct0
						INNER JOIN #tbl AS t ON ct0.Stt=t.Stt AND ct0.RowId=t.RowId
							WHERE ct0.RowId IN(SELECT RowId FROM #tbl) ;' + CHAR(13)
                  , ' ' + CHAR(13)
                )
FROM #tbl_Ct0_TableName_Branch
------------------------------
--PRINT @_StrExec RETURN
EXEC (@_StrExec)
------------------------------
DROP TABLE IF EXISTS #tbl
                   , #tbl_Ct0_TableName_Branch
RETURN

DROP TABLE IF EXISTS #tableName