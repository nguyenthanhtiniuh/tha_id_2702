DROP TABLE IF EXISTS #tbl
SELECT TOP 1
       MasterTable
     , MasterField
     , Table_Name
     --, REPLACE(Table_Name, '0', DataCode) AS Table_Name
     , Field_Name
INTO #tbl
FROM B00FieldList AS fl
--, B00Branch AS br
WHERE MasterTable LIKE '%B20Customer%'
      --OR Table_Name LIKE '%asset%'
      AND Field_Name LIKE 'CustomerId'
ORDER BY fl.Id DESC

UPDATE #tbl
SET Table_Name = 'B30TaxDetail'

DROP TABLE IF EXISTS #T_Append
SELECT fl.MasterTable
     , fl.MasterField
     , REPLACE(Table_Name, '0', br.DataCode) AS Table_Name
     , fl.Field_Name
INTO #T_Append
FROM #tbl AS fl
   , B00Branch AS br
WHERE br.BranchCode <> 'T00'
ORDER BY br.DataCode DESC



EXEC dbo.usp_sys_Append @_TableSource = '#T_Append'         -- nvarchar(128)
                      , @_TableDestination = 'b00fieldlist' -- nvarchar(128)

SELECT *
FROM B00FieldList
WHERE Table_Name LIKE 'B3%TaxDetail' AND Field_Name LIKE 'CustomerId'
--SELECT *
--FROM #tbl

------------

DROP TABLE IF EXISTS #T_CLASS
SELECT *
INTO #T_CLASS
FROM TO101_B7ACC.B7_THACO.DBO.B20CLASS
WHERE PARENTCODE = 'TCType'

ALTER TABLE #T_CLASS DROP COLUMN Id

--EXEC dbo.usp_sys_Append @_TableSource = '#T_CLASS'          -- nvarchar(128)
--                      , @_TableDestination = 'B20CLASS'     -- nvarchar(128)

DROP TABLE IF EXISTS #T_CLASS