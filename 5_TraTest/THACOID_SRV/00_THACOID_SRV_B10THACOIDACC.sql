USE B10THACOIDACC
GO
EXEC dbo._CreateTableByBranch @_TableName = 'vB20Asset_9' -- varchar(128)
EXEC dbo._CreateTableByBranch @_TableName = 'vB20Asset_ExploreFuture' -- varchar(128)
EXEC dbo._CreateTableByBranch @_TableName = 'vB20Asset_9' -- varchar(128)
EXEC dbo._CreateTableByBranch @_TableName = 'vB20Asset_ToolInstrument_Future' -- varchar(128)                   
SELECT * FROM sys.views WHERE name LIKE 'vB2%Asset_9'
--vB22021Asset_9


--gd2
EXEC dbo._CreateTableByBranch @_TableName = 'vB30LCDoc_Explore' -- varchar(128)   