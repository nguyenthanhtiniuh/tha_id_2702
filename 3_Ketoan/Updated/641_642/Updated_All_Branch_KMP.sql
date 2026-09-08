--SELECT * FROM I23_KMP_New

UPDATE I23_KMP_New
SET KMP_new = TRIM(KMP_new)
WHERE KMP_new IS NOT NULL
------------------------------
UPDATE I23_KMP_New
SET Stt = TRIM(Stt)
WHERE Stt IS NOT NULL
------------------------------
UPDATE I23_KMP_New
SET RowId = TRIM(RowId)
WHERE RowId IS NOT NULL
------------------------------
DROP TABLE IF EXISTS #tbl
SELECT kmp.KMP_new,
       kmp.Stt,
       kmp.RowId,
       ca.Id AS ExpenseCatgId
INTO #tbl
FROM B10THACOIDACC.dbo.I23_KMP_New AS kmp
    LEFT JOIN B10THACOID_Data.dbo.B20ExpenseCatg AS ca
        ON kmp.KMP_new = ca.Code
------------------------------
DECLARE @_DataCode VARCHAR(4) = ''
DECLARE @_BranchCode VARCHAR(3) = 'I23'
SELECT TOP 1
       @_DataCode = DataCode
FROM dbo.B00Branch AS bt
WHERE BranchCode = @_BranchCode;
------------------------------
DROP TABLE IF EXISTS #tbl_Ct0_TableName_Branch;
WITH cte_dmct
AS (SELECT DISTINCT
           doccode
    FROM dbo.B32002GeneralLedger
    WHERE RowId IN
          (
              SELECT RowId FROM #tbl
          ))
SELECT REPLACE(Ct0_TableName, '0', @_DataCode) AS Ct0_TableName_Branch,
       *
INTO #tbl_Ct0_TableName_Branch
FROM dbo.B00DmCt
WHERE Ma_Ct IN
      (
          SELECT * FROM cte_dmct
      )
------------------------------------ 
DECLARE @_Tbl_Check TABLE
(
    Account NVARCHAR(24)
)
------------------------------
DECLARE @_StrExec_GeneralLedger NVARCHAR(MAX) = ''
SELECT @_StrExec_GeneralLedger
    = ' UPDATE ct0
SET ct0.ExpenseCatgId = t.ExpenseCatgId
FROM ' + REPLACE('B30GeneralLedger', '0', @_DataCode)
      + ' AS ct0
     INNER JOIN #tbl AS t ON ct0.Stt=t.Stt AND ct0.RowId=t.RowId
WHERE ct0.RowId IN (SELECT RowId FROM #tbl) 
 AND
      (
          (
              (account LIKE ''641%'')
              OR (account LIKE ''642%'')
          )
          OR (
          (
              (crspaccount LIKE ''641%'')
              OR crspaccount LIKE ''642%''
          )
             )
      )
; '
------------------------------
--PRINT @_StrExec_GeneralLedger
EXEC (@_StrExec_GeneralLedger)
------------------------------
DECLARE @_StrExec NVARCHAR(MAX) = ''
SELECT @_StrExec
    = STRING_AGG(
                    'UPDATE ct0
SET ct0.ExpenseCatgId=t.ExpenseCatgId
FROM ' + Ct0_TableName_Branch
                    + ' AS ct0
     INNER JOIN #tbl AS t ON ct0.Stt=t.Stt AND ct0.RowId=t.RowId
WHERE ct0.RowId IN(SELECT RowId FROM #tbl) ;' + CHAR(13),
                    ' ' + CHAR(13)
                )
FROM #tbl_Ct0_TableName_Branch
------------------------------
--PRINT @_StrExec
EXEC (@_StrExec)
------------------------------
DROP TABLE IF EXISTS #tbl,
                     #tbl_Ct0_TableName_Branch
RETURN