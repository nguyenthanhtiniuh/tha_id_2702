USE B10THACOID
GO

SELECT * FROM b00lookup WHERE lookupkey LIKE 'Asset%'
--
SELECT * FROM B00FieldList WHERE Table_Name LIKE 'B20Asset%'

SELECT * FROM B00FieldList WHERE Table_Name LIKE 'B3%TaxDetail%'



DROP TABLE IF EXISTS [#tableName];

CREATE TABLE [#tableName] (
    [MasterTable]	VARCHAR(512),
    [MasterField]	VARCHAR(512),
    [Table_Name]	VARCHAR(512),
    [Field_Name]	VARCHAR(512),
    [Comma_Separated]	VARCHAR(512),
    [ParentTable_]	VARCHAR(512),
    [ParentKey_]	VARCHAR(512),
    [ChildKey_]	VARCHAR(512)
);

INSERT INTO [#tableName] ([MasterTable], [MasterField], [Table_Name], [Field_Name], [Comma_Separated], [ParentTable_], [ParentKey_], [ChildKey_]) VALUES
    ('B20Customer', 'Id', 'B30TaxDetail', 'CustomerId', '0', '', '', '');

    EXEC dbo.usp_sys_Append @_TableSource = '#tableName'          -- nvarchar(128)
                      , @_TableDestination = 'B00FieldList'     -- nvarchar(128)

SELECT * FROM B00FieldList WHERE MasterTable LIKE '%B20Customer%%' ORDER BY ID DESC 

--MasterTable	MasterField	Table_Name	Field_Name	Comma_Separated	ParentTable_	ParentKey_	ChildKey_	Id	CreatedBy	CreatedAt	ModifiedBy	ModifiedAt



--ke hoach nop thue 

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
WHERE MasterTable LIKE '%B20ChartOfAccount%'
      --OR Table_Name LIKE '%asset%'
      AND Field_Name LIKE 'account'
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
WHERE Table_Name LIKE 'B3%TaxDetail'



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