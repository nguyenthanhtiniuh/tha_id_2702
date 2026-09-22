-- @DESCRIPTION: Chỉnh sửa thủ tục usp_sys_GetTablePermissionExprAll thay đổi cách lấy thuộc tính từ AppName (Bắt buộc)
-- @PROPERTY: Required
-- @CONDITION: SELECT 1

-- =============================================
-- Author:	Phạm Ngọc Sơn	
-- Create date: 11/09/2024
-- Description:	Trả về bảng dữ liệu phân quyền áp dụng với người dùng 
-- =============================================
ALTER PROCEDURE dbo.usp_sys_GetTablePermissionExprAll
	@_TableName AS VARCHAR(100),
	@_CommandKey AS CodeType = NULL,
	@_RoleTypeList AS VARCHAR(100) = NULL,
	@_GroupUserString AS VARCHAR(MAX) = NULL,
	@_RoleUserString AS VARCHAR(MAX) = NULL,
	@_RestrictedRoleType AS TINYINT = NULL,
	-- @_RestrictedRoleType: cách thức kiểm soát người dùng có vai trò 'Restricted Reading Data' (RoleType=3) dựa trên giá trị cột CreatedBy
	-- 0: chỉ đọc được dữ liệu public (CreatedBy=-1) và dữ liệu của bản thân tạo ra (CreatedBy=@_UserId)
	-- 1: chỉ đọc được dữ liệu public (CreatedBy=-1) và dữ liệu của những người dùng trong cùng nhóm tạo ra
	-- 2: chỉ đọc được dữ liệu public (CreatedBy=-1) và dữ liệu của những người dùng có cùng vai trò (RoleId) tạo ra
	-- 3: chỉ đọc được dữ liệu của bản thân tạo ra (CreatedBy=@_UserId)
	@_PermissionFlags AS INT = NULL,
	-- 0: All
	-- 1: NoOpen
	-- 2: NoEdit
	-- 4: NoDelete
	-- 8: NoRecall
	-- 16: NoAddNew
	@_FilterExprPattern AS NVARCHAR(128) = NULL,
	-- Khi lấy lên build Explorer/Editor trên Backend, cần phải có đánh dấu alias cột của bảng phân quyền
	@_IsBuildQuery AS BIT = 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Result TABLE (
		NoOpen nvarchar(MAX),
		NoEdit nvarchar(MAX),
		NoDelete nvarchar(MAX),
		NoRecall nvarchar(MAX),
		NoAddNew nvarchar(MAX)
	)

	-------------------------------------------------------------------------------------------------------------
	-- Trả về chuỗi biểu thức điều kiện loại bỏ những dữ liệu không có quyền 
	-- để dùng ở cuối mệnh đề WHERE khi SELECT một bảng dữ liệu
	-------------------------------------------------------------------------------------------------------------

	-- Lấy các thông tin của người dùng thông qua ApplicationName truyền từ Backend xuống
  DECLARE @userId AS int = dbo.ufn_sys_GetValueFromAppName('UserId', NULL),
	@branchCode AS VARCHAR(3) = dbo.ufn_sys_GetValueFromAppName('BranchCode', NULL),
	@platform AS VARCHAR(8) = dbo.ufn_sys_GetValueFromAppName('Platform', NULL),
	@roleScheduleId AS int = dbo.ufn_sys_GetValueFromAppName('StrRoleScheduleId', NULL),
	@userPortalId AS int = dbo.ufn_sys_GetValueFromAppName('UserPortalId', 0),
	@tableName varchar(100) = @_TableName, 
	@commandKey CodeType = @_CommandKey,
	@roleTypeList varchar(100) = @_RoleTypeList, 
	@groupUserString varchar(MAX) = @_GroupUserString,
	@roleUserString varchar(MAX) = @_RoleUserString, 
	@restrictedRoleType AS tinyint = ISNULL(@_RestrictedRoleType, 2), 
	@permissionFlags AS int = ISNULL(@_PermissionFlags, 0), 
	@filterExprPattern nvarchar(128) = ISNULL(@_FilterExprPattern, ''),
	@previewTable PermissionFilterExprTypeB10;

	DECLARE @prefix AS nvarchar(MAX) = '';	
	DECLARE @baseTableName varchar(100) = @tableName;

  DECLARE @isPortalPlatform BIT = IIF(@platform = 'Portal' AND @userPortalId > 0, 1, 0);
  DECLARE @portalId INT = 0;
  DECLARE @portalDetailId INT = 0;
  IF (@isPortalPlatform = 1)
  BEGIN
    SELECT 
      @portalId = PC.Id,
      @portalDetailId = PCD.Id
    FROM B08UserPortal U WITH (NOLOCK)
    INNER JOIN B08WebPortalConfigDetail PCD WITH (NOLOCK) ON U.PortalDetailId=PCD.Id 
    INNER JOIN B08WebPortalConfig PC WITH (NOLOCK) ON PCD.PortalId=PC.Id 
    WHERE U.Id = @userPortalId;
  END

	IF LEFT(@tableName, 1) = 'v' -- get base table name of view
	BEGIN
		DECLARE @pos AS int = CHARINDEX('_', @tableName);
		IF @pos > 1
			SET @baseTableName = SUBSTRING(@tableName, 2, @pos - 2);
		ELSE
			SET @baseTableName = SUBSTRING(@tableName, 2, LEN(@tableName) - 1);
	END;

	-- Nếu đăng nhập theo ủy quyền => chỉ load các roles của ủy quyền
	DECLARE @roleScheduleListTable TABLE
	(
		Id int
	);
	IF(@roleScheduleId > 0)
		INSERT INTO @roleScheduleListTable 
			SELECT RoleId 
				FROM [B00RoleScheduleDetail] WITH (NOLOCK) 
				WHERE RoleScheduleId = @roleScheduleId

	DECLARE @isAdminRole AS bit = 0, @isModeratorRole AS bit = 0, 
		@isRestrictedRole AS bit = 0, @isRestrictedCommand AS bit = 0,
		@isIgnoredCommandKey AS bit = 1, @isLayoutPermission AS bit = 0;
	
	-- Lấy danh sách các role
	IF ISNULL(@roleTypeList, '') = ''
	BEGIN
		DECLARE @RoleTable TABLE (RoleType tinyint);
    IF (@isPortalPlatform = 1)
    BEGIN
      -- Dùng bảng B08 khi là Portal
      IF EXISTS (SELECT TOP 1 1 FROM @roleScheduleListTable)
  		BEGIN
  			INSERT INTO @RoleTable
  				SELECT DISTINCT RoleType 
  					FROM B08RoleList WITH (NOLOCK)
  					WHERE IsActive = 1 AND Id IN (SELECT Id FROM @roleScheduleListTable);
  		END
  		ELSE
  		BEGIN
  			WITH cteUsers (Id, ParentId) AS
  			(
  				SELECT Id, ParentId
  					FROM [B08UserPortal] WITH (NOLOCK)
  					WHERE Id = @userId
  				UNION ALL
  				SELECT u.Id, u.ParentId
  					FROM [B08UserPortal] AS u WITH (NOLOCK) INNER JOIN
  					cteUsers ON u.Id = cteUsers.ParentId
  			)
  			INSERT INTO @RoleTable
  				SELECT DISTINCT rl.RoleType 
  					FROM B08UserRole AS ur WITH (NOLOCK) INNER JOIN 
  						cteUsers AS u ON u.Id = ur.UserId INNER JOIN 
  						B08RoleList AS rl WITH (NOLOCK) ON rl.Id = ur.RoleId
  					WHERE ur.IsActive = 1 AND rl.IsActive = 1;
  		END
    END
    ELSE
    BEGIN
      -- Dùng bảng B00 mặc định
      IF EXISTS (SELECT TOP 1 1 FROM @roleScheduleListTable)
  		BEGIN
  			INSERT INTO @RoleTable
  				SELECT DISTINCT RoleType 
  					FROM B00RoleList WITH (NOLOCK)
  					WHERE IsActive = 1 AND Id IN (SELECT Id FROM @roleScheduleListTable);
  		END
  		ELSE
  		BEGIN
  			WITH cteUsers (Id, ParentId) AS
  			(
  				SELECT Id, ParentId
  					FROM [B00UserList] WITH (NOLOCK)
  					WHERE Id = @userId
  				UNION ALL
  				SELECT u.Id, u.ParentId
  					FROM [B00UserList] AS u WITH (NOLOCK) INNER JOIN
  					cteUsers ON u.Id = cteUsers.ParentId
  			)
  			INSERT INTO @RoleTable
  				SELECT DISTINCT rl.RoleType 
  					FROM B00UserRole AS ur WITH (NOLOCK) INNER JOIN 
  						cteUsers AS u ON u.Id = ur.UserId INNER JOIN 
  						B00RoleList AS rl WITH (NOLOCK) ON rl.Id = ur.RoleId
  					WHERE ur.IsActive = 1 AND rl.IsActive = 1;
  		END
    END

		IF EXISTS (SELECT TOP (1) 1 FROM @RoleTable WHERE RoleType = 1)
			SET @isAdminRole = 1;
	
		IF EXISTS (SELECT TOP (1) 1 FROM @RoleTable WHERE RoleType = 4)
			SET @isModeratorRole = 1;

		IF EXISTS (SELECT TOP (1) 1 FROM @RoleTable WHERE RoleType = 3)
			SET @isRestrictedRole = 1;
		
		IF (@baseTableName = 'B00Command' OR @baseTableName = 'B08Command' OR @baseTableName = 'B09Command') AND EXISTS (SELECT TOP (1) 1 FROM @RoleTable WHERE RoleType = 10)
			SET @isRestrictedCommand = 1;
	END;
	ELSE
	BEGIN
		SET @roleTypeList = ',' + @roleTypeList + ',';
		IF CHARINDEX(',1,', @roleTypeList) > 0
			SET @isAdminRole = 1;
		
		IF CHARINDEX(',4,', @roleTypeList) > 0
			SET @isModeratorRole = 1;

		IF CHARINDEX(',3,', @roleTypeList) > 0
			SET @isRestrictedRole = 1;

		IF (@baseTableName = 'B00Command' OR @baseTableName = 'B08Command' OR @baseTableName = 'B09Command') AND CHARINDEX(',10,', @roleTypeList) > 0
			SET @isRestrictedCommand = 1;
	END;

	IF ISNULL(@groupUserString, '') = ''
		SET @groupUserString = dbo.ufn_sys_GetModeratedUserString(@userId);

	IF ISNULL(@roleUserString, '') = ''
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM @roleScheduleListTable)
			SET @roleUserString = IIF((SELECT TOP 1 1 FROM @RoleTable WHERE RoleType = 3) > 0,  LTRIM(STR(@userId)) + ',-1', '-1');
		ELSE
			SET @roleUserString = dbo.ufn_sys_GetRestrictedRoleUserString(@userId);
	END
	
	-- Xử lý riêng biệt cho 2 bảng B00RoleList và B00UserList với người dùng không phải là admin. (B08UserPortal và B08RoleList nếu là portal)
	IF @isAdminRole = 0
	BEGIN
		IF @baseTableName = 'B00UserList' OR @baseTableName = 'B08UserPortal'
		BEGIN
			-- Quản lý nhóm được xem những người dùng thuộc nhóm
			IF @isModeratorRole = 1
			BEGIN
				DECLARE @currentParentId INT = 0;
				IF @baseTableName = 'B00UserList'		
					SET @currentParentId = (SELECT TOP 1 ParentId FROM B00UserList WHERE Id=@userId);
				ELSE IF @baseTableName = 'B08UserPortal'
					SET @currentParentId = (SELECT TOP 1 ParentId FROM B08UserPortal WHERE Id=@userId);

				SET @prefix = 'ParentId IN (' 
				+ (CASE WHEN RIGHT(@groupUserString, 3) = ',-1' THEN LEFT(@groupUserString, LEN(@groupUserString) - 3) ELSE @groupUserString END) 
				+ (CASE WHEN @groupUserString != '' AND @currentParentId > 0 THEN CONCAT(',', @currentParentId) ELSE '' END)
				+ ')';
			END
			ELSE
				SET @prefix = 'Id=' + LTRIM(STR(@userId));
		END;
		ELSE IF @baseTableName = 'B00RoleList' OR @baseTableName = 'B08RoleList'
		BEGIN
			-- Quản lý nhóm được xem những vai trò custom
			IF @isModeratorRole = 1
				SET @prefix = 'RoleType=0';
			ELSE
				SET @prefix = '0=1';
		END;
	END;

	DECLARE @ignoreCreatedBy AS bit = 0;
	DECLARE @isSystemTable AS bit = 0;
	DECLARE @isExistColumn BIT = (SELECT dbo.ufn_sys_IsExistColumn(@tableName, 'CreatedBy'));

	-- Các bảng B00 trừ B00Layout sẽ không query theo CreatedBy
	IF (@baseTableName <> 'B00Layout' OR @baseTableName <> 'B08Layout' OR @baseTableName <> 'B09Layout') AND (@baseTableName LIKE 'B00%' OR @baseTableName LIKE 'B08%' OR @baseTableName LIKE 'B09%')
	BEGIN
		SET @isSystemTable = 1;
		SET @ignoreCreatedBy = 1;
	END;

	-- Cần bỏ qua các bảng không có cột CreatedBy để tránh bị lỗi khi query
	ELSE IF OBJECT_ID(@tableName) IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.columns WITH (NOLOCK)
			WHERE [object_id] = OBJECT_ID(@tableName) AND [name] = 'CreatedBy') AND @IsExistColumn = 0
		SET @ignoreCreatedBy = 1;

	DECLARE @restrictedExpr AS nvarchar(MAX) = '';
	
	IF @ignoreCreatedBy = 0
	BEGIN
		IF @restrictedRoleType = 0
			SET @restrictedExpr = IIF(@_IsBuildQuery = 0, 'CreatedBy', '{$.}CreatedBy') + ' IN (-1,' + LTRIM(STR(@userId)) + ')';
		ELSE IF @restrictedRoleType = 1
			SET @restrictedExpr = IIF(@_IsBuildQuery = 0, 'CreatedBy', '{$.}CreatedBy') + ' IN (' + @groupUserString + ')';
		ELSE IF @restrictedRoleType = 2
			SET @restrictedExpr = IIF(@_IsBuildQuery = 0, 'CreatedBy', '{$.}CreatedBy') + ' IN (' + @roleUserString + ')';
		ELSE IF @restrictedRoleType = 3
			SET @restrictedExpr = IIF(@_IsBuildQuery = 0, 'CreatedBy', '{$.}CreatedBy') + '=' + LTRIM(STR(@userId));
	END;

	DECLARE @openFlag AS bit = IIF(@permissionFlags = 0 OR (@permissionFlags & 1) = 1, 1, 0), 
		@editFlag AS bit = IIF(@permissionFlags = 0 OR (@permissionFlags & 2) = 2, 1, 0), 
		@deleteFlag AS bit = IIF(@permissionFlags = 0 OR (@permissionFlags & 4) = 4, 1, 0), 
		@recallFlag AS bit = IIF(@permissionFlags = 0 OR (@permissionFlags & 8) = 8, 1, 0), 
		@addNewFlag AS bit = IIF(@permissionFlags = 0 OR (@permissionFlags & 16) = 16, 1, 0);

	DECLARE @filterExpr AS nvarchar(MAX) = '';
  DECLARE @noPermissionData BIT = 0;

	-- Quyền dữ liệu được lưu với TableName <> '', ColumnName = '', FilterExpr có thể = '' hoặc không
  IF (@isPortalPlatform = 1)
  BEGIN
  	IF NOT EXISTS (SELECT 1 FROM B08PermissionData WITH (NOLOCK)
  		WHERE TableName IN (@tableName, @baseTableName) AND ColumnName = '' AND PortalDetailId = @portalDetailId)
  		SET @noPermissionData = 1;
  END
  ELSE
  BEGIN
  	IF NOT EXISTS (SELECT 1 FROM B00PermissionData WITH (NOLOCK)
  		WHERE TableName IN (@tableName, @baseTableName) AND ColumnName = '')
  		SET @noPermissionData = 1;
  END

	IF @noPermissionData = 1
	BEGIN
		-- Ngầm định khi không có dữ liệu phân quyền

		IF @isRestrictedCommand = 1
			SET @filterExpr = '(DLLName='''' AND ClassName='''')'; -- chỉ cho phép role Restricted Command tải các lệnh tác vụ
		ELSE IF @isRestrictedRole = 1 AND @ignoreCreatedBy = 1
			SET @filterExpr = '';--'0=1'; // cho phép role Limited User có toàn quyền với dữ liệu không có cột CreatedBy
		ELSE IF @isRestrictedRole = 1 AND @restrictedExpr > ''
			SET @filterExpr = '(' + (CASE WHEN @prefix <> '' THEN @prefix + ' AND ' 
				ELSE '' END) + @restrictedExpr + ')';
		ELSE IF @prefix > ''
			SET @filterExpr = '(' + @prefix + ')';
		
		IF @isRestrictedRole = 1
			INSERT INTO @Result SELECT 
				IIF(@openFlag = 1, @filterExpr, NULL) AS NoOpen, 
				IIF(@editFlag = 1, '(0=1)', NULL) AS NoEdit, 
				IIF(@deleteFlag = 1, '(0=1)', NULL) AS NoDelete, 
				IIF(@recallFlag = 1, '(0=1)', NULL) AS NoRecall, 
				IIF(@addNewFlag = 1, (CASE WHEN @isSystemTable = 1 THEN '(0=1)' ELSE IIF(@prefix > '', '(' + @prefix + ')','') END), NULL) AS NoAddNew;
		ELSE
			INSERT INTO @Result SELECT
				IIF(@openFlag = 1, @filterExpr, NULL) AS NoOpen, 
				IIF(@editFlag = 1, @filterExpr, NULL) AS NoEdit, 
				IIF(@deleteFlag = 1, @filterExpr, NULL) AS NoDelete, 
				IIF(@recallFlag = 1, @filterExpr, NULL) AS NoRecall, 
				IIF(@addNewFlag = 1, IIF(@prefix > '', '(' + @prefix + ')',''), NULL) AS NoAddNew;
		SELECT * FROM @Result;
		RETURN;
	END;

	DECLARE @UserListTable TABLE(BuiltinOrder int, UserId int, RoleId int);
	IF EXISTS (SELECT TOP 1 1 FROM @roleScheduleListTable)
		INSERT INTO @userListTable SELECT 0 AS BuiltinOrder,CAST(-1 AS INT) AS UserId, Id AS RoleId 
			FROM @roleScheduleListTable
	ELSE
		INSERT INTO @UserListTable 
			SELECT BuiltinOrder, UserId, RoleId 
				FROM dbo.ufn_sys_GetPermissionUserListTable(@userId);

	
	DECLARE @exprRestrictOpen AS nvarchar(MAX) = '', @exprRestrictEdit AS nvarchar(MAX) = '', 
		@exprRestrictDelete AS nvarchar(MAX) = '', @exprRestrictRecall AS nvarchar(MAX) = '';

	DECLARE @className varchar(64) = NULL;
	-- Logic 10.5.1:
	-- - Mở all ClassName có logic tương tự DataExplorer/DataEditor/ProjectManagement
	-- - Check thêm ClassName của Command
  IF (@isPortalPlatform = 1)
  BEGIN
    SELECT 
      c.*,
      ROW_NUMBER() OVER (
          PARTITION BY c.CommandKey 
          ORDER BY 
              CASE 
                  WHEN c.PortalDetailId = @portalDetailId THEN 1
                  WHEN c.PortalId = @portalId THEN 2
                  WHEN c.PortalDetailId = 0 AND c.PortalId = 0 THEN 3
                  ELSE 4
              END
      ) AS _RowNumber
    INTO #tmpCommand
    FROM B08Command c WITH (NOLOCK)
    WHERE c.PortalDetailId = @portalDetailId OR c.PortalId = @portalId OR (c.PortalDetailId = 0 AND c.PortalId = 0)
  END

	IF (@commandKey IS NOT NULL AND @isPortalPlatform = 1)
		BEGIN
      IF (EXISTS (SELECT 1 FROM #tmpCommand WHERE CommandKey = @commandKey AND _RowNumber = 1))
      BEGIN
        SET @className = (SELECT TOP 1 ClassName FROM #tmpCommand WHERE CommandKey = @commandKey AND _RowNumber = 1);
  			SET @isIgnoredCommandKey = 0;
      END
      DROP TABLE #tmpCommand;
		END
	ELSE IF (@commandKey IS NOT NULL 
			AND @platform != 'Mobile' 
			AND EXISTS 
			(
				SELECT 1 FROM B00Command WITH (NOLOCK)
					WHERE CommandKey = @commandKey 
			)
		)
		BEGIN
			SET @className = (SELECT TOP 1 ClassName FROM B00Command WITH (NOLOCK) WHERE CommandKey = @commandKey);
			SET @isIgnoredCommandKey = 0;
		END
	ELSE IF (@commandKey IS NOT NULL 
				AND @platform = 'Mobile' 
				AND EXISTS 
				(
					SELECT 1 FROM B09Command WITH (NOLOCK)
						WHERE CommandKey = @commandKey
				)
			)
		BEGIN
			SET @className = (SELECT TOP 1 ClassName FROM B09Command WITH (NOLOCK) WHERE CommandKey = @commandKey);
			SET @isIgnoredCommandKey = 0;
		END

	IF (@commandKey IS NOT NULL AND @baseTableName IN ('B00Layout','B08Layout','B09Layout'))
		BEGIN
			SET @isIgnoredCommandKey = 0;
			SET @isLayoutPermission = 1;
		END

    -- Các biến dùng để xử lý FilterExpr
    DECLARE @_Index INT;
    DECLARE @_TempExpr NVARCHAR(MAX);
    DECLARE @_TempDataId INT;

	-- Với vai trò người dùng cô lập cần kiểm tra quyền cho phép
	IF @isRestrictedRole = 1 OR @isRestrictedCommand = 1
	BEGIN
		DECLARE @PermissionAll TABLE
		(
			DataIdForFilterExpr int
            ,RowIndex int
			,TableName varchar(100)
			,FilterExpr nvarchar(MAX)
			,BuiltinOrder int
			,RoleId int
			,UserId int
			,NoOpenDOU tinyint
			,NoEditDOU tinyint
			,NoDeleteDOU tinyint
			,NoRecallDOU tinyint
			,NoInherit tinyint
		);
		
    IF (@isPortalPlatform = 1)
    BEGIN
      INSERT INTO @PermissionAll SELECT * FROM (SELECT 
                (CASE WHEN pd.LayoutId IS NOT NULL THEN -1 ELSE pd.Id END) AS DataIdForFilterExpr
                ,ROW_NUMBER() OVER(ORDER BY (SELECT 0)) AS RowIndex
                ,pd.TableName
				,(CASE WHEN pd.LayoutId IS NOT NULL THEN 'Id=' + LTRIM(STR(LayoutId)) ELSE FixedFilterExpr END) FilterExpr
				,o.BuiltinOrder
				,p.RoleId
				,p.UserId
				,IIF(@isRestrictedCommand = 1, p.NoOpen, p.NoOpenDOU) NoOpenDOU
				,p.NoEditDOU
				,p.NoDeleteDOU
				,p.NoRecallDOU
				,p.NoInherit
			FROM B08Permission AS p WITH (NOLOCK) INNER JOIN 
				@UserListTable AS o ON 
					o.RoleId = ISNULL(p.RoleId, -1) AND o.UserId = ISNULL(p.UserId, -1) INNER JOIN
				B08PermissionData AS pd WITH (NOLOCK) ON pd.Id = p.DataId
			WHERE pd.TableName IN (@tableName, @baseTableName) AND pd.ColumnName = '' AND pd.PortalDetailId = @portalDetailId
				AND (
						pd.ParentCommandKey = IIF(@isIgnoredCommandKey = 1, '', ISNULL(@commandKey, '')) 
						OR pd.ParentCommandKey = IIF(@isIgnoredCommandKey = 1, '', '*') -- Lọc logic config * ở ParentCommandKey
						OR (@isIgnoredCommandKey = 0 AND pd.ParentCommandKey = '')
					)
				AND (
						ISNULL(@className, '') <> '' AND (pd.ClassName = @className OR pd.ClassName = '')
						OR ISNULL(pd.ClassName, '') = ''
					)
				AND (pd.BranchCode = ISNULL(@branchCode, '') OR pd.BranchCode = '')
				AND (pd.Platform = ISNULL(@platform, '') OR pd.Platform = '')
				AND (IIF(@openFlag = 1, ISNULL(p.NoOpenDOU, 1), 1) = 0 
					OR IIF(@editFlag = 1, ISNULL(p.NoEditDOU, 0), 1) = 0
					OR IIF(@deleteFlag = 1, ISNULL(p.NoDeleteDOU, 0), 1) = 0 
					OR IIF(@recallFlag = 1, ISNULL(p.NoRecallDOU, 0), 1) = 0 
					OR ISNULL(p.NoInherit, 0) = 1)
				AND p.IsActive = 1 AND pd.IsActive = 1) temp 
				WHERE (IIF(@filterExprPattern > '', CHARINDEX(FilterExpr, @filterExprPattern), 1) > 0);
    END
    ELSE
    BEGIN
      INSERT INTO @PermissionAll SELECT * FROM (SELECT 
                (CASE WHEN pd.LayoutId IS NOT NULL THEN -1 ELSE pd.Id END) AS DataIdForFilterExpr
                ,ROW_NUMBER() OVER(ORDER BY (SELECT 0)) AS RowIndex
                ,pd.TableName
				,(CASE WHEN pd.LayoutId IS NOT NULL THEN 'Id=' + LTRIM(STR(LayoutId)) ELSE FixedFilterExpr END) FilterExpr
				,o.BuiltinOrder
				,p.RoleId
				,p.UserId
				,IIF(@isRestrictedCommand = 1, p.NoOpen, p.NoOpenDOU) NoOpenDOU
				,p.NoEditDOU
				,p.NoDeleteDOU
				,p.NoRecallDOU
				,p.NoInherit
			FROM B00Permission AS p WITH (NOLOCK) INNER JOIN 
				@UserListTable AS o ON 
					o.RoleId = ISNULL(p.RoleId, -1) AND o.UserId = ISNULL(p.UserId, -1) INNER JOIN
				B00PermissionData AS pd WITH (NOLOCK) ON pd.Id = p.DataId
			WHERE pd.TableName IN (@tableName, @baseTableName) AND pd.ColumnName = ''
				AND (
						pd.ParentCommandKey = IIF(@isIgnoredCommandKey = 1, '', ISNULL(@commandKey, '')) 
						OR pd.ParentCommandKey = IIF(@isIgnoredCommandKey = 1, '', '*') -- Lọc logic config * ở ParentCommandKey
						OR (@isIgnoredCommandKey = 0 AND pd.ParentCommandKey = '')
					)
				AND (
						ISNULL(@className, '') <> '' AND (pd.ClassName = @className OR pd.ClassName = '')
						OR ISNULL(pd.ClassName, '') = ''
					)
				AND (pd.BranchCode = ISNULL(@branchCode, '') OR pd.BranchCode = '')
				AND (pd.Platform = ISNULL(@platform, '') OR pd.Platform = '')
				AND (IIF(@openFlag = 1, ISNULL(p.NoOpenDOU, 1), 1) = 0 
					OR IIF(@editFlag = 1, ISNULL(p.NoEditDOU, 0), 1) = 0
					OR IIF(@deleteFlag = 1, ISNULL(p.NoDeleteDOU, 0), 1) = 0 
					OR IIF(@recallFlag = 1, ISNULL(p.NoRecallDOU, 0), 1) = 0 
					OR ISNULL(p.NoInherit, 0) = 1)
				AND p.IsActive = 1 AND pd.IsActive = 1) temp 
				WHERE (IIF(@filterExprPattern > '', CHARINDEX(FilterExpr, @filterExprPattern), 1) > 0);
    END
		
		
        -- Đoạn này xử lý lấy ra FilterExpr đã được evaluate
        SET @_Index = 1;
        WHILE @_Index <= (SELECT COUNT(1) FROM @PermissionAll)
        BEGIN
				-- Nếu đã có FilterExpr rồi tức là các PermissionData dùng FixedFilterExpr
				IF(EXISTS(SELECT TOP 1 1 FROM @PermissionAll WHERE RowIndex = @_Index AND ISNULL(FilterExpr, '') != ''))
				BEGIN				
					SET @_Index += 1;
					CONTINUE;
				END

                SET @_TempDataId = -1;
                SET @_TempExpr = N'';
                SELECT TOP 1 @_TempDataId = DataIdForFilterExpr FROM @PermissionAll WHERE RowIndex = @_Index;
                IF (@_TempDataId <= 0) CONTINUE;
                EXEC usp_sys_GetPermissionFilterExpr
                @_DataId = @_TempDataId,
				@_PreviewTable = @previewTable,
                @_Expr = @_TempExpr OUTPUT,
				@_IsBuildQuery = @_IsBuildQuery
                UPDATE @PermissionAll SET FilterExpr = @_TempExpr WHERE RowIndex = @_Index;
                SET @_Index += 1;
        END

		;WITH ctePermissionNoInherit AS
		(
			SELECT TableName, FilterExpr, BuiltinOrder 
				FROM @PermissionAll WHERE NoInherit = 1
		)
		,cteExpr AS
		(
			SELECT  a.FilterExpr, a.NoOpenDOU, a.NoEditDOU, a.NoDeleteDOU, a.NoRecallDOU
				FROM @PermissionAll AS a INNER JOIN 
					ctePermissionNoInherit AS b ON a.TableName = b.TableName AND a.FilterExpr = b.FilterExpr 
						AND (a.BuiltinOrder < b.BuiltinOrder OR (a.BuiltinOrder = b.BuiltinOrder AND a.NoInherit = 1))
			UNION
			SELECT  a.FilterExpr, a.NoOpenDOU, a.NoEditDOU, a.NoDeleteDOU, a.NoRecallDOU
				FROM @PermissionAll AS a 
				WHERE NOT EXISTS (SELECT 1 FROM @PermissionAll WHERE 
					NoInherit = 1 AND TableName = a.TableName AND FilterExpr = a.FilterExpr)
		)
		SELECT @exprRestrictOpen = IIF(@openFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
				(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
					FROM cteExpr WHERE @openFlag = 1 AND NoOpenDOU = 0 FOR XML PATH ('')
				), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
			@exprRestrictEdit = IIF(@addNewFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
				(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
					FROM cteExpr WHERE @editFlag = 1 AND NoEditDOU = 0 FOR XML PATH ('')
				), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
			@exprRestrictDelete = IIF(@deleteFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
				(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
					FROM cteExpr WHERE @deleteFlag = 1 AND NoDeleteDOU = 0 FOR XML PATH ('')
				), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
			@exprRestrictRecall = IIF(@recallFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
				(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
					FROM cteExpr WHERE @recallFlag = 1 AND NoRecallDOU = 0 FOR XML PATH ('')
				), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), '');

		SELECT @exprRestrictOpen = LTRIM(RTRIM(ISNULL(@exprRestrictOpen, ''))),
				@exprRestrictEdit = LTRIM(RTRIM(ISNULL(@exprRestrictEdit, ''))),
				@exprRestrictDelete = LTRIM(RTRIM(ISNULL(@exprRestrictDelete, ''))),
				@exprRestrictRecall = LTRIM(RTRIM(ISNULL(@exprRestrictRecall, '')));

		IF @restrictedExpr > ''
		BEGIN
			IF @exprRestrictOpen <> '' SET @exprRestrictOpen = @exprRestrictOpen + ' OR ';
			SET @exprRestrictOpen = '(' + @exprRestrictOpen + @restrictedExpr + ')';

			IF @exprRestrictEdit <> '' SET @exprRestrictEdit = @exprRestrictEdit + ' OR ';
			SET @exprRestrictEdit = '(' + @exprRestrictEdit + @restrictedExpr + ')';

			IF @exprRestrictDelete <> '' SET @exprRestrictDelete = @exprRestrictDelete + ' OR ';
			SET @exprRestrictDelete = '(' + @exprRestrictDelete + @restrictedExpr + ')';

			IF @exprRestrictRecall <> '' SET @exprRestrictRecall = @exprRestrictRecall + ' OR ';
			SET @exprRestrictRecall = '(' + @exprRestrictRecall + @restrictedExpr + ')';
		END
	END;

	-- Đối với tất cả các vai trò cần kiểm tra quyền cấm + quyền cho phép
	
	DECLARE @PermissionAll0 TABLE
	(
		DataIdForFilterExpr int
        ,RowIndex int
        ,TableName varchar(48)
		,FilterExpr nvarchar(MAX)
		,BuiltinOrder int
		,RoleId int
		,UserId int
		,NoOpen tinyint
		,NoOpenDOU tinyint
		,NoEdit tinyint
		,NoEditDOU tinyint
		,NoDelete tinyint
		,NoDeleteDOU tinyint
		,NoRecall tinyint
		,NoRecallDOU tinyint
		,NoAddNew tinyint
		,NoInherit tinyint
	);

  IF (@isPortalPlatform = 1)
  BEGIN
    INSERT INTO @PermissionAll0 SELECT * FROM (SELECT 
            (CASE WHEN pd.LayoutId IS NOT NULL THEN -1 ELSE pd.Id END) AS DataIdForFilterExpr
            ,ROW_NUMBER() OVER(ORDER BY (SELECT 0)) AS RowIndex
            ,pd.TableName
			,(CASE WHEN pd.LayoutId IS NOT NULL THEN 'Id=' + LTRIM(STR(LayoutId)) ELSE FixedFilterExpr END) FilterExpr
			,o.BuiltinOrder
			,p.RoleId
			,p.UserId
			,p.NoOpen
			,p.NoOpenDOU
			,p.NoEdit
			,p.NoEditDOU
			,p.NoDelete
			,p.NoDeleteDOU
			,p.NoRecall
			,p.NoRecallDOU
			,p.NoAddNew
			,p.NoInherit
		FROM B08Permission AS p WITH (NOLOCK) INNER JOIN 
			@UserListTable AS o ON 
				o.RoleId = ISNULL(p.RoleId, -1) AND o.UserId = ISNULL(p.UserId, -1) INNER JOIN
			B08PermissionData AS pd WITH (NOLOCK) ON pd.Id = p.DataId
		WHERE pd.TableName IN (@tableName, @baseTableName) AND pd.ColumnName = '' AND pd.PortalDetailId = @portalDetailId
			AND (
					pd.ParentCommandKey = IIF(@isIgnoredCommandKey = 1, '', ISNULL(@commandKey, '')) 
					OR pd.ParentCommandKey = IIF(@isIgnoredCommandKey = 1, '', '*') -- Lọc logic config * ở ParentCommandKey
					OR (@isIgnoredCommandKey = 0 AND pd.ParentCommandKey = '')
				)
			AND (
					ISNULL(@className, '') <> '' AND (pd.ClassName = @className OR pd.ClassName = '')
					OR ISNULL(pd.ClassName, '') = ''
				)
			AND (pd.BranchCode = ISNULL(@branchCode, '') OR pd.BranchCode = '')
			AND (pd.Platform = ISNULL(@platform, '') OR pd.Platform = '')
			AND (IIF(@openFlag = 1, IIF(p.NoOpen IS NULL, 0, 1), 0) = 1 
				OR IIF(@openFlag = 1, IIF(p.NoOpenDOU IS NULL, 0, 1), 0) = 1
				OR IIF(@editFlag = 1, IIF(p.NoEdit IS NULL, 0, 1), 0) = 1 
				OR IIF(@editFlag = 1, IIF(p.NoEditDOU IS NULL, 0, 1), 0) = 1 
				OR IIF(@deleteFlag = 1, IIF(p.NoDelete IS NULL, 0, 1), 0) = 1 
				OR IIF(@deleteFlag = 1, IIF(p.NoDeleteDOU IS NULL, 0, 1), 0) = 1
				OR IIF(@recallFlag = 1, IIF(p.NoRecall IS NULL, 0, 1), 0) = 1 
				OR IIF(@recallFlag = 1, IIF(p.NoRecallDOU IS NULL, 0, 1), 0) = 1 
				OR IIF(@addNewFlag = 1, IIF(p.NoAddNew IS NULL, 0, 1), 0) = 1 
				OR IIF(p.NoInherit IS NULL, 0, 1) = 1)
			AND p.IsActive = 1 AND pd.IsActive = 1) temp
			WHERE (IIF(@filterExprPattern > '', CHARINDEX(FilterExpr, @filterExprPattern), 1) > 0);
  END
  ELSE
  BEGIN
    INSERT INTO @PermissionAll0 SELECT * FROM (SELECT 
            (CASE WHEN pd.LayoutId IS NOT NULL THEN -1 ELSE pd.Id END) AS DataIdForFilterExpr
            ,ROW_NUMBER() OVER(ORDER BY (SELECT 0)) AS RowIndex
            ,pd.TableName
			,(CASE WHEN pd.LayoutId IS NOT NULL THEN 'Id=' + LTRIM(STR(LayoutId)) ELSE FixedFilterExpr END) FilterExpr
			,o.BuiltinOrder
			,p.RoleId
			,p.UserId
			,p.NoOpen
			,p.NoOpenDOU
			,p.NoEdit
			,p.NoEditDOU
			,p.NoDelete
			,p.NoDeleteDOU
			,p.NoRecall
			,p.NoRecallDOU
			,p.NoAddNew
			,p.NoInherit
		FROM B00Permission AS p WITH (NOLOCK) INNER JOIN 
			@UserListTable AS o ON 
				o.RoleId = ISNULL(p.RoleId, -1) AND o.UserId = ISNULL(p.UserId, -1) INNER JOIN
			B00PermissionData AS pd WITH (NOLOCK) ON pd.Id = p.DataId
		WHERE pd.TableName IN (@tableName, @baseTableName) AND pd.ColumnName = '' 
			AND (
					pd.ParentCommandKey = IIF(@isIgnoredCommandKey = 1, '', ISNULL(@commandKey, '')) 
					OR pd.ParentCommandKey = IIF(@isIgnoredCommandKey = 1, '', '*') -- Lọc logic config * ở ParentCommandKey
					OR (@isIgnoredCommandKey = 0 AND pd.ParentCommandKey = '')
				)
			AND (
					ISNULL(@className, '') <> '' AND (pd.ClassName = @className OR pd.ClassName = '')
					OR ISNULL(pd.ClassName, '') = ''
				)
			AND (pd.BranchCode = ISNULL(@branchCode, '') OR pd.BranchCode = '')
			AND (pd.Platform = ISNULL(@platform, '') OR pd.Platform = '')
			AND (IIF(@openFlag = 1, IIF(p.NoOpen IS NULL, 0, 1), 0) = 1 
				OR IIF(@openFlag = 1, IIF(p.NoOpenDOU IS NULL, 0, 1), 0) = 1
				OR IIF(@editFlag = 1, IIF(p.NoEdit IS NULL, 0, 1), 0) = 1 
				OR IIF(@editFlag = 1, IIF(p.NoEditDOU IS NULL, 0, 1), 0) = 1 
				OR IIF(@deleteFlag = 1, IIF(p.NoDelete IS NULL, 0, 1), 0) = 1 
				OR IIF(@deleteFlag = 1, IIF(p.NoDeleteDOU IS NULL, 0, 1), 0) = 1
				OR IIF(@recallFlag = 1, IIF(p.NoRecall IS NULL, 0, 1), 0) = 1 
				OR IIF(@recallFlag = 1, IIF(p.NoRecallDOU IS NULL, 0, 1), 0) = 1 
				OR IIF(@addNewFlag = 1, IIF(p.NoAddNew IS NULL, 0, 1), 0) = 1 
				OR IIF(p.NoInherit IS NULL, 0, 1) = 1)
			AND p.IsActive = 1 AND pd.IsActive = 1) temp
			WHERE (IIF(@filterExprPattern > '', CHARINDEX(FilterExpr, @filterExprPattern), 1) > 0);
  END
	
	
    -- Đoạn này xử lý lấy ra FilterExpr đã được evaluate
    SET @_Index = 1;
    WHILE @_Index <= (SELECT COUNT(1) FROM @PermissionAll0)
    BEGIN
			-- Nếu đã có FilterExpr rồi tức là các PermissionData dùng FixedFilterExpr
			IF(EXISTS(SELECT TOP 1 1 FROM @PermissionAll0 WHERE RowIndex = @_Index AND ISNULL(FilterExpr, '') != ''))
			BEGIN				
				SET @_Index += 1;
				CONTINUE;
			END

            SET @_TempDataId = -1;
            SET @_TempExpr = N'';
            SELECT TOP 1 @_TempDataId = DataIdForFilterExpr FROM @PermissionAll0 WHERE RowIndex = @_Index;
            IF (@_TempDataId <= 0) CONTINUE;
            EXEC usp_sys_GetPermissionFilterExpr
            @_DataId = @_TempDataId,
			@_PreviewTable = @previewTable,
            @_Expr = @_TempExpr OUTPUT,
			@_IsBuildQuery = @_IsBuildQuery
            UPDATE @PermissionAll0 SET FilterExpr = @_TempExpr WHERE RowIndex = @_Index;
            SET @_Index += 1;
    END

	DECLARE @exprDenyOpen AS nvarchar(MAX), @exprDenyEdit AS nvarchar(MAX),
		@exprDenyDelete AS nvarchar(MAX), @exprDenyRecall AS nvarchar(MAX), @exprDenyAddNew AS nvarchar(MAX);
	DECLARE @exprDenyOpenDOU AS nvarchar(MAX), @exprDenyEditDOU AS nvarchar(MAX), 
		@exprDenyDeleteDOU AS nvarchar(MAX), @exprDenyRecallDOU AS nvarchar(MAX);

	DECLARE @exprAllowOpen AS nvarchar(MAX), @exprAllowEdit AS nvarchar(MAX),
		@exprAllowDelete AS nvarchar(MAX), @exprAllowRecall AS nvarchar(MAX), @exprAllowAddNew AS nvarchar(MAX);

	WITH ctePermissionNoInherit AS
	(
		SELECT TableName, FilterExpr, BuiltinOrder 
			FROM @PermissionAll0 WHERE NoInherit = 1
	)
	,cteExpr AS
	(
		SELECT a.FilterExpr, a.NoOpen, a.NoEdit, a.NoDelete, a.NoRecall, a.NoAddNew, a.NoOpenDOU, a.NoEditDOU, a.NoDeleteDOU, a.NoRecallDOU
			FROM @PermissionAll0 AS a INNER JOIN 
				ctePermissionNoInherit AS b ON a.TableName = b.TableName AND a.FilterExpr = b.FilterExpr 
					AND (a.BuiltinOrder < b.BuiltinOrder OR (a.BuiltinOrder = b.BuiltinOrder AND a.NoInherit = 1))
		UNION
		SELECT a.FilterExpr, a.NoOpen, a.NoEdit, a.NoDelete, a.NoRecall, a.NoAddNew, a.NoOpenDOU, a.NoEditDOU, a.NoDeleteDOU, a.NoRecallDOU
			FROM @PermissionAll0 AS a 
			WHERE NOT EXISTS (SELECT 1 FROM @PermissionAll0 WHERE 
				NoInherit = 1 AND TableName = a.TableName AND FilterExpr = a.FilterExpr)
	)
	SELECT @exprDenyOpen = IIF(@openFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE @openFlag = 1 AND NoOpen = 1 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprAllowOpen = IIF(@openFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE @openFlag = 1 AND NoOpen = 0 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprDenyEdit = IIF(@editFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE NoEdit = 1 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprAllowEdit = IIF(@editFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE NoEdit = 0 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprDenyDelete = IIF(@deleteFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE NoDelete = 1 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprAllowDelete = IIF(@deleteFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE NoDelete = 0 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprDenyRecall = IIF(@recallFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE NoRecall = 1 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprAllowRecall = IIF(@recallFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE NoRecall = 0 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprDenyAddNew = IIF(@addNewFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE NoAddNew = 1 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprAllowAddNew = IIF(@addNewFlag = 1, REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE NoAddNew = 0 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprDenyOpenDOU = IIF(@ignoreCreatedBy = 0 AND @openFlag = 1, 
			REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE @openFlag = 1 AND NoOpenDOU = 1 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprDenyEditDOU = IIF(@ignoreCreatedBy = 0 AND @editFlag = 1, 
			REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE @editFlag = 1 AND NoEditDOU = 1 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprDenyDeleteDOU = IIF(@ignoreCreatedBy = 0 AND @deleteFlag = 1, 
			REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE NoDeleteDOU = 1 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), ''),
		@exprDenyRecallDOU = IIF(@ignoreCreatedBy = 0 AND @recallFlag = 1, 
			REPLACE(REPLACE(REPLACE(STUFF(CONVERT(nvarchar(MAX), 
			(SELECT ' OR ' + (CASE WHEN FilterExpr = '' THEN '0=0' ELSE FilterExpr END)
				FROM cteExpr WHERE NoRecallDOU = 1 FOR XML PATH ('')
			), 1), 1, 4, ''), '&gt;', '>'), '&lt;', '<'), '&amp;', '&'), '');

	SELECT @exprDenyOpen = LTRIM(RTRIM(ISNULL(@exprDenyOpen, ''))),
		@exprDenyEdit = LTRIM(RTRIM(ISNULL(@exprDenyEdit, ''))),
		@exprDenyDelete = LTRIM(RTRIM(ISNULL(@exprDenyDelete, ''))),
		@exprDenyRecall = LTRIM(RTRIM(ISNULL(@exprDenyRecall, ''))),
		@exprDenyAddNew = LTRIM(RTRIM(ISNULL(@exprDenyAddNew, ''))),
		@exprDenyOpenDOU = LTRIM(RTRIM(ISNULL(@exprDenyOpenDOU, ''))),
		@exprDenyEditDOU = LTRIM(RTRIM(ISNULL(@exprDenyEditDOU, ''))),
		@exprDenyDeleteDOU = LTRIM(RTRIM(ISNULL(@exprDenyDeleteDOU, ''))),
		@exprDenyRecallDOU = LTRIM(RTRIM(ISNULL(@exprDenyRecallDOU, ''))),
		@exprAllowOpen = LTRIM(RTRIM(ISNULL(@exprAllowOpen, ''))),
		@exprAllowEdit = LTRIM(RTRIM(ISNULL(@exprAllowEdit, ''))),
		@exprAllowDelete = LTRIM(RTRIM(ISNULL(@exprAllowDelete, ''))),
		@exprAllowRecall = LTRIM(RTRIM(ISNULL(@exprAllowRecall, ''))),
		@exprAllowAddNew = LTRIM(RTRIM(ISNULL(@exprAllowAddNew, '')));
	
	-- Nếu là quyền cho phép đối với B00Layout, B09Layout + CommandKey => Loại bỏ các LayoutType không phải là Layout, SubLayout
	IF @isLayoutPermission = 1 AND @exprAllowOpen <> '' SET @exprAllowOpen = '(' + @exprAllowOpen + ' OR IsTemplate NOT IN (0,4))'
	IF @isLayoutPermission = 1 AND @exprAllowEdit <> '' SET @exprAllowEdit = '(' + @exprAllowEdit + ' OR IsTemplate NOT IN (0,4))'
	IF @isLayoutPermission = 1 AND @exprAllowDelete <> '' SET @exprAllowDelete = '(' + @exprAllowDelete + ' OR IsTemplate NOT IN (0,4))'
	IF @isLayoutPermission = 1 AND @exprAllowRecall <> '' SET @exprAllowRecall = '(' + @exprAllowRecall + ' OR IsTemplate NOT IN (0,4))'
	IF @isLayoutPermission = 1 AND @exprAllowAddNew <> '' SET @exprAllowAddNew = '(' + @exprAllowAddNew + ' OR IsTemplate NOT IN (0,4))'


	IF @exprDenyOpen <> '' SET @exprDenyOpen = 'NOT (' + @exprDenyOpen + ')';
	IF @exprDenyEdit <> '' SET @exprDenyEdit = 'NOT (' + @exprDenyEdit + ')';
	IF @exprDenyDelete <> '' SET @exprDenyDelete = 'NOT (' + @exprDenyDelete + ')';
	IF @exprDenyRecall <> '' SET @exprDenyRecall = 'NOT (' + @exprDenyRecall + ')';
	IF @exprDenyAddNew <> '' SET @exprDenyAddNew = 'NOT (' + @exprDenyAddNew + ')';

	IF @exprDenyOpenDOU <> ''
	BEGIN
		IF @restrictedExpr > ''
			SET @exprDenyOpenDOU = 'NOT ((' + @exprDenyOpenDOU + ') AND NOT ' + @restrictedExpr + ')';
		ELSE
			SET @exprDenyOpenDOU = 'NOT (' + @exprDenyOpenDOU + ')';
	END;

	IF @exprDenyEditDOU <> ''
	BEGIN
		IF @restrictedExpr > ''
			SET @exprDenyEditDOU = 'NOT ((' + @exprDenyEditDOU + ') AND NOT ' + @restrictedExpr + ')';
		ELSE
			SET @exprDenyEditDOU = 'NOT (' + @exprDenyEditDOU + ')';
	END;

	IF @exprDenyDeleteDOU <> ''
	BEGIN
		IF @restrictedExpr > ''
			SET @exprDenyDeleteDOU = 'NOT ((' + @exprDenyDeleteDOU + ') AND NOT ' + @restrictedExpr + ')';
		ELSE
			SET @exprDenyDeleteDOU = 'NOT (' + @exprDenyDeleteDOU + ')';
	END;

	IF @exprDenyRecallDOU <> ''
	BEGIN
		IF @restrictedExpr > ''
			SET @exprDenyRecallDOU = 'NOT ((' + @exprDenyRecallDOU + ') AND NOT ' + @restrictedExpr + ')';
		ELSE
			SET @exprDenyRecallDOU = 'NOT (' + @exprDenyRecallDOU + ')';
	END;

	IF @prefix <> '' SET @filterExpr = @prefix;
	
	DECLARE @openFilterExpr AS nvarchar(MAX) = '', @editFilterExpr AS nvarchar(MAX) = '',
		@deleteFilterExpr AS nvarchar(MAX) = '', @recallFilterExpr AS nvarchar(MAX) = '',
		@addNewFilterExpr AS nvarchar(MAX) = '';

	SELECT @openFilterExpr = @filterExpr, @editFilterExpr = @filterExpr, 
		@deleteFilterExpr = @filterExpr, @recallFilterExpr = @filterExpr,
		@addNewFilterExpr = @filterExpr;

	IF @exprDenyOpen <> '' SET @openFilterExpr = IIF(@openFilterExpr <> '', @openFilterExpr + ' AND ', '') + @exprDenyOpen;
	IF @exprDenyEdit <> '' SET @editFilterExpr = IIF(@editFilterExpr <> '', @editFilterExpr + ' AND ', '') + @exprDenyEdit;
	IF @exprDenyDelete <> '' SET @deleteFilterExpr = IIF(@deleteFilterExpr <> '', @deleteFilterExpr + ' AND ', '') + @exprDenyDelete;
	IF @exprDenyRecall <> '' SET @recallFilterExpr = IIF(@recallFilterExpr <> '', @recallFilterExpr + ' AND ', '') + @exprDenyRecall;
	IF @exprDenyAddNew <> '' SET @addNewFilterExpr = IIF(@addNewFilterExpr <> '', @addNewFilterExpr + ' AND ', '') + @exprDenyAddNew;
	
	IF @exprRestrictOpen <> '' SET @openFilterExpr = IIF(@openFilterExpr <> '', @openFilterExpr + ' AND ', '') + @exprRestrictOpen;
	IF @exprRestrictEdit <> '' SET @editFilterExpr = IIF(@editFilterExpr <> '', @editFilterExpr + ' AND ', '') + @exprRestrictEdit;
	IF @exprRestrictDelete <> '' SET @deleteFilterExpr = IIF(@deleteFilterExpr <> '', @deleteFilterExpr + ' AND ', '') + @exprRestrictDelete;
	IF @exprRestrictRecall <> '' SET @recallFilterExpr = IIF(@recallFilterExpr <> '', @recallFilterExpr + ' AND ', '') + @exprRestrictRecall;
	
	IF @exprAllowOpen <> '' SET @openFilterExpr = IIF(@openFilterExpr <> '', @openFilterExpr + ' AND ', '') + @exprAllowOpen;
	IF @exprAllowEdit <> '' SET @editFilterExpr = IIF(@editFilterExpr <> '', @editFilterExpr + ' AND ', '') + @exprAllowEdit;
	IF @exprAllowDelete <> '' SET @deleteFilterExpr = IIF(@deleteFilterExpr <> '', @deleteFilterExpr + ' AND ', '') + @exprAllowDelete;
	IF @exprAllowRecall <> '' SET @recallFilterExpr = IIF(@recallFilterExpr <> '', @recallFilterExpr + ' AND ', '') + @exprAllowRecall;
	IF @exprAllowAddNew <> '' SET @addNewFilterExpr = IIF(@addNewFilterExpr <> '', @addNewFilterExpr + ' AND ', '') + @exprAllowAddNew;

	IF @exprDenyOpenDOU <> '' SET @openFilterExpr = IIF(@openFilterExpr <> '', @openFilterExpr + ' AND ', '') + @exprDenyOpenDOU;
	IF @exprDenyEditDOU <> '' SET @editFilterExpr = IIF(@editFilterExpr <> '', @editFilterExpr + ' AND ', '') + @exprDenyEditDOU;
	IF @exprDenyDeleteDOU <> '' SET @deleteFilterExpr = IIF(@deleteFilterExpr <> '', @deleteFilterExpr + ' AND ', '') + @exprDenyDeleteDOU;
	IF @exprDenyRecallDOU <> '' SET @recallFilterExpr = IIF(@recallFilterExpr <> '', @recallFilterExpr + ' AND ', '') + @exprDenyRecallDOU;
	
	IF @openFilterExpr <> '' SET @openFilterExpr = '(' + @openFilterExpr + ')';

	--LOCPC 11/03/2025
	DECLARE @CmdExpr NVARCHAR(max) = ''

	IF @baseTableName LIKE 'B00Branch' 
	BEGIN
		 DECLARE @_BranchCodeExpr NVARCHAR(3), @IncludedChild BIT

		 SET @CmdExpr = ''

		 DECLARE @cteBranch AS TABLE(IsGroup BIT, IncludedChild BIT, BranchCode NVARCHAR(16), _Mark NVARCHAR(1))

		 IF EXISTS
			(
				SELECT 1 
				FROM B00PermissionBranch AS o WITH (NOLOCK) 
				INNER JOIN @UserListTable AS u ON o.UserId = u.UserId
				WHERE o.TableName = @baseTableName
			 ) 
		  BEGIN	    				
				INSERT INTO @cteBranch(IsGroup, IncludedChild, BranchCode, _Mark)
				SELECT d.IsGroup, o.IncludedChild, o.BranchCode, '' AS _Mark
				FROM B00PermissionBranch AS o WITH (NOLOCK) 
				INNER JOIN @UserListTable AS u ON o.UserId = u.UserId
				INNER JOIN B00Branch AS d ON o.BranchCode = d.BranchCode
				WHERE o.TableName = @baseTableName	
		  END

		  WHILE EXISTS(SELECT 1 FROM @cteBranch WHERE IsGroup = 1 AND IncludedChild = 1 AND _Mark = '')
		  BEGIN
			   SELECT TOP 1 @_BranchCodeExpr = BranchCode, @IncludedChild = IncludedChild FROM @cteBranch WHERE IsGroup = 1 AND _Mark = ''

			   ;WITH _CteBranchDetail AS
			   (
				 SELECT Id, ParentId, IsGroup, BranchCode
				 FROM B00Branch
				 WHERE BranchCode = @_BranchCodeExpr
				 UNION ALL
				 SELECT d0.Id, d0.ParentId, d0.IsGroup, d0.BranchCode
				 FROM B00Branch AS d0 INNER JOIN _CteBranchDetail AS _Cte
				 ON d0.ParentId = _Cte.Id				 
			   )
			   INSERT INTO @cteBranch
			   SELECT IsGroup, @IncludedChild AS IncludedChild, BranchCode, '' AS _Mark FROM _CteBranchDetail WHERE IsGroup = 0

			   UPDATE @cteBranch SET _Mark = '1' WHERE BranchCode = @_BranchCodeExpr
		  END

		  SELECT @CmdExpr = @CmdExpr + IIF(@CmdExpr<>'', ' OR ', '') + 'BranchCode = ''' + BranchCode + ''''
		  FROM @cteBranch
		  GROUP BY BranchCode

		  --Nếu không phải là Role Database Designer và chưa khai báo BranchCode truy cập thì khóa hết
		  IF ISNULL(@CmdExpr, '') = '' 
		  BEGIN
			  IF EXISTS(SELECT 1 FROM @UserListTable WHERE RoleId = 32) --Database Designer
			     SET @CmdExpr = '1=1'
              ELSE SET @CmdExpr = '0=1'
		  END
		  		  
		  IF @CmdExpr <> '' SET @openFilterExpr = IIF(@openFilterExpr <> '', @openFilterExpr + ' AND ', '') + '(' + @CmdExpr + ')';		  
	END	
	
	IF @baseTableName LIKE 'B00Layout' --phân quyền Main layout
	BEGIN
		 SET @CmdExpr = ''	 

		 IF NOT EXISTS(SELECT 1 FROM @UserListTable WHERE RoleId = 32) --Database Designer
		 BEGIN		     
			 SET @CmdExpr = 
			 STUFF((
				 SELECT ' OR Id = ' + CAST(L.Id AS NVARCHAR(32)) 
				 FROM B00Layout L WITH (NOLOCK)
				 WHERE L.FormName = 'MainWindow' AND L.IsTemplate = 0
				 AND NOT EXISTS(
					 SELECT p.LayoutId
					 FROM @UserListTable AS u
					 INNER JOIN B00PermissionLayout AS p ON u.UserId = p.UserId OR u.RoleId = p.RoleId
					 WHERE p.LayoutId = L.Id			 
				 )
				 GROUP BY L.Id
				 FOR XML PATH('')
				), 1, 3, '')
			 			 
			 IF @CmdExpr<>'' SET @openFilterExpr = IIF(@openFilterExpr <> '', @openFilterExpr + ' AND ', '') + ' ( NOT (' + @CmdExpr + '))'
			
         END		 		 		 
	END
	--Kt LOCPC thêm

	INSERT INTO @Result SELECT
		IIF(@openFlag = 1, @openFilterExpr, NULL) AS NoOpen,
		IIF(@editFlag = 1, @editFilterExpr, NULL) AS NoEdit, 
		IIF(@deleteFlag = 1, @deleteFilterExpr, NULL) AS NoDelete, 
		IIF(@recallFlag = 1, @recallFilterExpr, NULL) AS NoRecall, 
		IIF(@addNewFlag = 1, @addNewFilterExpr, NULL) AS NoAddNew;

	SELECT * FROM @Result;	
END;
GO
