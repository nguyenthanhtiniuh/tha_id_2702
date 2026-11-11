USE B10THACOIDACC_Data
GO
DECLARE @_DataCode   VARCHAR(4) = ''
      , @_BranchCode VARCHAR(3) = 'I21'
-------------------------------------
DROP TABLE IF EXISTS #tableName;
CREATE TABLE #tableName
(
    KUNN NVARCHAR(128)
  , Stt NVARCHAR(128)
  , RowId NVARCHAR(16)
);


DROP TABLE IF EXISTS #tableName1
CREATE TABLE #tableName1
(
    STT VARCHAR(512)
  , ROWID VARCHAR(512)
  , DOCNO VARCHAR(512)
  , KUV VARCHAR(512)
  , KEYKUV VARCHAR(512)
);

INSERT INTO #tableName1
(
    STT
  , ROWID
  , DOCNO
  , KUV
  , KEYKUV
)
VALUES
('I210501797', 'I212267801BN', 'BPSTBV0001-2609-0271', 'LD2610700342', 'I212251348LC')
, ('I210501797', 'I212267801BN', 'BPSTBV0001-2609-0271', 'LD2610700342', 'I212251348LC')
, ('I210505203', 'I212279303BN', 'BPHDBV0009-2609-0008', 'KUNN50', 'I212251146LC')
, ('I210505203', 'I212279303BN', 'BPHDBV0009-2609-0008', 'KUNN50', 'I212251146LC')
, ('I210505301', 'I212279979BN', 'BPHDBV0009-2609-0047', 'KUNN47', 'I212250856LC')
, ('I210505301', 'I212279979BN', 'BPHDBV0009-2609-0047', 'KUNN47', 'I212250856LC')
, ('I210505303', 'I212279981BN', 'BPHDBV0009-2609-0049', 'KUNN48', 'I212251052LC')
, ('I210505303', 'I212279981BN', 'BPHDBV0009-2609-0049', 'KUNN48', 'I212251052LC');

INSERT INTO #tableName
(
    KUNN
  , Stt
  , RowId
)
SELECT KUV
     , STT
     , ROWID
FROM #tableName1

 
------------------------------
UPDATE #tableName
SET KUNN = TRIM(KUNN)
  , Stt = TRIM(Stt)
  , RowId = TRIM(RowId)
------------------------------
DROP TABLE IF EXISTS #tbl
SELECT kmp.*
     , ca.BizDocId AS BizDocId_LC
INTO #tbl
FROM #tableName                AS kmp
    LEFT JOIN dbo.B32013BizDoc AS ca
        ON kmp.KUNN = (ca.DocNo)

	 
------------------------------
SELECT TOP (1)
       @_DataCode = DataCode
FROM dbo.B00Branch AS bt
WHERE BranchCode = @_BranchCode
ORDER BY BranchCode ASC
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
DECLARE @_StrExec NVARCHAR(MAX) = ''
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
FROM ' + REPLACE('B30GeneralLedger', '0', @_DataCode)
      + ' AS ct0 INNER JOIN #tbl AS t ON ct0.Stt=t.Stt AND ct0.RowId=t.RowId
WHERE ct0.RowId IN (SELECT RowId FROM #tbl) AND ( ct0.DebitAccount LIKE ''341%'' ) ; '
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
FROM ' + REPLACE('B30AccDocOther', '0', @_DataCode)
      + '  AS ct0
    INNER JOIN #tbl    AS t
        ON ct0.Stt = t.Stt
           AND ct0.RowId = t.RowId
WHERE ct0.RowId IN
      (
          SELECT RowId FROM #tbl
      )
      AND DEBITaccount LIKE ''341%'''
-------------
EXEC (@_StrExec)
-------------
SELECT @_StrExec
    = '
UPDATE ct0
SET ct0.CreditBizDocId_LC = t.BizDocId_LC
FROM ' + REPLACE('B30AccDocOther', '0', @_DataCode)
      + ' AS ct0
    INNER JOIN #tbl    AS t
        ON ct0.Stt = t.Stt
           AND ct0.RowId = t.RowId
WHERE ct0.RowId IN
      (
          SELECT RowId FROM #tbl
      )
      AND Creditaccount LIKE ''341%'''
------------------------------ 
EXEC (@_StrExec)
------------------------------
DROP TABLE IF EXISTS #tbl
                   , #tbl_Ct0_TableName_Branch
                   , #tableName