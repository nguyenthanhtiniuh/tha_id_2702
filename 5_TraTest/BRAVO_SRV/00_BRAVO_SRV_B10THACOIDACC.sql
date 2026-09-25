USE B10THACOIDACC
GO


SELECT * FROM vB30Tax
--gd 1
EXEC dbo._CreateTableByBranch @_TableName = 'vB20Asset_9' -- varchar(128)
EXEC dbo._CreateTableByBranch @_TableName = 'vB20Asset_ExploreFuture' -- varchar(128)                   
EXEC dbo._CreateTableByBranch @_TableName = 'vB20Asset_9' -- varchar(128)                   
EXEC dbo._CreateTableByBranch @_TableName = 'vB20Asset_ToolInstrument_Future' -- varchar(128)     

--gd 2
EXEC dbo._CreateTableByBranch @_TableName = 'vB30LCDoc_Explore' -- varchar(128)                   


SELECT * FROM sys.views WHERE name LIKE 'vB2%Asset_9'
--vB22021Asset_9

SELECT * FROM vB22021Asset_ExploreFuture WHERE code LIKE 'zz%'

--