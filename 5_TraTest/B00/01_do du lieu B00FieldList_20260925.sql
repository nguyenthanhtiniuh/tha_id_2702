USE B10THACOID;
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
FROM B10THACOID.dbo.B00FieldList_20260928;

IF EXISTS (SELECT * FROM B00FieldList_20260928)
BEGIN
    TRUNCATE TABLE B00FieldList;
    SET IDENTITY_INSERT dbo.B00FieldList ON;

	INSERT INTO B00FieldList ([Id],[MasterTable],[MasterField],[Table_Name],[Field_Name],[Comma_Separated],[ParentTable_],[ParentKey_],[ChildKey_],[CreatedBy],[CreatedAt],[ModifiedBy],[ModifiedAt]) 
	SELECT [Id],[MasterTable],[MasterField],[Table_Name],[Field_Name],[Comma_Separated],[ParentTable_],[ParentKey_],[ChildKey_],[CreatedBy],[CreatedAt],[ModifiedBy],[ModifiedAt] FROM B00FieldList_20260928

    --EXEC dbo.usp_sys_Append @_TableSource = 'B00FieldList_20260928' -- nvarchar(128)
    --                      , @_TableDestination = 'B00FieldList';    -- nvarchar(128)

END;


SELECT * FROM B10THACOID.dbo.B00FieldList;
SELECT * FROM B10THACOIDACC.dbo.B00FieldList;