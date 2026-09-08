DROP TABLE IF EXISTS #tbl;
SELECT Stt AS RN,
       TRIM(Exp_Id) AS expenCode,
       TRIM(Stt2) AS Stt,
       TRIM(column4) AS RowId,
       ex.Id AS ExpenseCatgId
INTO #tbl
FROM B10THACOIDACC.dbo.I26_642 AS i
    INNER JOIN B20ExpenseCatg AS ex
        ON i.Exp_Id = ex.code;

--SELECT * FROM #tbl 

UPDATE acc
SET acc.ExpenseCatgId = t.ExpenseCatgId
FROM B32009AccDocPurchase1 AS acc
    INNER JOIN #tbl AS t
        ON acc.Rowid = t.RowId
WHERE acc.Rowid IN
      (
          SELECT RowId FROM #tbl
      );

UPDATE acc
SET acc.ExpenseCatgId = t.ExpenseCatgId
FROM B32009AccDocJournalEntry AS acc
    INNER JOIN #tbl AS t
        ON acc.Rowid = t.RowId
WHERE acc.Rowid IN
      (
          SELECT RowId FROM #tbl
      );

UPDATE acc
SET acc.ExpenseCatgId = t.ExpenseCatgId
FROM B32009GeneralLedger AS acc
    INNER JOIN #tbl AS t
        ON acc.Rowid = t.RowId
WHERE acc.Rowid IN
      (
          SELECT RowId FROM #tbl
      );

--UPDATE 
/*
B30AccDocPurchase1
B30AccDocJournalEntry
*/

SELECT *
FROM dbo.B32009GeneralLedger
WHERE RowId IN
      (
          SELECT RowId FROM #tbl
      );

DROP TABLE IF EXISTS #tbl;