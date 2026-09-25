USE B10THACOIDACC
GO
DROP TABLE IF EXISTS #T
SELECT MasterTable
     , MasterField
     , Table_Name
     , Field_Name
     , Comma_Separated
     , ParentTable_
     , ParentKey_
     , ChildKey_
     , Id
     , CreatedBy
     , CreatedAt
     , ModifiedBy
     , ModifiedAt
INTO #T
FROM B10THACOID.dbo.B00FieldList

TRUNCATE TABLE B00FieldList
SET IDENTITY_INSERT dbo.B00FieldList ON;

EXEC dbo.usp_sys_Append @_TableSource = '#T'                -- nvarchar(128)
                      , @_TableDestination = 'B00FieldList' -- nvarchar(128)

SELECT *
FROM B00FieldList
SELECT *
FROM B10THACOIDACC.dbo.B00FieldList