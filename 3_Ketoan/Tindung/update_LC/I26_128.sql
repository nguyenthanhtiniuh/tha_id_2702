USE B10THACOIDACC_Data
GO
DECLARE @_DataCode   VARCHAR(4) = ''
      , @_BranchCode VARCHAR(3) = 'I26'
------------------------------------- 
SELECT TOP (1)
       @_DataCode = DataCode
FROM dbo.B00Branch AS bt
WHERE BranchCode = @_BranchCode
ORDER BY BranchCode ASC
------------------------------------- 

DROP TABLE IF EXISTS #tableName;

CREATE TABLE #tableName
(
    KUNN NVARCHAR(128)
  , STT NVARCHAR(16)
  , ROWID NVARCHAR(16)
);

BEGIN


    INSERT INTO #tableName
    (
        KUNN
      , ROWID
      , STT
    )
    VALUES
    ('16/2025/TACB-IND', 'I260178761BC', 'I260031407')
  , ('16/2025/TACB-IND', 'I260178821BC', 'I260031437')
  , ('18/2025/TACB-IND', 'I260198653BC', 'I260034395')
  , ('17/2025/TACB-IND', 'I260220287BC', 'I260037881')
  , ('01/2026/TACB-IND', 'I260232425BC', 'I260041339')
  , ('15/2025/TACB-IND', 'I260248687BC', 'I260043087')
  , ('15/2025/TACB-IND', 'I260248693BC', 'I260043093')
  , ('15/2025/TACB-IND', 'I260249389BC', 'I260043125')
  , ('08/2026/TACB-IND', 'I260286235BC', 'I260050971')
  , ('18/2025/TACB-IND', 'I260286223BC', 'I260050971')
  , ('01/2026/TACB-IND', 'I260321121BC', 'I260056805')
  , ('04/2026/TACB-IND', 'I260321369BC', 'I260056833')
  , ('01/2026/TACB-IND', 'I260327617BC', 'I260057893')
  , ('08/2026/TACB-IND', 'I260327619BC', 'I260057895')
  , ('11/2026/TACB-IND', 'I260327623BN', 'I260057899')
  , ('11/2026/TACB-IND', 'I260327621BN', 'I260057897')
  , ('01/2026/TACB-IND', 'I260327597BC', 'I260057873')
  , ('01/2026/TACB-IND', 'I260321411BC', 'I260056861')
  , ('01/2026/TACB-IND', 'I260321445BC', 'I260056867')
  , ('04/2026/TACB-IND', 'I260321463BC', 'I260056877')
  , ('01/2026/TACB-IND', 'I260321485BC', 'I260056883')
  , ('23/2025/TACB-IND', 'I260343175BC', 'I260060183')
  , ('12/2026/TACB-IND', 'I260327515BN', 'I260057825')
  , ('12/2026/TACB-IND', 'I260327517BN', 'I260057827')
  , ('12/2026/TACB-IND', 'I260327519BN', 'I260057829')
  , ('13/2026/TACB-IND', 'I260327713BN', 'I260057955')
  , ('14/2026/TACB-IND', 'I260327715BN', 'I260057957')
  , ('23/2025/TACB-IND', 'I260338575BC', 'I260059811')
  , ('01/2026/TACB-IND', 'I260338577BC', 'I260059813')
  , ('01/2026/TACB-IND', 'I260338579BC', 'I260059815')
  , ('04/2026/TACB-IND', 'I260338581BC', 'I260059817')
  , ('15/2026/TACB-IND', 'I260338583BN', 'I260059823')
  , ('15/2026/TACB-IND', 'I260338585BN', 'I260059827')
  , ('15/2026/TACB-IND', 'I260338587BN', 'I260059831')
  , ('04/2026/TACB-IND', 'I260336197BC', 'I260059401')
  , ('16/2026/TACB-IND', 'I260336201BN', 'I260059407')
  , ('16/2026/TACB-IND', 'I260336203BN', 'I260059409')
  , ('23/2025/TACB-IND', 'I260369417BC', 'I260065575')
  , ('23/2025/TACB-IND', 'I260365071BC', 'I260064855')
  , ('04/2026/TACB-IND', 'I260365081BC', 'I260064871')
  , ('04/2026/TACB-IND', 'I260369035BC', 'I260065493')
  , ('17/2025/TACB-IND', 'I260369201BC', 'I260065533')
  , ('16/2025/TACB-IND', 'I260375509BC', 'I260066555')
  , ('01/2026/TACB-IND', 'I260375511BC', 'I260066557')
  , ('01/2026/TACB-IND', 'I260375513BC', 'I260066559')
  , ('04/2026/TACB-IND', 'I260375515BC', 'I260066561')
  , ('04/2026/TACB-IND', 'I260375519BC', 'I260066563')
  , ('04/2026/TACB-IND', 'I260375523BC', 'I260066565')
  , ('16/2025/TACB-IND', 'I260375529BC', 'I260066567')
  , ('01/2026/TACB-IND', 'I260411743BC', 'I260071559')
  , ('23/2025/TACB-IND', 'I260418997BC', 'I260072771')
  , ('04/2026/TACB-IND', 'I260421859BC', 'I260073419');

END




------------------------------
UPDATE #tableName
SET KUNN = TRIM(KUNN)
  , STT = TRIM(STT)
  , ROWID = TRIM(ROWID)
------------------------------
DROP TABLE IF EXISTS #tbl
SELECT TOP 0
       kmp.*
     , ca.BizDocId AS BizDocId_LC
INTO #tbl
FROM #tableName             AS kmp
    LEFT JOIN dbo.B30BizDoc AS ca
        ON kmp.KUNN = (ca.DocNo)
---
DECLARE @_StrExec NVARCHAR(MAX) = ''
SELECT @_StrExec = '
UPDATE t
SET t.STT = ge.STT
FROM #tableName                 AS t
    INNER JOIN b3' + @_DataCode + 'GeneralLedger AS ge
        ON t.ROWID = ge.ROWID		
'
EXEC (@_StrExec)


----


SELECT @_StrExec
    = '
INSERT INTO #tbl
SELECT kmp.*
     , ca.BizDocId AS BizDocId_LC 
FROM #tableName                AS kmp
    LEFT JOIN dbo.B3' + @_DataCode
      + 'BizDoc AS ca
        ON kmp.KUNN = (ca.DocNo) AND ca.DocCode = ''LC'' and ca.IsActive = 1 
		WHERE ca.BizDocId IS NOT NULL '
EXEC (@_StrExec)

 

------------------------------
--SELECT * FROM #tableName RETURN
------------------------------
IF @_DataCode = ''
    RETURN
------------------------------
DROP TABLE IF EXISTS #tbl_Ct0_TableName_Branch;
SELECT TOP 0
       REPLACE(Ct0_TableName, '0', @_DataCode) AS Ct0_TableName_Branch
     , Ma_Ct
INTO #tbl_Ct0_TableName_Branch
FROM dbo.B00DmCt
-------------------------------------
SELECT @_StrExec
    = ' SELECT Ct0_TableName AS Ct0_TableName_Branch,Ma_Ct
FROM dbo.B00DmCt AS dmct
WHERE Ma_Ct IN
      (
          SELECT DISTINCT DocCode FROM dbo.B3' + @_DataCode
      + 'GeneralLedger AS ge WHERE ge.Stt IN ( SELECT t.Stt FROM #tbl AS t ))'
-------------------------------------
INSERT INTO #tbl_Ct0_TableName_Branch
EXEC (@_StrExec)
------------------------------------- 
UPDATE #tbl_Ct0_TableName_Branch
SET Ct0_TableName_Branch = REPLACE(Ct0_TableName_Branch, '0', @_DataCode)
------------------------------------ 
DECLARE @_StrExec_GeneralLedger NVARCHAR(MAX) = ''
SELECT @_StrExec_GeneralLedger
    = ' UPDATE ct0 SET ct0.BizDocId_LC = ISNULL(t.BizDocId_LC,ct0.BizDocId_LC)
FROM ' + REPLACE(N'B30GeneralLedger', '0', @_DataCode)
      + ' AS ct0 INNER JOIN #tbl AS t ON ct0.Stt=t.Stt AND ct0.RowId=t.RowId
WHERE ct0.RowId IN (SELECT RowId FROM #tbl) AND ( ct0.account LIKE ''128%'' ) ; '
------------------------------ 
EXEC (@_StrExec_GeneralLedger)
------------------------------
SELECT @_StrExec
    = STRING_AGG(
                    'UPDATE ct0 SET ct0.BizDocId_LC = t.BizDocId_LC
					FROM ' + Ct0_TableName_Branch
                    + ' AS ct0
						INNER JOIN #tbl AS t ON ct0.Stt=t.Stt AND ct0.RowId=t.RowId
							WHERE ct0.RowId IN (SELECT RowId FROM #tbl) ;' + CHAR(13)
                  , ' ' + CHAR(13)
                )
FROM #tbl_Ct0_TableName_Branch
WHERE Ma_Ct <> 'BT'
-------------
EXEC (@_StrExec)
-------------
SELECT @_StrExec
    = '
UPDATE ct0
SET ct0.DEBITBizDocId_LC = t.BizDocId_LC
FROM ' + REPLACE(N'B30AccDocOther', '0', @_DataCode)
      + '  AS ct0
    INNER JOIN #tbl    AS t
        ON ct0.Stt = t.Stt
           AND ct0.RowId = t.RowId
WHERE ct0.RowId IN
      (
          SELECT RowId FROM #tbl
      )
      AND DEBITaccount LIKE ''128%'''
-------------
EXEC (@_StrExec)
-------------
SELECT @_StrExec
    = '
UPDATE ct0
SET ct0.CreditBizDocId_LC = t.BizDocId_LC
FROM ' + REPLACE(N'B30AccDocOther', '0', @_DataCode)
      + ' AS ct0
    INNER JOIN #tbl    AS t
        ON ct0.Stt = t.Stt
           AND ct0.RowId = t.RowId
WHERE ct0.RowId IN
      (
          SELECT RowId FROM #tbl
      )
      AND Creditaccount LIKE ''128%'''
------------------------------ 
EXEC (@_StrExec)
------------------------------
DROP TABLE IF EXISTS #tbl
                   , #tbl_Ct0_TableName_Branch
                   , #tableName