--lấy úuser theo đơn vị
DROP TABLE IF EXISTS #PermissionBranch_User
SELECT pb.Id, pb.UserId, pb.RoleId, pb.BranchCode, ul.UserName, ul.IsGroup
INTO #PermissionBranch_User
FROM dbo.B00PermissionBranch AS pb
     LEFT JOIN dbo.B00UserList AS ul ON pb.UserId=ul.Id
WHERE pb.BranchCode='I04' AND ul.IsActive=1 AND ul.IsGroup=0
ORDER BY ul.IsGroup DESC

--lấy úuser theo đơn vị là user trong các nhóm 
--
DROP TABLE IF EXISTS #PermissionBranch_GroupUser
SELECT pb.Id, pb.UserId, pb.RoleId, pb.BranchCode, ul.UserName, ul.IsGroup
INTO #PermissionBranch_GroupUser
FROM dbo.B00PermissionBranch AS pb
     LEFT JOIN dbo.B00UserList AS ul ON pb.UserId=ul.Id
WHERE pb.BranchCode='I04' AND ul.IsActive=1 AND ul.IsGroup=1
ORDER BY ul.IsGroup DESC

------------

SELECT * FROM #PermissionBranch_User

SELECT * FROM #PermissionBranch_GroupUser
;
WITH temp  AS (SELECT Id, ParentId, 0 AS aLevel, UserName, IsGroup,BranchCode,BranchList,BranchNewList
                                                       FROM dbo.B00UserList
                                                       WHERE UserName='KT_ID'
                                                       UNION ALL
                                                       SELECT b.Id, b.ParentId, a.aLevel, b.UserName, b.IsGroup,b.BranchCode,b.BranchList,b.BranchNewList
                                                       FROM temp AS a, dbo.B00UserList AS b
                                                       WHERE a.id=b.ParentId)
SELECT * 
FROM temp AS b
WHERE	b.ParentId IN(SELECT UserId FROM #PermissionBranch_GroupUser)
	OR	b.id IN(SELECT UserId FROM #PermissionBranch_User)
ORDER BY b.IsGroup DESC, b.ParentId ASC, b.UserName ASC
-----------
--RETURN
--SELECT BranchCode, BranchName, TaxCode, Tel, Ws_Id, DataCode
--FROM dbo.B00Branch

--SELECT * FROM vB00UserList_Explore 