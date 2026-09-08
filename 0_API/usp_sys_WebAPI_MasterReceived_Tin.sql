USE [B10THACOID]
GO
/****** Object:  StoredProcedure [dbo].[usp_sys_WebAPI_MasterReceived_Tin]    Script Date: 2026-08-27 4:48:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--=============================================================
--Thủ tục nhận đầu vào các loại API: Danh mục, chứng từ
--=============================================================
ALTER PROCEDURE [dbo].[usp_sys_WebAPI_MasterReceived_Tin]
	@_JsonData nvarchar(MAX)	= '',
	@_ClientInfo varchar(64)	= '',
	@_Type varchar(64)			= '',
	@_Id_APILog bigint =0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @_RowId_Api varchar(24), 
			@_ApiType tinyint, 
			@_ApiClass char(1), 
			@_ApiExecute varchar(10), 
			@_CommandType nvarchar(50),
			@_BranchMES varchar(24),
			@_BranchCode varchar(24);	
	
	--:> Lấy thông tin cấu hình
	SELECT TOP (1) @_RowId_Api = RowId, 
			@_ApiType = ApiType, 
			@_ApiClass = ApiClass,
			@_ApiExecute = ApiExecute
		FROM dbo.B00ApiProvider (NoLock) 
		WHERE Code = @_Type AND IsActive =1;

	--:> Không hỗ trợ Type
	IF (ISNULL(@_RowId_Api,'')='')
	BEGIN
		SELECT '999' AS Status, (dbo.ufn_sys_WebAPI_GetResultName('01','999',0)+N'(ApiProvider)') AS Message, @_ClientInfo AS ClientInfo;
		RETURN;
	END

	--:> Check CommandType
	SET @_CommandType = JSON_VALUE(@_JsonData, '$.CommandType');
	IF (ISNULL(@_CommandType,'')='')
	BEGIN
		SELECT '999' AS Status, (dbo.ufn_sys_WebAPI_GetResultName('01','999',0)+N'(CommandType)') AS Message, @_ClientInfo AS ClientInfo;
		RETURN;
	END

	--:> Check @_BranchMES
	SET @_BranchMES = JSON_VALUE(@_JsonData, '$.BranchCode');
	IF (@_BranchMES <> '' AND @_ApiClass ='2' AND @_CommandType ='GET') OR (@_Type ='Asset')
	BEGIN
		SELECT TOP (1) @_BranchCode = BranchCode 
			FROM dbo.B00BranchMES (NoLock) 
			WHERE BranchMES = @_BranchMES AND IsActive =1;

		IF (ISNULL(@_BranchCode,'')='')
		BEGIN
			SELECT '999' AS Status, (dbo.ufn_sys_WebAPI_GetResultName('01','999',0)+N'(BranchCode)') AS Message, @_ClientInfo AS ClientInfo;
			RETURN;
		END
	END

	--:> Không hỗ trợ Realtime
	IF NOT EXISTS(SELECT Value FROM STRING_SPLIT(@_ApiExecute,',') WHERE value ='1')
	BEGIN
		INSERT INTO B00ApiEventLog (ApiName,Body,Response)
		SELECT @_Type, @_JsonData, 
			JSON_QUERY((SELECT '999' AS Status, 
							(dbo.ufn_sys_WebAPI_GetResultName('01','999',0)+N'(Realtime)') AS Message, 
							@_ClientInfo AS ClientInfo 
						FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
					  );
		SELECT '999' AS Status, (dbo.ufn_sys_WebAPI_GetResultName('01','999',0)+N'(Realtime)') AS Message, @_ClientInfo AS ClientInfo;
		RETURN;
	END

	--:> Insert log API trước
	IF ISNULL(@_Id_APILog,0) =0 AND @_Type NOT IN ('BizDocD0','BizDocD1','BizDocCM')
	BEGIN
		INSERT INTO B00ApiEventLog (ApiName,Body)
		SELECT @_Type, @_JsonData;
		----:> Lấy Id
		SELECT @_Id_APILog = IDENT_CURRENT('B00ApiEventLog');
	END

	--PRINT @_RowId_Api; PRINT @_CommandType; PRINT @_Id_APILog

	--:0=> Xử lý danh mục
	IF (@_ApiClass ='0')
	BEGIN
		Print N'0. Danh mục';

		IF @_CommandType ='GET' AND @_Type ='Asset'
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_biz_WebAPI_B20AssetSendGet]
				@_JsonData = @_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_Type = @_Type,
				@_RowId_Api = @_RowId_Api,
				@_CommandType = @_CommandType,
				@_BranchCode = @_BranchCode,
				@_Id_APILog = @_Id_APILog;
			RETURN;
		END 


		--: GET: Thaco Get danh mục
		IF @_CommandType ='GET'
		BEGIN
			EXECUTE [dbo].[usp_sys_WebAPI_CategoryReceiveGet]
				@_JsonData = @_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_Type = @_Type,
				@_RowId_Api = @_RowId_Api,
				@_CommandType = @_CommandType,
				@_Id_APILog = @_Id_APILog;
			RETURN;
		END 

		--: ZQTCNSTEP:  Cấu hình công nghệ
		IF @_Type ='ZQTCNSTEP'
		BEGIN
			EXECUTE B10THACOIDACC.[dbo].[usp_acc_WebAPI_TechConfigReceive]
				@_JsonData =@_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_RowId_Api =@_RowId_Api,
				@_Type = @_Type,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;		
			RETURN;
		END 

		--: ZQTCN:  Quy Trình công nghệ BOM
		IF @_Type IN ('ZBOM','ZQTCN')
		BEGIN
			--EXECUTE B10THACOIDACC.[dbo].[usp_acc_WebAPI_ZCostReceive]
			--	@_JsonData =@_JsonData,
			--	@_ClientInfo = @_ClientInfo,
			--	@_RowId_Api =@_RowId_Api,
			--	@_Type = @_Type,
			--	@_CommandType =@_CommandType,
			--	@_Id_APILog =@_Id_APILog;	
			EXECUTE B10THACOIDACC.[dbo].[usp_acc_WebAPI_TechProcessReceive]
				@_JsonData =@_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_RowId_Api =@_RowId_Api,
				@_Type = @_Type,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;	
			RETURN;
		END 

		--:Item: Danh mục sản phẩm
		IF @_Type ='Item'
		BEGIN
			EXECUTE [dbo].[usp_sys_WebAPI_CategoryItemReceive]
				@_JsonData =@_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_RowId_Api =@_RowId_Api,
				@_Type = @_Type,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;		
			RETURN;
		END 

		--:> Danh mục sản phẩm
		--IF @_Type ='Product'
		--BEGIN
		--	--EXECUTE [dbo].[usp_sys_WebAPI_ProductReceive]
		--	--	@_JsonData =@_JsonData,
		--	--	@_ClientInfo = @_ClientInfo,
		--	--	@_RowId_Api =@_RowId_Api,
		--	--	@_Type = @_Type,
		--	--	@_CommandType =@_CommandType,
		--	--	@_Id_APILog =@_Id_APILog;		
		--	RETURN;
		--END ELSE


		--:: ZWorkCenter: Danh mục ZWorkCenter
		IF @_Type ='ZWorkCenter'
		BEGIN
			EXECUTE [dbo].[usp_sys_WebAPI_ZWorkCenterReceive]
				@_JsonData =@_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_RowId_Api =@_RowId_Api,
				@_Type = @_Type,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;		
			RETURN;
		END 

		--:> Xử lý dùng chung
		BEGIN
			EXECUTE [dbo].[usp_sys_WebAPI_CategoryReceive]
				@_JsonData =@_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_RowId_Api =@_RowId_Api,
				@_Type = @_Type,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;		
			RETURN;
		END
		
		RETURN;
	END ELSE
	
	--:1> Tài liệu kinh doanh
	IF @_ApiClass ='1'
	BEGIN
		Print N'0. Tài liệu kinh doanh';

		--:> GET: dữ liệu QLMH từ Bravo 8
		IF @_CommandType ='GET'
		BEGIN
			EXECUTE [dbo].[usp_sys_WebAPI_BizDocD0ReceiveGet]
				@_JsonData = @_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_Type = @_Type,
				@_RowId_Api = @_RowId_Api,
				@_CommandType = @_CommandType,
				@_Id_APILog = @_Id_APILog;	
			RETURN;
		END 

		--: GETDETAIL: Get dữ liệu mua hàng từ Bravo 10
		IF @_CommandType ='GETDETAIL' AND @_Type IN ('BizDocPF','BizDocD0','BizDocD1')
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_biz_WebAPI_B40BizDocSendGet]
				@_JsonData = @_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_Type = @_Type,
				@_RowId_Api = @_RowId_Api,
				@_CommandType = @_CommandType,
				@_Id_APILog = @_Id_APILog;	
			RETURN;
		END 
				
		--: Duyệt chứng từ
		IF @_CommandType ='APPROVAL' AND @_Type IN ('BizDocD0','BizDocD1','BizDocCM')
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_biz_WebAPI_B40BizDocSendApproval]
				@_JsonData =@_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_RowId_Api =@_RowId_Api,
				@_Type = @_Type,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;		
			RETURN;
		END 

		--: FinPlan: Kế hoạch doanh thu 
		IF @_Type ='FinPlan'
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_biz_WebAPI_FinPlanReceive]
				@_JsonData =@_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_RowId_Api =@_RowId_Api,
				@_Type = @_Type,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;		
			RETURN;
		END 

		--: SummarySheet: 
		IF @_Type ='SummarySheet'
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_biz_WebAPI_SummarySheetReceive]
				@_JsonData =@_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_RowId_Api =@_RowId_Api,
				@_Type = @_Type,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;		
			RETURN;
		END 

		--: PackageDoc: 
		IF @_Type ='PackageDoc'
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_biz_WebAPI_ZPackageDocReceive]
				@_JsonData =@_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_RowId_Api =@_RowId_Api,
				@_Type = @_Type,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;		
			RETURN;
		END 

		--: ZMoldDoc: 
		IF @_Type ='ZMoldDoc'
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_biz_WebAPI_ZMoldDocReceive]
				@_JsonData =@_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_RowId_Api =@_RowId_Api,
				@_Type = @_Type,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;		
			RETURN;
		END 

		--: AllBizDoc: Tất cả bizdoc
		DECLARE @_DocType varchar(24) = JSON_VALUE(@_JsonData, '$.DocType');
		IF @_Type ='AllBizDoc'
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_acc_WebAPI_AllBizDocReceive]
				@_JsonData =@_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_RowId_Api =@_RowId_Api,
				@_Type = @_Type,
				@_CommandType =@_CommandType,
				@_DocType =@_DocType,
				@_Id_APILog =@_Id_APILog;		
			RETURN;
		END 

		--IF @_Type IN ('BizDocD0','BizDocD1','BizDocCM')
		--BEGIN
		--	EXECUTE [B10THACOIDACC].[dbo].[usp_acc_WebAPI_B8BizDocReceive]
		--			@_JsonData =@_JsonData,
		--			@_ClientInfo = @_ClientInfo,
		--			@_RowId_Api =@_RowId_Api,
		--			@_Type = @_Type,
		--			@_CommandType =@_CommandType,
		--			@_DocType =@_DocType,
		--			@_Id_APILog =@_Id_APILog;		
		--		RETURN;
		--END

		--: BizDoc (BizDocC2,BizDocCx): dùng chung cho tất cả bizdoc
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_biz_WebAPI_BizDocAllReceive]
				@_JsonData =@_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_RowId_Api =@_RowId_Api,
				@_Type = @_Type,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;		
			RETURN;
		END;

		RETURN;
	END;

	--:2> Tài liệu kinh doanh
	IF @_ApiClass ='2'
	BEGIN
		Print N'0. Chứng từ kế toán';

		--:> GET dữ liệu từ Thaco
		IF @_CommandType ='GET'
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_acc_WebAPI_AccDocReceiveGet]
				@_JsonData = @_JsonData,
				@_ClientInfo = @_ClientInfo,
				@_Type = @_Type,
				@_RowId_Api = @_RowId_Api,
				@_CommandType = @_CommandType,
				@_BranchCode =@_BranchCode,
				@_Id_APILog = @_Id_APILog;	

			RETURN;
		END;

		--:> Nhập mua, nhập khẩu
		IF @_Type ='AccDocNK'
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_acc_WebAPI_AccDocPurchaseReceive]
				@_JsonData = @_JsonData,
				@_ClientInfo =@_ClientInfo,
				@_Type =@_Type,
				@_RowId_Api =@_RowId_Api,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;

			RETURN;
		END

		--:> Trả nhà cung cấp
		IF @_Type ='AccDocXT'
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_acc_WebAPI_AccDocReturnedReceive]
				@_JsonData = @_JsonData,
				@_ClientInfo =@_ClientInfo,
				@_Type =@_Type,
				@_RowId_Api =@_RowId_Api,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;

			RETURN;
		END

		--:> Nhập kho nội bộ, nhập kho, nhập BTP/TP, xuất kho, điều chuyển
		IF @_Type IN ('AccDocNB','AccDocPN','AccDocTP','AccDocPX','AccDocDC')
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_acc_WebAPI_AccDocItemReceive]
				@_JsonData = @_JsonData,
				@_ClientInfo =@_ClientInfo,
				@_Type =@_Type,
				@_RowId_Api =@_RowId_Api,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;

			RETURN;
		END

		--> Hoá đơn
		--IF @_Type ='AccDocLR'
		--BEGIN
		--	EXECUTE [B10THACOIDACC].[dbo].[usp_acc_WebAPI_AccDocItemLRReceive]
		--		@_JsonData = @_JsonData,
		--		@_ClientInfo =@_ClientInfo,
		--		@_Type =@_Type,
		--		@_RowId_Api =@_RowId_Api,
		--		@_CommandType =@_CommandType,
		--		@_Id_APILog =@_Id_APILog;

		--	RETURN;
		--END

		--> Hoá đơn
		IF @_Type ='AccDocHD'
		BEGIN
			EXECUTE [B10THACOIDACC].[dbo].[usp_acc_WebAPI_AccDocSalesReceive]
				@_JsonData = @_JsonData,
				@_ClientInfo =@_ClientInfo,
				@_Type =@_Type,
				@_RowId_Api =@_RowId_Api,
				@_CommandType =@_CommandType,
				@_Id_APILog =@_Id_APILog;

			RETURN;
		END

		RETURN;
	END;
	
	--:2=> Báo cáo
	IF @_ApiClass ='3'
	BEGIN
		--Trả báo cáo: Dùng cho tất cả các báo cáo
		EXECUTE [B10THACOIDACC].[dbo].[usp_sys_WebAPI_ApiReportQuery_Tin]
			@_JsonData = @_JsonData,
			@_ClientInfo = @_ClientInfo,
			@_Type = @_Type,
			@_RowId_Api = @_RowId_Api,
			@_CommandType = @_CommandType,
			@_Id_APILog = @_Id_APILog;
	END
END
GO
dbo.usp_sys_WebAPI_MasterReceived_Tin @_JsonData = N'{
  "Type": "ApiReport20",
  "CommandType": "GET",
  "Parameter": [
    {
      "FromDate": "01/01/2026",
      "ToDate": "31/01/2026",
      "BranchCode": "CASC"
    }
  ]
}

',
                                      @_ClientInfo = '',
                                      @_Type = 'ApiReport20',
                                      @_Id_APILog = 0