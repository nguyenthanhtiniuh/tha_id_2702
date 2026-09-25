USE B10THACOID
GO


SELECT * FROM b00lookup WHERE lookupkey like 'Asset%'
SELECT * FROM b00lookup WHERE lookupkey like 'DocStatus%'


--
SELECT *
FROM B00FieldList
WHERE Table_Name LIKE 'B20Asset%'

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