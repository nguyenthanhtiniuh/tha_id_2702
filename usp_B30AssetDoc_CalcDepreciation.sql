USE [B10THACOIDACC]
GO

/****** Object:  StoredProcedure [dbo].[usp_B30AssetDoc_CalcDepreciation]    Script Date: 27-02-2026 11:38:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Description:	Tính khấu hao tháng TSCĐ
-- =============================================
ALTER PROCEDURE [dbo].[usp_B30AssetDoc_CalcDepreciation] 
	@_Date			AS DATE	= '20160101',
	@_Year			AS VARCHAR(24)		= '', 
	@_AssetAccount	AS VARCHAR(24)		= '',
	@_AssetId		AS VARCHAR(512)		= '',
	@_AssetType		AS TINYINT			= 0,
	@_Round			AS TINYINT			= 0,
	@_CustomerId	AS VARCHAR(512)		= '',
	@_TransCode		AS VARCHAR(32)		= '',
	@_DocNo			AS VARCHAR(32)		= '',
	@_DetailByAsset AS TINYINT = 0,
	@_AutoDisposals AS TINYINT = 0,
	@_DisposalsTransCode AS VARCHAR(32)	= '',
	@_AutoPostEntry AS TINYINT = 0,
	@_nUserId AS INT = 0,
	@_LangId TINYINT = 0,
	@_BranchCode AS VARCHAR(3) = 'A01',
	@_DeprMethod VARCHAR(24)= '' --- trunght thêm biến này để check
AS
BEGIN
	SET NOCOUNT ON;

	-- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
	SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId)
	--SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode)

	DECLARE @_ErrorMessage NVARCHAR(128)

	SET @_Date = DATEADD(day, 1 - DAY(@_Date), @_Date)

	DECLARE @_DepreciationMethod NVARCHAR(1), @_LineDepreciation TINYINT = 1 -- Tính khấu hao theo đường thẳng

	SELECT @_DeprMethod = ISNULL(@_DeprMethod,'')
	
	IF @_AssetType <> 0
		GOTO _DepreciationMethod1;
	ELSE
	BEGIN		
		-- Khấu hao chạy cả 2 phương pháp cùng 1 lúc, căn cứ vào khai báo PP khấu hao theo tài sản
		IF @_DeprMethod IN ('','1')
			EXECUTE dbo.usp_B30AssetDoc_CalDepreciation1_26022026
				@_Date = @_Date, 
				@_Year = @_Year, 
				@_AssetAccount = @_AssetAccount, 
				@_AssetId = @_AssetId, 
				@_AssetType = @_AssetType,
				@_Round = @_Round, 
				@_LangId = @_LangId,	
				@_nUserId = @_nUserId,
				@_BranchCode = @_BranchCode,
				@_CustomerId = @_CustomerId,
				@_TransCode	= @_TransCode,
				@_DocNo	= @_DocNo,
				@_DetailByAsset = @_DetailByAsset,
				@_AutoDisposals = @_AutoDisposals,
				@_DisposalsTransCode = @_DisposalsTransCode,
				@_DeprMethod = 1
		
		 

		IF @_DeprMethod IN ('','2')
			EXECUTE usp_B30AssetDoc_CalDepreciationPlan2
				@_Date = @_Date, 
				@_Year = @_Year, 
				@_AssetAccount = @_AssetAccount,
				@_AssetId= @_AssetId,
				@_Round = @_Round,
				@_BranchCode = @_BranchCode, 
				@_YearPlan = 0,
				@_nUserId = @_nUserId,
				@_LangId = @_LangId,
				@_CustomerId = @_CustomerId,
				@_TransCode	= @_TransCode,
				@_DocNo	= @_DocNo,
				@_DetailByAsset = @_DetailByAsset,
				@_AutoDisposals = @_AutoDisposals,
				@_DisposalsTransCode = @_DisposalsTransCode
			
		-- Khấu hao theo sản lượng
		IF @_DeprMethod IN ('','3')
			EXECUTE  usp_B30AssetDoc_CalDepreciation3 
				@_Date = @_Date, 
				@_Year = @_Year, 
				@_AssetAccount = @_AssetAccount, 
				@_AssetId = @_AssetId, 
				@_AssetType = @_AssetType,
				@_Round = @_Round, 
				@_LangId = @_LangId,	
				@_nUserId = @_nUserId,
				@_BranchCode = @_BranchCode,
				@_CustomerId = @_CustomerId,
				@_TransCode	= @_TransCode,
				@_DocNo	= @_DocNo,
				@_DetailByAsset = @_DetailByAsset,
				@_AutoDisposals = @_AutoDisposals,
				@_DisposalsTransCode = @_DisposalsTransCode,
				@_DeprMethod = 3

			  

	END

	RETURN;	

_DepreciationMethod2:
	
	EXECUTE usp_B30AssetDoc_CalDepreciationPlan2 
		@_Date = @_Date, 
		@_Year = @_Year, 
		@_AssetAccount = @_AssetAccount,
		@_AssetId= @_AssetId,
		@_Round = @_Round,
		@_BranchCode = @_BranchCode,
		@_YearPlan = 0,
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_CustomerId = @_CustomerId,
		@_TransCode	= @_TransCode,
		@_DocNo	= @_DocNo,
		@_DetailByAsset = @_DetailByAsset,
		@_AutoDisposals = @_AutoDisposals,
		@_DisposalsTransCode = @_DisposalsTransCode
	RETURN;

_DepreciationMethod3:	

	EXECUTE usp_B30AssetDoc_CalDepreciationPlan3
		@_Date = @_Date,
		@_Year = @_Year, 
		@_AssetAccount = @_AssetAccount, 
		@_AssetId= @_AssetId,
		@_Round = @_Round,
		@_BranchCode = @_BranchCode,
		@_YearPlan = 0
	RETURN;

-- Khấu hao theo phương pháp đường thẳng	
_DepreciationMethod1:	

	IF @_LineDepreciation = 1 OR @_AssetType <> 0
	BEGIN 
		
		IF @_DeprMethod IN ('','1')
		EXEC usp_B30AssetDoc_CalDepreciation1 
			@_Date = @_Date, 
			@_Year = @_Year, 
			@_AssetAccount = @_AssetAccount,
			@_AssetId = @_AssetId, 
			@_AssetType = @_AssetType,
			@_Round = @_Round, 
			@_LangId = @_LangId,	
			@_nUserId = @_nUserId,
			@_BranchCode = @_BranchCode,
			@_CustomerId = @_CustomerId,
			@_TransCode	= @_TransCode,
			@_DocNo	= @_DocNo,
			@_DetailByAsset = @_DetailByAsset,
			@_AutoDisposals = @_AutoDisposals,
			@_DisposalsTransCode = @_DisposalsTransCode


		IF @_DeprMethod IN ('','3')
		EXECUTE usp_B30AssetDoc_CalDepreciation3 
				@_Date = @_Date, 
				@_Year = @_Year, 
				@_AssetAccount = @_AssetAccount, 
				@_AssetId = @_AssetId, 
				@_AssetType = @_AssetType,
				@_Round = @_Round, 
				@_LangId = @_LangId,	
				@_nUserId = @_nUserId,
				@_BranchCode = @_BranchCode,
				@_CustomerId = @_CustomerId,
				@_TransCode	= @_TransCode,
				@_DocNo	= @_DocNo,
				@_DetailByAsset = @_DetailByAsset,
				@_AutoDisposals = @_AutoDisposals,
				@_DisposalsTransCode = @_DisposalsTransCode,
				@_DeprMethod = 3		 

		RETURN; 
	END
 
	 
 
  
 
	RETURN;
END
GO

