USE B10THACOID
GO

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
FROM B10THACOID.dbo.B00FieldList_20260925


TRUNCATE TABLE B00FieldList
SET IDENTITY_INSERT dbo.B00FieldList ON;
EXEC dbo.usp_sys_Append @_TableSource = 'B00FieldList_20260925' -- nvarchar(128)
                      , @_TableDestination = 'B00FieldList'     -- nvarchar(128)


SELECT *
FROM B10THACOID.dbo.B00FieldList