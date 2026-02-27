USE [B10THACOIDACC]
GO

/****** Object:  StoredProcedure [dbo].[usp_B30AssetDoc_CalDepreciation3]    Script Date: 27-02-2026 11:41:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- Coder: VuLA

-- =============================================
-- Description: Tính khấu hao tháng TSCĐ - theo PP đường thẳng
-- Chú ý sau:
-- Biến động thời gian sử dụng tài sản: chương trình sẽ tính toán bắt đầu từ thời điểm đầu tháng phát sinh
-- Tình huống: Tài sản phát sinh cũ khi nhập vào chương trình như sau:
--  Tài sản tăng 01/05/2011 giá trị 1.2 tỷ
--   đến ngày 31/12/2019 đã trích 1.030 tỷ
--  đến ngày 01/01/2020:nhập liệu vào chương trình như sau:
--  Tài sản tăng:  01/05/2011 giá trị 1.2 tỷ
--   chi tiết tăng: 01/05/2011 giá trị 1.2 tỷ đã khấu hao 1.030 tỷ
--   trong tình huống này chương trình sẽ tính theo nguyên giá chia thời gian sử dụng tài sản 
-- =============================================
ALTER    PROCEDURE  [dbo].usp_B30AssetDoc_CalDepreciation3_26022026 
	 @_Date AS DATE = '20280331',
	 @_Year AS VARCHAR(24) = '2028', 
	 @_AssetAccount AS VARCHAR(24) = '',
	 @_AssetId AS VARCHAR(512) = '',--'Z1',
	 @_AssetType AS TINYINT = 0,
	 @_Round AS TINYINT = 0,
	 @_CustomerId  AS VARCHAR(512) = '',
	 @_TransCode AS VARCHAR(32) = '',
	 @_DocNo AS VARCHAR(32) = '',
	 @_DetailByAsset AS BIT = 0,
	 @_AutoDisposals AS BIT = 0,
	 @_DisposalsTransCode AS VARCHAR(32) = '',
	 @_AutoPostEntry AS BIT = 0,
	 @_LangId TINYINT = 0,
	 @_nUserId INT = 0,
	 @_DeprMethod TINYINT = 1, -- 1: Khấu hao đường thằng, 3-Khấu hao theo sản lượng
	 @_BranchCode AS CHAR(3) = 'A01'
AS
BEGIN
	SET NOCOUNT ON;
 
	DECLARE @_DataCode_Branch VARCHAR(8),@_nl CHAR(1)=CHAR(10)
	DECLARE @_Cmd NVARCHAR(MAX),@_Declare NVARCHAR(MAX)
	SELECT TOP 1 @_DataCode_Branch = DataCode FROM B00Branch WHERE BranchCode = @_BranchCode;
	SET @_DataCode_Branch = ISNULL(@_DataCode_Branch, '0')

	SET @_Date = DATEADD(day, 1 - DAY(@_Date), @_Date)

	SELECT @_AssetAccount = LTRIM(RTRIM(ISNULL(@_AssetAccount, ''))),
	@_AssetId = LTRIM(RTRIM(ISNULL(@_AssetId, '')))

	DECLARE @_DocDate1 AS DATE = @_Date, @_DocDate2 AS DATE = EOMONTH(@_Date), 
			@_M_PP_Pb_CCDC VARCHAR(24) = ISNULL(dbo.ufn_vB00Config_GetValue('M_PP_Pb_CCDC', @_BranchCode), '1')

	DECLARE @_ProgUsedFirstDay DATE = (SELECT TOP 1 StartDate FROM B00FiscalYear WHERE BranchCode = @_BranchCode ORDER BY StartDate ASC)

	DECLARE @_FirstDayOfYear DATE, @_EndDayOfYear DATE, @_FirstDayOfAccounting DATE, 
	@_FiscalYear VARCHAR(24) = dbo.ufn_B00FiscalYear_GetName(@_DocDate2, @_BranchCode)

	SELECT @_FirstDayOfYear = dbo.ufn_B00FiscalYear_GetStartDate(@_DocDate1, @_BranchCode), 
	@_EndDayOfYear = dbo.ufn_B00FiscalYear_GetEndDate(@_DocDate2, @_BranchCode), 
	@_FirstDayOfAccounting = dbo.ufn_B00FiscalYear_GetFirstUsingDate(@_FiscalYear, @_BranchCode);

	DECLARE @_StartedDate Date = dbo.ufn_B00FiscalYear_GetStartedDate(@_BranchCode), 
	@_StartedUsingDate Date = dbo.ufn_B00FiscalYear_GetStartedUsingDate(@_BranchCode)
 

	DROP TABLE IF EXISTS #t_DmTs;
	SELECT TOP 0
		   CAST(0 AS INT) AS Id,
		   Code,
		   Name,
		   FirstDeprDate, -- Ngày bắt đầu khấu hao (Ngày chương trình tính thời gian khấu hao)
		   FirstUsedDate, -- Ngày bắt đầu sử dụng  (Ngày đưa vào sử dụng của TS - có thể sau ngày bắt đầu khấu hao)
		   StandbyForDisposal,
		   CAST(NULL AS DATE) AS LastDeprDate,
		   CAST(0 AS INT) AS UsefulMonth,
		   CAST(0 AS NUMERIC(18, 2)) AS ProductionCapacity,
		   CAST(0 AS INT) AS AllocateByCapacity,
		   CAST(NULL AS DATE) AS LastSuspendDate,
		   CAST(NULL AS DATE) AS LastResumeDate,
		   Type,
		   DeprMethod
	INTO #t_DmTs
	FROM B20Asset WITH (NOLOCK)
 
	SET @_Cmd = N'WITH GiamTs -- Lấy danh sách TSCĐ đến thời điểm lên báo cáo'+@_nl+
	'	AS'+@_nl+
	'	('+@_nl+
	'		SELECT AssetId, DocDate AS DecreaseDate, AssetTransId AS DecreaseAssetCode'+@_nl+
	'			FROM B3' + @_DataCode_Branch + N'AssetDoc '+@_nl+
	'				WHERE AssetTransType = N''GIAMTAISAN'' AND IsActive = 1'+@_nl+
	'	),'+@_nl+
	'	SuspendDepreciation  -- Tài sản tạm dừng khấu hao'+@_nl+
	'	AS'+@_nl+
	'	( SELECT AssetId, MAX(DocDate) AS LastTransDate'+@_nl+
	'			FROM vB3' + @_DataCode_Branch + N'AssetDoc_SuspendDepreciation'+@_nl+
	'				WHERE DocDate <= @_DocDate2 AND IsActive = 1'+@_nl+
	'				GROUP BY AssetId'+@_nl+
	'	),'+@_nl+
	'	ResumeDepreciation -- Tài sản tiếp tục khấu hao sau khi tạm dừng'+@_nl+
	'	AS'+@_nl+
	'	( SELECT AssetId, MAX(DocDate) AS LastTransDate'+@_nl+
	'			FROM vB3' + @_DataCode_Branch + N'AssetDoc_ResumeDepreciation'+@_nl+
	'				WHERE DocDate <= @_DocDate2 AND IsActive = 1'+@_nl+
	'				GROUP BY AssetId'+@_nl+
	'	)'+@_nl+
	'	INSERT #t_DmTs(Id,Code,Name,FirstDeprDate,FirstUsedDate,StandbyForDisposal,LastDeprDate,UsefulMonth,'+@_nl+
	'					ProductionCapacity,AllocateByCapacity,LastSuspendDate,LastResumeDate,Type,DeprMethod)'+@_nl+
	'	SELECT	dmts.Id, dmts.Code, dmts.Name,'+@_nl+
	'			dmts.FirstDeprDate,   -- Ngày bắt đầu khấu hao (Ngày chương trình tính thời gian khấu hao)'+@_nl+
	'			dmts.FirstUsedDate,   -- Ngày bắt đầu sử dụng  (Ngày đưa vào sử dụng của TS - có thể sau ngày bắt đầu khấu hao)'+@_nl+
	'			dmts.StandbyForDisposal,'+@_nl+
	'			CAST(NULL AS DATE) AS LastDeprDate,'+@_nl+
	'			IIF(IIF(ISNULL(dmts.DeprMethod, 1) = 3, 1, 0) = 1, 0, dmts.UsefulYear*12 + dmts.UsefulMonth) AS UsefulMonth,'+@_nl+
	'			CAST(0 AS NUMERIC(18, 2)) AS ProductionCapacity, '+@_nl+
	'			IIF(ISNULL(dmts.DeprMethod, 1) = 3, 1, 0) AllocateByCapacity,'+@_nl+
	'			SuspendDate.LastTransDate AS LastSuspendDate, '+@_nl+
	'			ResumeDate.LastTransDate AS LastResumeDate,dmts.Type,dmts.DeprMethod '+@_nl+
	'			FROM B2' + @_DataCode_Branch + N'Asset dmts'+@_nl+
	'				LEFT JOIN GiamTs ON dmts.Id = giamTs.AssetId'+@_nl+
	'				LEFT JOIN SuspendDepreciation AS SuspendDate ON DmTs.Id = SuspendDate.AssetId'+@_nl+
	'				LEFT JOIN ResumeDepreciation AS ResumeDate ON DmTs.Id = ResumeDate.AssetId'+@_nl+
	'			WHERE dmts.BranchCode = @_BranchCode AND '+@_nl+
	'					(ISNULL(dmts.FirstDeprDate, '''') <> '''' AND dmts.FirstDeprDate <= @_DocDate2) AND'+@_nl+
	'					(ISNULL(giamTs.DecreaseDate, '''') = '''' OR giamTs.DecreaseDate >= @_DocDate1) AND -- Chỉ lấy TS chưa giảm hoặc đã giảm nhưng sau ngày 1 '+@_nl+
	'					(ISNULL(giamTs.DecreaseDate, '''') BETWEEN @_DocDate1 AND @_DocDate2 OR ISNULL(SuspendDate.LastTransDate, '''') = '''' OR ISNULL(ResumeDate.LastTransDate, '''') > ISNULL(SuspendDate.LastTransDate, ''''))  -- Kết thúc tháng nào thì không tính tháng đó luôn'+@_nl+
	'					AND dmts.AssetAccount LIKE @_AssetAccount + ''%'' '+@_nl+
	'					AND ( CHARINDEX(TRIM(STR(dmts.Id)) , @_AssetId) >=1 OR ISNULL(@_AssetId, '''') = '''')  '+@_nl+
	'					AND dmts.Type = @_AssetType AND dmts.IsActive = 1 '+@_nl+
	'					AND dmts.DeprMethod = @_DeprMethod '
  
	EXECUTE sp_executesql @_cmd, 
			N'	@_AssetAccount VARCHAR(24),@_AssetId VARCHAR(512),@_AssetType VARCHAR(24),@_BranchCode VARCHAR(24),@_DeprMethod VARCHAR(24),@_DocDate1 DATE,@_DocDate2 DATE',
				@_AssetAccount,@_AssetId,@_AssetType,@_BranchCode, @_DeprMethod,@_DocDate1,@_DocDate2
  
	-- 25-08-2022 ThắngĐQ: TSCĐ sẽ coi điều chỉnh khấu hao cũng là 1 biến động để tính lại giá trị khấu hao = giá trị còn lại / số tháng còn lại
	-- Mô tả theo PS số 1037728 của QuangLM, nếu không muốn tính GD này là biến động thì để lại theo đoạn như CCDC
	-- Nếu không coi điều chỉnh thủ công khấu hao là 1 biến động: Khi tăng, giảm tài sản việc tính khấu hao sẽ tính ra giá trị không hợp lý

	-- Lấy danh sách mã nguồn + mã tài sản có biến động cuối cùng trước ngày ct 1
	DROP TABLE IF EXISTS #t_BienDongCuoi;
	SELECT TOP 0 AssetId,CAST('' AS NVARCHAR(24)) AS AssetCode, EquityId, 
	CAST(NULL AS DATE) AS LastDayFluctuations,
	CAST(NULL AS DATE) AS LastDayFluctuations0,
	CAST(0 AS Bit) AS ChkLastDayFluctuations
	INTO #t_BienDongCuoi
	FROM B30AssetDoc WITH (NOLOCK)
 
	IF @_AssetType = 0 -- Tính khấu hao TSCĐ
	BEGIN
	SET @_Cmd = N'INSERT #t_BienDongCuoi (AssetId,AssetCode, EquityId, LastDayFluctuations, LastDayFluctuations0, ChkLastDayFluctuations)  '+@_nl+
				N'	SELECT	ctts.AssetId,dmts.Code AS AssetCode, ctts.EquityId,  '+@_nl+
				N'			CAST(MAX(TaOriginalCost.LastDayFluctuations) AS DATE) AS LastDayFluctuations, '+@_nl+
				N'			CAST(MAX(TaOriginalCost.LastDayFluctuations) AS DATE) AS LastDayFluctuations0, '+@_nl+
				N'			CAST(0 AS Bit) AS ChkLastDayFluctuations '+@_nl+
				N'	FROM vB3' + @_DataCode_Branch + N'AssetDoc ctts '+@_nl+
				N'				INNER JOIN #t_DmTs dmts ON ctts.AssetId = dmts.Id  '+@_nl+
				N'				LEFT JOIN  -- Lấy danh sách biến động tài sản trước ngày Ct1 '+@_nl+
				N'				( '+@_nl+
				N'					SELECT tg.AssetId, tg.EquityId,  '+@_nl+
				N'							IIF(tg.AssetTransType = ''KHAUHAO'', DATEADD(day, 1, tg.DocDate), tg.DocDate) AS LastDayFluctuations, '+@_nl+
				N'							ROW_NUMBER() OVER (PARTITION BY tg.AssetId, tg.EquityId ORDER BY DocDate DESC) AS _rId '+@_nl+
				N'							FROM B3' + @_DataCode_Branch + N'AssetDoc tg '+@_nl+
				N'							LEFT JOIN dbo.B20AssetTrans dmtgts ON tg.AssetTransId = dmtgts.Id '+@_nl+
				N'							WHERE ((AssetTransType <> ''KHAUHAO'' AND tg.DeprAllocationRate = 0) -- Không phải là khấu hao và chỉnh hệ số '+@_nl+
				N'								OR (AssetTransType = ''KHAUHAO'' AND (tg.isDeprAdjusted = 1 OR tg.CustomFlag = 1)) -- Khấu hao & tự sửa '+@_nl+
				N'				) -- Khấu hao & trước khi sử dụng chương trình  '+@_nl+
				N'					AND tg.DocDate < @_DocDate1 AND tg.IsActive = 1 '+@_nl+
				N'					) AS TaOriginalCost ON ctts.AssetId = TaOriginalCost.AssetId AND ctts.EquityId = TaOriginalCost.EquityId AND TaOriginalCost._rId = 1 '+@_nl+
				N'	WHERE ctts.DocDate <= @_DocDate2 AND ctts.IsActive = 1 '+@_nl+
				N'	GROUP BY ctts.AssetId,dmts.Code, ctts.EquityId'
	--PRINT @_Cmd
	EXECUTE sp_executesql @_cmd,N'@_DocDate1 DATE, @_DocDate2 DATE',@_DocDate1,@_DocDate2  
	END 
 ELSE
	BEGIN
	-- PÁ trước, không coi sửa khấu hao là biến động
	SET @_Cmd = N'INSERT #t_BienDongCuoi (AssetId,AssetCode, EquityId, LastDayFluctuations, LastDayFluctuations0, ChkLastDayFluctuations)  '+@_nl+
				N'	SELECT	ctts.AssetId,dmts.Code AS AssetCode, ctts.EquityId,  '+@_nl+
				N'			CAST(MAX(TaOriginalCost.LastDayFluctuations) AS DATE) AS LastDayFluctuations, '+@_nl+
				N'			CAST(MAX(TaOriginalCost.LastDayFluctuations) AS DATE) AS LastDayFluctuations0, '+@_nl+
				N'			CAST(0 AS Bit) AS ChkLastDayFluctuations '+@_nl+
				N'				FROM vB3' + @_DataCode_Branch + N'AssetDoc ctts '+@_nl+
				N'					INNER JOIN #t_DmTs dmts ON ctts.AssetId = dmts.Id   '+@_nl+
				N'					LEFT OUTER JOIN  -- Lấy danh sách biến động tài sản trước ngày Ct1 '+@_nl+
				N'					( '+@_nl+
				N'						SELECT tg.AssetId, tg.EquityId,  '+@_nl+
				N'								IIF(tg.AssetTransType = ''KHAUHAO'', DATEADD(day, 1, tg.DocDate), tg.DocDate) AS LastDayFluctuations, '+@_nl+
				N'								ROW_NUMBER() OVER (PARTITION BY tg.AssetId, tg.EquityId ORDER BY DocDate DESC) AS _rId '+@_nl+
				N'						FROM B3' + @_DataCode_Branch + N'AssetDoc tg '+@_nl+
				N'					LEFT OUTER JOIN dbo.B20AssetTrans dmtgts ON tg.AssetTransId = dmtgts.Id '+@_nl+
				N'			WHERE tg.AssetTransType NOT IN (''KHAUHAO'') '+@_nl+
				N'				AND (tg.DeprAllocationRate = 0) -- Loại trừ nhập hệ số phân bổ  '+@_nl+
				N'						-- Chú ý nếu điều chỉnh vào ngày đầu tháng tính (01) '+@_nl+
				N'						-- thì khấu hao sẽ tính bằng GTCL / thời gian sử dụng còn lại '+@_nl+
				N'				AND tg.DocDate <= @_DocDate1 AND tg.IsActive = 1  '+@_nl+
				N'				AND dmtgts.Type <> ''3'' -- Không lấy loại = 3 '+@_nl+
				N'					) AS TaOriginalCost ON ctts.AssetId = TaOriginalCost.AssetId AND ctts.EquityId = TaOriginalCost.EquityId AND TaOriginalCost._rId = 1 '+@_nl+
				N'			WHERE ctts.DocDate <= @_DocDate2 AND ctts.IsActive = 1 '+@_nl+
				N'			GROUP BY ctts.AssetId,dmts.Code, ctts.EquityId'
  
	EXECUTE sp_executesql @_cmd,N'@_DocDate1 DATE, @_DocDate2 DATE',@_DocDate1,@_DocDate2
	END

 
 
	 -- Xử lý riêng ngày biến động cuối cùng
	 -- Việc tính khấu hao đưa hết vào thời điểm ngày cuối cùng của tháng
	 -- Việc tính gt khấu hao đến thời điểm biến động cuối cùng (GT còn lại / thời gian còn lại) sẽ không đúng
	 -- vì giá trị còn lại đến thời điểm biến động cuối không có khấu hao trích đến thời điểm đó
	 -- Loại trường hợp trong tháng đó có tính khấu hao
	 SET @_cmd = N' UPDATE #t_BienDongCuoi 
		   SET ChkLastDayFluctuations = 1
		   FROM #t_BienDongCuoi bd
		   INNER JOIN B3' + @_DataCode_Branch + N'AssetDoc ts ON bd.AssetId = ts.AssetId 
				   AND bd.EquityId = ts.EquityId AND ts.IsActive = 1 
				   AND ts.DocDate BETWEEN bd.LastDayFluctuations 
				   --AND DATEADD(day, -1, DATEADD(m, 1, CONVERT(DATE, ''01/'' + STR(MONTH(bd.LastDayFluctuations), 2) + ''/'' + STR(YEAR(bd.LastDayFluctuations), 4), 103)))
					 AND DATEADD(DAY,-1,DATEADD(m,1,FORMAT(bd.LastDayFluctuations,''yyyyMM01'')))
				   AND ts.AssetTransType = ''KHAUHAO''
				   AND ISNULL(IsDeprAdjusted, 0) = 0
		 WHERE DAY(bd.LastDayFluctuations) <> 1'
	 EXECUTE sp_executesql @_cmd
  
	 -- Xử lý tính huống ngày bắt đầu hạch toán lớn hơn ngày bắt đầu năm thì đối với những biến động
	 --  trước ngày bắt đầu hạch toán được quy về số dư đến ngày bắt đầu hạch toán để tính
	 --  Nếu ko sử dụng cái này thì bỏ
	IF @_StartedUsingDate > @_StartedDate
	BEGIN
    
		UPDATE #t_BienDongCuoi 
		SET LastDayFluctuations = @_StartedUsingDate 
		WHERE LastDayFluctuations < @_StartedUsingDate 
   
	END
 
	-- Số tháng sử dụng tài sản 
	DROP TABLE IF EXISTS #SoThangSd;
	SELECT TOP 0 ctts.AssetId,dmts.Code AS AssetCode, ctts.EquityId,MAX(DocDate) AS DocDate, 
			SUM(CASE WHEN ctts.DocGroup = '2' THEN -1 ELSE 1 END * ctts.UsefulMonth) AS UsefulMonth,
			SUM(CASE WHEN ctts.DocDate < @_DocDate1 THEN ctts.UsefulMonth ELSE 0 END) AS UsefulMonth0,
			SUM(CASE WHEN ctts.UsefulMonth <> 0 THEN 1 ELSE 0 END) AS ChangeInMonth0,
			SUM(CASE WHEN ctts.DocDate >= @_DocDate1 THEN ctts.UsefulMonth ELSE 0 END) AS UsefulMonthAcc,
			SUM(CASE WHEN ctts.DocGroup = '2' THEN -1 ELSE 1 END * ctts.ProductionCapacity) AS ProductionCapacity,
			SUM(CASE WHEN ctts.DocDate < @_DocDate1 THEN ctts.ProductionCapacity ELSE 0 END) AS ProductionCapacity0,
			SUM(CASE WHEN ctts.ProductionCapacity <> 0 THEN 1 ELSE 0 END) AS ChangeInMonth1,
			SUM(CASE WHEN ctts.DocDate >= @_DocDate1 THEN ctts.ProductionCapacity ELSE 0 END) AS ProductionCapacityAcc
	INTO #SoThangSd 
	FROM B30AssetDoc ctts WITH (NOLOCK) INNER JOIN #t_DmTs dmts ON ctts.AssetId = dmts.Id 
	GROUP BY ctts.AssetId, dmts.Code,ctts.EquityId
 
	 SET @_Cmd = N'INSERT INTO #SoThangSd(AssetId,AssetCode,EquityId,DocDate,UsefulMonth,UsefulMonth0,ChangeInMonth0,UsefulMonthAcc,
					ProductionCapacity,ProductionCapacity0,ChangeInMonth1,ProductionCapacityAcc)

					SELECT ctts.AssetId,dmts.Code AS AssetCode, ctts.EquityId, MAX(DocDate) AS DocDate,
					SUM(CASE WHEN ctts.DocGroup = ''2'' THEN -1 ELSE 1 END * ctts.UsefulMonth) AS UsefulMonth,
					SUM(CASE WHEN ctts.DocDate < @_DocDate1 THEN ctts.UsefulMonth ELSE 0 END) AS UsefulMonth0,
					SUM(CASE WHEN ctts.UsefulMonth <> 0 THEN 1 ELSE 0 END) AS ChangeInMonth0,
					SUM(CASE WHEN ctts.DocDate >= @_DocDate1 THEN ctts.UsefulMonth ELSE 0 END) AS UsefulMonthAcc,
					SUM(CASE WHEN ctts.DocGroup = ''2'' THEN -1 ELSE 1 END * ctts.ProductionCapacity) AS ProductionCapacity,
					SUM(CASE WHEN ctts.DocDate < @_DocDate1 THEN ctts.ProductionCapacity ELSE 0 END) AS ProductionCapacity0,
					SUM(CASE WHEN ctts.ProductionCapacity <> 0 THEN 1 ELSE 0 END) AS ChangeInMonth1,
					SUM(CASE WHEN ctts.DocDate >= @_DocDate1 THEN ctts.ProductionCapacity ELSE 0 END) AS ProductionCapacityAcc
					FROM B3' + @_DataCode_Branch + N'AssetDoc ctts 
					INNER JOIN #t_DmTs dmts ON ctts.AssetId = dmts.Id 
					WHERE ctts.DocDate <= @_DocDate2 AND ctts.IsActive = 1 AND AssetTransType NOT IN (''KHAUHAO'', ''GIAMTAISAN'')
					GROUP BY ctts.AssetId,dmts.Code, ctts.EquityId'
 
	 EXECUTE sp_executesql @_cmd,N'@_DocDate1 DATE, @_DocDate2 DATE',@_DocDate1,@_DocDate2

	 DELETE FROM #SoThangSd WHERE ChangeInMonth0 = 0 AND ChangeInMonth1 = 0

	IF @_DeprMethod IN ('','3')
	BEGIN 

	DROP TABLE IF EXISTS #SanLuong
	CREATE TABLE #SanLuong(AssetId INT,ProductId INT,StageId INT,Quantity NUMERIC(18,5),QuantityInput NUMERIC(18,5))
 
	SET @_Cmd=' INSERT #SanLuong(AssetId,ProductId,StageId,Quantity) '+@_nl+
				' SELECT  AssetId,ProductId,StageId,SUM(Quantity) '+@_nl+
				' FROM B3'+@_DataCode_Branch+'AssetProduct a'+@_nl+
				' WHERE EXISTS (SELECT * FROM #t_DmTs WHERE Id=a.AssetId) '+@_nl+
				' GROUP BY AssetId,ProductId,StageId '
	EXEC(@_Cmd)

	DROP TABLE IF EXISTS #NhapTp
	CREATE TABLE #NhapTp(ProductId INT,StageId INT,Quantity NUMERIC(18,5))
 
	SET @_cmd=' ;WITH Cte '+@_nl+
				' AS '+@_nl+
				' ('+@_nl+
				'     SELECT Stt,BranchCode,DocCode,DocDate,ProductId,StageId,ItemId,Quantity '+@_nl+
				'     FROM vB3'+@_DataCode_Branch+'StockLedger a '+@_nl+
				'     WHERE BranchCode='''+@_BranchCode +''' AND DocCode=''TP'' AND CreditAccount LIKE ''154%'' '+@_nl+
				'             AND DocDate BETWEEN '''+ FORMAT(@_DocDate1,'yyyyMMdd') +''' AND '''+FORMAT(@_DocDate2,'yyyyMMdd') +''''   +@_nl+
				' ) '+@_nl+
				' INSERT #NhapTp(StageId,ProductId,Quantity) '+@_nl+
				' SELECT a.StageId,Item.ProductId,SUM(Quantity) AS Quantity'+@_nl+
				' FROM Cte a JOIN vB20Item Item ON a.ItemId=Item.Id '+@_nl+
				' WHERE EXISTS(SELECT * FROM #SanLuong WHERE ProductId=Item.ProductId AND StageId=a.StageId) '+@_nl+
				' GROUP BY a.StageId,Item.ProductId '
      
	EXEC(@_cmd)
 
	UPDATE a
	SET QuantityInput = ISNULL(Tp.Quantity,0)
	FROM #SanLuong a LEFT JOIN (SELECT StageId,ProductId,SUM(Quantity) AS Quantity
							FROM   #NhapTp 
							GROUP BY StageId,ProductId
							)Tp ON a.ProductId=Tp.ProductId AND a.StageId=Tp.StageId
    
	END 
	  
	IF @_DeprMethod = '3' OR EXISTS ( SELECT * FROM #t_DmTs t WHERE t.DeprMethod = 3)
	BEGIN

	--26022026: Nếu tính theo PP sản lượng thì CẬP NHẬT lại số lượng sản xuất vào bảng #t_DmTs để tính khấu hao
 
		UPDATE t 
		SET ProductionCapacity = s.Quantity		 
		FROM  #t_DmTs t INNER JOIN #SanLuong s 
		ON t.Id = s.AssetId
		WHERE T.DeprMethod = 3	
 
	END 
	
	
	 
	-- Xử lý tình huống tăng, giảm thời gian khấu hao trong kỳ thì ngày biến động cuối bằng ngày đầu tháng
	IF EXISTS(SELECT * FROM #SoThangSd WHERE UsefulMonthAcc <> 0 OR ProductionCapacityAcc <> 0)
	BEGIN
   
	UPDATE a 
	SET LastDayFluctuations = @_DocDate1
	FROM #t_BienDongCuoi a 
	WHERE EXISTS(SELECT * FROM #SoThangSd 
		WHERE (UsefulMonthAcc <> 0 OR ProductionCapacityAcc <> 0)
		AND AssetId=a.AssetId AND EquityId=a.EquityId)
  
  
	END
 
   
	-- Lấy giá trị còn lại, số tháng còn lại kể từ thời điểm bắt đầu khấu hao đến thời điểm tăng (giảm) cuối cùng
	DROP TABLE IF EXISTS #t_GtCl0;
	CREATE TABLE #t_GtCl0 (AssetId INT,AssetCode VARCHAR(24), EquityId INT, FirstDeprDate DATE, UsefulMonth NUMERIC(18, 9),
							ProductionCapacity NUMERIC(18, 4), LastDayFluctuations DATE,
							OriginalCost NUMERIC(18, 2), DeprAmount NUMERIC(18, 2), NetBookValue NUMERIC(18, 2),
							MonthForDepr1 NUMERIC(18, 9), ResidualMonth NUMERIC(18, 9), Depreciation0 NUMERIC(18, 2),
							UsefulMonth0 NUMERIC(18, 9), ProductionCapacity0 NUMERIC(18, 4), AllocateByCapacity NUMERIC(18, 4))
 
 

	SET @_cmd = N'INSERT #t_GtCl0(AssetId,AssetCode,EquityId,FirstDeprDate,UsefulMonth,ProductionCapacity,	 '+@_nl+
				N'					LastDayFluctuations,OriginalCost,DeprAmount,NetBookValue,MonthForDepr1,ResidualMonth,  '+@_nl+
				N'					Depreciation0,UsefulMonth0,ProductionCapacity0,AllocateByCapacity)  '+@_nl+
				N'	SELECT Dk.AssetId,dmts.Code AS AssetCode, Dk.EquityId,  '+@_nl+
				N'			MAX(dmts.FirstDeprDate) AS FirstDeprDate,  '+@_nl+
				N'			MAX(dmts.UsefulMonth) + MAX(ISNULL(UsefulMonth.UsefulMonth, 0)) AS UsefulMonth, '+@_nl+
				N'			MAX(dmts.ProductionCapacity) + MAX(ISNULL(UsefulMonth.ProductionCapacity, 0)) AS ProductionCapacity,  '+@_nl+
				N'			MAX(BienDongCuoi.LastDayFluctuations) AS LastDayFluctuations, '+@_nl+
				N'			SUM(Dk.IncOriginalCost - Dk.DeOriginalCost) AS OriginalCost, '+@_nl+
				N'			SUM(Dk.IncDepreciation - Dk.DeDepreciation) AS DeprAmount, '+@_nl+
				N'			SUM(Dk.IncOriginalCost - Dk.DeOriginalCost) - IIF(MAX(BienDongCuoi.LastDayFluctuations) = MAX(dmts.FirstDeprDate), 0, SUM(Dk.IncDepreciation - Dk.DeDepreciation)) AS NetBookValue, '+@_nl+
				N'			CAST(0 AS Numeric(18, 9)) AS MonthForDepr1, '+@_nl+
				N'			CAST(0 AS Numeric(18, 9)) AS ResidualMonth, '+@_nl+
				N'			CAST(0 AS NUMERIC(18, 2)) AS Depreciation0, '+@_nl+
				N'			MAX(dmts.UsefulMonth) AS UsefulMonth0, '+@_nl+
				N'			MAX(dmts.ProductionCapacity) AS ProductionCapacity0,  '+@_nl+
				N'			MAX(Dk.AllocateByCapacity) AS AllocateByCapacity  '+@_nl+
				N'	FROM dbo.vB3' + @_DataCode_Branch + N'AssetDoc Dk  '+@_nl+
				N'			INNER JOIN #t_BienDongCuoi BienDongCuoi ON Dk.AssetId = BienDongCuoi.AssetId  '+@_nl+
				N'				AND Dk.EquityId = BienDongCuoi.EquityId  '+@_nl+
				N'				AND Dk.DocDate <= BienDongCuoi.LastDayFluctuations  '+@_nl+
				N'				AND Dk.DocDate < @_DocDate1 '+@_nl+
				N'			INNER JOIN #t_DmTs dmts ON Dk.AssetId = dmts.Id    '+@_nl+
				N'			LEFT JOIN  -- Lấy danh sách biến động tài sản trước ngày Ct1 '+@_nl+
				N'				( '+@_nl+
				N'					SELECT ctts.AssetId, ctts.EquityId, SUM(CASE WHEN DocGroup = ''2'' THEN -1 ELSE 1 END * UsefulMonth) AS UsefulMonth, '+@_nl+
				N'							SUM(CASE WHEN DocGroup = ''2'' THEN -1 ELSE 1 END * ProductionCapacity) AS ProductionCapacity '+@_nl+
				N'							FROM dbo.B3' + @_DataCode_Branch + N'AssetDoc ctts '+@_nl+
				N'						WHERE ctts.AssetTransType NOT IN (''KHAUHAO'') '+@_nl+
				N'							AND ctts.DocDate <= @_DocDate2 AND ctts.UsefulMonth <> 0 AND ctts.IsActive = 1 '+@_nl+
				N'						GROUP BY AssetId, EquityId '+@_nl+
				N'				) AS UsefulMonth ON UsefulMonth.AssetId = Dk.AssetId AND UsefulMonth.EquityId = Dk.EquityId '+@_nl+
				N'		WHERE BienDongCuoi.LastDayFluctuations IS NOT NULL AND Dk.IsActive = 1  '+@_nl+
				N'		GROUP BY Dk.AssetId,dmts.Code, Dk.EquityId'
 
	EXECUTE sp_executesql @_cmd,N'@_DocDate1 DATE, @_DocDate2 DATE',@_DocDate1,@_DocDate2
 
	IF @_AssetType = 0
	BEGIN
	DELETE FROM #t_GtCl0 WHERE NetBookValue < 0
	END
	  
	-- Với CCDC/CPCPB, tính phân bổ từ ngày Bắt đầu phân bổ (Nếu Ngày tăng khác và trong cùng tháng)
	IF @_AssetType <> 0
	BEGIN
		UPDATE #t_GtCl0
		SET LastDayFluctuations = FirstDeprDate
		WHERE FirstDeprDate > LastDayFluctuations
	END
   
    
 -- Tính phân bổ CCDC tròn tháng, tính theo pp đường thẳng và sản lượng
	 IF (@_AssetType <> 0 AND @_M_PP_Pb_CCDC = '1')
	 BEGIN
 
		UPDATE #t_GtCl0
		SET MonthForDepr1 = case when AllocateByCapacity = 0 then  DATEDIFF(MONTH, FirstDeprDate, DATEADD(DAY, -1, @_DocDate1))
							else MonthForDepr1 end		
 
		UPDATE #t_GtCl0
		SET ResidualMonth = CAST(IIF( AllocateByCapacity = 0, UsefulMonth, ProductionCapacity) AS NUMERIC(18, 9)) - MonthForDepr1

		--kiểm tra lại công thức tính pp khấu hao theo sản lượng đang bị sai giá trị phân bổ cho 1 mã
		--
		
		SELECT Depreciation0,NetBookValue,ResidualMonth,* from #t_GtCl0     

		UPDATE #t_GtCl0
		SET Depreciation0 = CASE
								WHEN FirstDeprDate = LastDayFluctuations
									 AND UsefulMonth <> 0 THEN
									ISNULL(ROUND(OriginalCost / NULLIF(UsefulMonth, 0), @_Round), 0)
								WHEN ResidualMonth > 0 THEN
									ROUND(NetBookValue / ResidualMonth, @_Round)
							END 
      
	  	SELECT Depreciation0,NetBookValue,ResidualMonth,* from #t_GtCl0   return 


		-- Xử lý riêng tình huống lấy số dư cuối chia thời gian sử dụng còn lại
		-- Chỉ lấy CCDC có điều chinh hao mòn quá khứ
		DROP TABLE IF EXISTS #_CtCl;
		CREATE TABLE #_CtCl
		(
			AssetId INT,
			EquityId INT,
			DeprMethod TINYINT
		)

		SET @_Cmd = N'INSERT INTO #_CtCl(AssetId,EquityId,DeprMethod) '+@_nl+
					N'	SELECT AssetId, EquityId,tb.DeprMethod '+@_nl+
					N'		FROM vB3' + @_DataCode_Branch+ 'AssetDoc tb '+@_nl+
					N'			INNER JOIN #t_DmTs ts ON tb.AssetId = ts.Id '+@_nl+
					N'		WHERE DocDate < @_ProgUsedFirstDay AND IsActive = 1 AND AssetType = @_AssetType '+@_nl+
					N'			AND AssetTransType = ''KHAUHAO'' '+@_nl+
					N'			AND isDeprAdjusted = 1 '+@_nl+
					N'		GROUP BY AssetId, EquityId,tb.DeprMethod'  
  
		EXECUTE sp_executesql @_cmd,N'@_ProgUsedFirstDay DATE, @_AssetType VARCHAR(24)',@_ProgUsedFirstDay,@_AssetType
      
		IF EXISTS(SELECT * FROM #_CtCl)
		BEGIN   
		-- Với CCDC nào không có biến động thì tính Phân bổ tháng = NetBookValue / Số tháng
 
		SET @_Cmd = N'UPDATE #t_GtCl0 
					SET Depreciation0 = IIF((a.ResidualMonth - DATEDIFF(month, a.FirstDeprDate, @_ProgUsedFirstDay)) = 0, 0, -- 10/12/2024 VũLA: Bổ sung IIF cho phép chia
						ROUND((a.NetBookValue-b.Depreciation)/(a.ResidualMonth - DATEDIFF(month, a.FirstDeprDate, @_ProgUsedFirstDay)), @_Round))
					FROM #t_GtCl0 a
						INNER JOIN #_CtCl cl ON a.AssetId = cl.AssetId
						INNER JOIN 
							(
								SELECT AssetId, EquityId, SUM(Depreciation) AS Depreciation 
								FROM dbo.vB3' + @_DataCode_Branch + N'AssetDoc
								WHERE DocDate < @_ProgUsedFirstDay AND IsActive = 1 AND AssetType = @_AssetType
								AND AssetTransType = ''KHAUHAO''
								GROUP BY AssetId, EquityId
							) b ON a.AssetId = b.AssetId AND a.EquityId = b.EquityId 
					WHERE a.UsefulMonth > 0 OR a.ProductionCapacity > 0'
 
		EXECUTE sp_executesql @_cmd,
			N' @_ProgUsedFirstDay DATE, @_AssetType VARCHAR(24), @_Round INT',
				@_ProgUsedFirstDay,@_AssetType,@_Round
 
			
 
			UPDATE #t_GtCl0
			SET Depreciation0 = ROUND((a.NetBookValue)/(a.ResidualMonth), @_Round)
			FROM #t_GtCl0 a 
			INNER JOIN #_CtCl b ON a.AssetId = b.AssetId AND a.EquityId = b.EquityId 
			WHERE a.ResidualMonth > 0  
			END  
			 
			DROP TABLE IF EXISTS #_CtCl

	 END
 ELSE
	BEGIN 
 
		UPDATE #t_GtCl0 SET MonthForDepr1 = dbo.ufn_sys_MonthDiffTs(FirstDeprDate, LastDayFluctuations)
    
		UPDATE #t_GtCl0 SET ResidualMonth = CAST(IIF(AllocateByCapacity = 0, UsefulMonth, ProductionCapacity) AS NUMERIC(18, 9)) - MonthForDepr1  
  
		UPDATE #t_GtCl0 SET Depreciation0 = ROUND(NetBookValue/ResidualMonth, @_Round) WHERE ResidualMonth > 0
		
		--select Depreciation0,* from #t_GtCl0 return 

		-- MonthForDepr1 số tháng phân bổ
		-- ResidualMonth số tháng phân bổ còn lại
		-- Depreciation0 giá trị phân bổ

	 
	END
 
  
 -- Tình huống đặc biệt:
 -- Tài sản có biến động thời gian sử dụng trong kỳ tính toán khấu hao tháng được tính = GTCL đầu kỳ Chia Thời gian còn lại (đã cộng tăng giảm thời gian sử dụng)
 -- Chú ý: Biến động về thời gian sử dụng bất kỳ ngày nào trong tháng cũng được tính là ngày đầu của tháng tính toán.
	IF EXISTS(SELECT * FROM #SoThangSd WHERE UsefulMonthAcc <> 0 OR ProductionCapacityAcc <> 0)
	----trunght thêm đoạn này để xử lý có biến động là tính lại 
	OR EXISTS(SELECT * FROM #SoThangSd WHERE DocDate BETWEEN @_DocDate1 AND @_DocDate2)
		BEGIN
		IF (@_AssetType <> 0 AND @_M_PP_Pb_CCDC = '1') -- Phân bổ CCDC tròn tháng
			BEGIN   
				SET @_Cmd = N'	UPDATE #t_GtCl0   '+@_nl+
							N'	SET NetBookValue = dk.NetBookValue,  '+@_nl+
							N'		MonthForDepr1 = DATEDIFF(month, ctcl.FirstDeprDate, @_DocDate1),  '+@_nl+
							N'		ResidualMonth = CAST(IIF(ctcl.AllocateByCapacity = 0, ctcl.UsefulMonth, ctcl.ProductionCapacity) AS NUMERIC(18, 9)) - DATEDIFF(month, ctcl.FirstDeprDate, @_DocDate1),   '+@_nl+
							N'		Depreciation0 =   '+@_nl+
							N'			CASE WHEN (CAST(IIF(ctcl.AllocateByCapacity = 0, ctcl.UsefulMonth, ctcl.ProductionCapacity) AS NUMERIC(18, 9)) - DATEDIFF(month, ctcl.FirstDeprDate, @_DocDate1)) = 0   '+@_nl+
							N'			THEN 0 ELSE ROUND(dk.NetBookValue/(IIF(ctcl.AllocateByCapacity = 0, ctcl.UsefulMonth, ctcl.ProductionCapacity) - DATEDIFF(month, ctcl.FirstDeprDate, @_DocDate1)), @_Round) END   '+@_nl+
							N'	FROM #t_GtCl0 ctcl   '+@_nl+
							N'		INNER JOIN #SoThangSd SoThangSd ON ctcl.AssetId = SoThangSd.AssetId AND ctcl.EquityId = SoThangSd.EquityId  '+@_nl+
							N'		INNER JOIN (  '+@_nl+
							N'					SELECT AssetId, EquityId, SUM((IncOriginalCost - DeOriginalCost) - (IncDepreciation - DeDepreciation)) AS NetBookValue  '+@_nl+
							N'						FROM dbo.vB3' + @_DataCode_Branch + N'AssetDoc  '+@_nl+
							N'						WHERE DocDate < @_DocDate1 AND IsActive=1  '+@_nl+
							N'						GROUP BY AssetId, EquityId) AS dk ON ctcl.AssetId = Dk.AssetId AND ctcl.EquityId = Dk.EquityId   '+@_nl+
							N'						WHERE SoThangSd.UsefulMonthAcc <> 0 OR SoThangSd.ProductionCapacityAcc <> 0'
   
				EXECUTE sp_executesql @_cmd, N'@_DocDate1 DATE, @_Round INT',@_DocDate1, @_Round
     
			END
		ELSE
			BEGIN
				IF EXISTS(SELECT * FROM #SoThangSd WHERE UsefulMonthAcc <> 0 OR ProductionCapacityAcc <> 0)
					BEGIN 

						SET @_Cmd = N'UPDATE #t_GtCl0		'+@_nl+
									N'	SET NetBookValue = dk.NetBookValue, '+@_nl+
									N'		MonthForDepr1 = dbo.ufn_sys_MonthDiffTs(ctcl.FirstDeprDate, DATEADD(DAY, -1, @_DocDate1)),'+@_nl+
									N'		ResidualMonth = CAST(IIF(ctcl.AllocateByCapacity = 0, ctcl.UsefulMonth, ctcl.ProductionCapacity) AS NUMERIC(18, 9)) - dbo.ufn_sys_MonthDiffTs(ctcl.FirstDeprDate, @_DocDate1), '+@_nl+
									N'		Depreciation0 = CASE '+@_nl+
									N'						WHEN CAST(IIF(ctcl.AllocateByCapacity = 0, ctcl.UsefulMonth, ctcl.ProductionCapacity) AS NUMERIC(18, 9)) - dbo.ufn_sys_MonthDiffTs(ctcl.FirstDeprDate, @_DocDate1) = 0 THEN 0 '+@_nl+
									N'						END '+@_nl+
									N'		FROM #t_GtCl0 AS ctcl '+@_nl+
									N'			INNER JOIN #SoThangSd AS SoThangSd ON ctcl.AssetId = SoThangSd.AssetId AND ctcl.EquityId = SoThangSd.EquityId'+@_nl+
									N'			INNER JOIN ('+@_nl+
									N'						SELECT AssetId, EquityId, SUM((IncOriginalCost - DeOriginalCost) - (IncDepreciation - DeDepreciation)) AS NetBookValue'+@_nl+
									N'				--ELSE ROUND(dk.NetBookValue/(CAST(IIF(ctcl.AllocateByCapacity = 0, ctcl.UsefulMonth, ctcl.ProductionCapacity) AS NUMERIC(18, 9)) - dbo.ufn_sys_MonthDiffTs(ctcl.FirstDeprDate, @_DocDate1)), @_Round)'+@_nl+
									N'			FROM dbo.vB3' + @_DataCode_Branch + N'AssetDoc'+@_nl+
									N'		WHERE DocDate < @_DocDate1 AND IsActive=1'+@_nl+
									N'		GROUP BY AssetId, EquityId) AS dk ON ctcl.AssetId = Dk.AssetId AND ctcl.EquityId = Dk.EquityId '+@_nl+
									N'		WHERE SoThangSd.UsefulMonthAcc <> 0 OR SoThangSd.ProductionCapacityAcc <> 0'

						EXECUTE sp_executesql @_cmd,N'@_DocDate1 DATE, @_Round INT',@_DocDate1, @_Round

					  

					END
				ELSE -- trunght thêm để làm số dư
					BEGIN
       
						SET @_Cmd = N'	UPDATE #t_GtCl0  '+@_nl+
									N'		SET NetBookValue = dk.NetBookValue,'+@_nl+
									N'			MonthForDepr1 = dbo.ufn_sys_MonthDiffTs(ctcl.FirstDeprDate, DATEADD(DAY, -1, @_DocDate1)),'+@_nl+
									N'			ResidualMonth = CAST(IIF(ctcl.AllocateByCapacity = 0, ctcl.UsefulMonth, ctcl.ProductionCapacity) AS NUMERIC(18, 9))'+@_nl+
									N'			- dbo.ufn_sys_MonthDiffTs(ctcl.FirstDeprDate, @_DocDate1), '+@_nl+
									N'			Depreciation0 = CASE '+@_nl+
									N'							WHEN CAST(IIF(ctcl.AllocateByCapacity = 0, ctcl.UsefulMonth, ctcl.ProductionCapacity) AS NUMERIC(18, 9)) - dbo.ufn_sys_MonthDiffTs(ctcl.FirstDeprDate, @_DocDate1) = 0 THEN 0 '+@_nl+
									N'							END '+@_nl+
									N'			FROM #t_GtCl0 AS ctcl '+@_nl+
									N'				INNER JOIN #SoThangSd AS SoThangSd ON ctcl.AssetId = SoThangSd.AssetId AND ctcl.EquityId = SoThangSd.EquityId'+@_nl+
									N'				INNER JOIN ('+@_nl+
									N'							SELECT AssetId, EquityId, SUM((IncOriginalCost - DeOriginalCost) - (IncDepreciation - DeDepreciation)) AS NetBookValue'+@_nl+
									N'						ELSE ROUND(dk.NetBookValue/(CAST(IIF(ctcl.AllocateByCapacity = 0, ctcl.UsefulMonth, ctcl.ProductionCapacity) AS NUMERIC(18, 9)) - dbo.ufn_sys_MonthDiffTs(ctcl.FirstDeprDate, @_DocDate1)), @_Round)'+@_nl+
									N'				FROM dbo.vB3' + @_DataCode_Branch + N'AssetDoc'+@_nl+
									N'			WHERE DocDate < @_DocDate1 AND IsActive=1'+@_nl+
									N'			GROUP BY AssetId, EquityId) AS dk ON ctcl.AssetId = Dk.AssetId AND ctcl.EquityId = Dk.EquityId ' 
         
     
						EXECUTE sp_executesql @_cmd,N'@_DocDate1 DATE, @_Round INT',@_DocDate1, @_Round
 
   

					END         
			END
		END
 
 
					


		IF @_AssetType = 0 AND EXISTS(SELECT * FROM #t_GtCl0 WHERE LastDayFluctuations = FirstDeprDate 
										AND CAST(IIF(AllocateByCapacity = 0, UsefulMonth, ProductionCapacity) AS NUMERIC(18, 9)) = ResidualMonth
										AND LastDayFluctuations < @_ProgUsedFirstDay AND ResidualMonth <> 0
		)
		BEGIN    
			UPDATE #t_GtCl0 
				SET Depreciation0 = ROUND(OriginalCost/ResidualMonth, @_Round)
			FROM #t_GtCl0 
			WHERE LastDayFluctuations = FirstDeprDate AND UsefulMonth = ResidualMonth
			AND LastDayFluctuations < @_ProgUsedFirstDay AND ResidualMonth <>0
		END
 
		

		-- Danh sách tài sản biến động trong kỳ
		DROP TABLE IF EXISTS #t_BienDong;  
		SELECT TOP 0 ctts.AssetId,dmts.Code AS AssetCode, ctts.EquityId, ctts.DocDate, ctts.DocGroup,
					ctts.AssetTransType, 
					IIF(ctts.AssetTransType = 'GIAMTAISAN', 0, ctts.OriginalCost) AS OriginalCost, 
					IIF(ctts.AssetTransType = 'GIAMTAISAN', 0, ctts.Depreciation) AS Depreciation, 
					IIF(ctts.AssetTransType = 'GIAMTAISAN', 0, ctts.AmountForDepr) AS AmountForDepr, 
					dmts.FirstDeprDate AS FirstDeprDate,
					IIF(ctts.AssetTransType = 'GIAMTAISAN', 0, dmts.UsefulMonth) + ISNULL(SoThangSd.UsefulMonth, 0) AS UsefulMonth,
					IIF(ctts.AssetTransType = 'GIAMTAISAN', 0, dmts.ProductionCapacity) + ISNULL(SoThangSd.ProductionCapacity, 0) AS ProductionCapacity, 
					CAST(0 AS Numeric(18, 9)) AS ResidualMonth,
					CAST(0 AS NUMERIC(18, 2)) AS FlucDepr,
					CASE WHEN DocGroup = '1' THEN 1 ELSE -1 END*IIF(ctts.AssetTransType = 'GIAMTAISAN', 0, ctts.OriginalCost) AS OriginalCost0,
					CASE WHEN DocGroup = '1' THEN 1 ELSE -1 END*IIF(ctts.AssetTransType = 'GIAMTAISAN', 0, (ctts.OriginalCost - ctts.Depreciation)) AS NetBookValue0,
					ctts.AllocateByCapacity 
		INTO #t_BienDong 
		FROM dbo.vB30AssetDoc ctts WITH (NOLOCK)
		INNER JOIN #t_DmTs dmts ON ctts.AssetId = dmts.Id
		LEFT OUTER JOIN #SoThangSd SoThangSd ON ctts.AssetId = SoThangSd.AssetId AND ctts.EquityId = SoThangSd.EquityId
 
   

		SET @_Cmd = N'INSERT #t_BienDong(AssetId,AssetCode,EquityId,DocDate,DocGroup,AssetTransType,OriginalCost,Depreciation,AmountForDepr, '+@_nl+
											N'FirstDeprDate,UsefulMonth,ProductionCapacity,ResidualMonth,FlucDepr,OriginalCost0, '+@_nl+
											N'NetBookValue0,AllocateByCapacity) '+@_nl+
					N'SELECT ctts.AssetId,dmts.Code AS AssetCode, ctts.EquityId, ctts.DocDate, ctts.DocGroup,ctts.AssetTransType, '+@_nl+
					N'		IIF(ctts.AssetTransType = ''GIAMTAISAN'', 0, ctts.OriginalCost) AS OriginalCost,  '+@_nl+
					N'		IIF(ctts.AssetTransType = ''GIAMTAISAN'', 0, ctts.Depreciation) AS Depreciation,  '+@_nl+
					N'		IIF(ctts.AssetTransType = ''GIAMTAISAN'', 0, ctts.AmountForDepr) AS AmountForDepr,  '+@_nl+
					N'		dmts.FirstDeprDate AS FirstDeprDate, '+@_nl+
					N'		IIF(ctts.AssetTransType = ''GIAMTAISAN'', 0, dmts.UsefulMonth) + ISNULL(SoThangSd.UsefulMonth, 0) AS UsefulMonth, '+@_nl+
					N'		IIF(ctts.AssetTransType = ''GIAMTAISAN'', 0, dmts.ProductionCapacity) + ISNULL(SoThangSd.ProductionCapacity, 0) AS ProductionCapacity,  '+@_nl+
					N'		CAST(0 AS Numeric(18, 9)) AS ResidualMonth, '+@_nl+
					N'		CAST(0 AS NUMERIC(18, 2)) AS FlucDepr, '+@_nl+
					N'		CASE WHEN DocGroup = ''1'' THEN 1 ELSE -1 END*IIF(ctts.AssetTransType = ''GIAMTAISAN'', 0, ctts.OriginalCost) AS OriginalCost0, '+@_nl+
					N'		CASE WHEN DocGroup = ''1'' THEN 1 ELSE -1 END*IIF(ctts.AssetTransType = ''GIAMTAISAN'', 0, (ctts.OriginalCost - ctts.Depreciation)) AS NetBookValue0, '+@_nl+
					N'		ctts.AllocateByCapacity  '+@_nl+
					N'			FROM vB3' + @_DataCode_Branch + N'AssetDoc ctts  '+@_nl+
					N'				INNER JOIN #t_DmTs dmts ON ctts.AssetId = dmts.Id '+@_nl+
					N'				LEFT JOIN #SoThangSd SoThangSd ON ctts.AssetId = SoThangSd.AssetId AND ctts.EquityId = SoThangSd.EquityId '+@_nl+
					N'			WHERE ctts.AssetTransType NOT IN (''KHAUHAO'') AND (ctts.DeprAllocationRate = 0) -- Loại trừ nhập hệ số phân bổ '+@_nl+
					N'				AND ctts.DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND ctts.IsActive = 1'  

		EXECUTE sp_executesql @_cmd,N'@_DocDate1 DATE, @_DocDate2 DATE',@_DocDate1,@_DocDate2

 

		-- Với CCDC/CPCPB, tính phân bổ từ ngày Bắt đầu phân bổ (Nếu Ngày tăng khác và trong cùng tháng)
		IF @_AssetType <> 0
			UPDATE #t_BienDong SET DocDate = FirstDeprDate
			WHERE FirstDeprDate <> DocDate AND (FirstDeprDate BETWEEN @_DocDate1 AND @_DocDate2 AND DocDate BETWEEN @_DocDate1 AND @_DocDate2)

		-- Tính phân bổ CCDC tròn tháng
		IF (@_AssetType <> 0 AND @_M_PP_Pb_CCDC = '1')
		BEGIN
			UPDATE #t_BienDong SET ResidualMonth = CAST(IIF(AllocateByCapacity = 0, UsefulMonth, ProductionCapacity) AS NUMERIC(18, 9)) - DATEDIFF(month, FirstDeprDate, DocDate) 
  
			UPDATE #t_BienDong SET FlucDepr = ROUND((NetBookValue0 / ResidualMonth), @_Round) 
			WHERE ResidualMonth > 0; 
		END
		ELSE
		BEGIN
			UPDATE #t_BienDong 
			SET ResidualMonth = CAST(IIF(AllocateByCapacity = 0, UsefulMonth, ProductionCapacity) AS NUMERIC(18, 9)) - dbo.ufn_sys_MonthDiffTs(FirstDeprDate, DocDate) 

			UPDATE #t_BienDong SET FlucDepr = 
			ROUND((NetBookValue0 / ResidualMonth)*
			CASE WHEN DocGroup = '1' THEN dbo.ufn_sys_MonthDiffTs(DATEADD(DAY, -1, DocDate), @_DocDate2)
			ELSE dbo.ufn_sys_MonthDiffTs(DocDate, DATEADD(DAY, 1, @_DocDate2)) END, @_Round) 
			WHERE ResidualMonth > 0; 
		END 

		DROP TABLE IF EXISTS #t_khts;
		SELECT TOP 0 @_BranchCode AS BranchCode,
				CAST(-1 AS int) AS ParentId, CAST(0 AS BIT) AS IsGroup,
				CAST(0 AS INT) AS Id, CAST(0 AS INT) AS EquityId, Name, Code,
				CAST(0 AS NUMERIC(18, 2)) AS OriginalCost,
				CAST(0 AS NUMERIC(18, 2)) AS NetBookValue,
				CAST(0 AS NUMERIC(18, 2)) AS AmountForDepr,
				CAST(0 AS NUMERIC(18, 2)) AS MonthDepr,
				CAST(NULL AS DATE) AS FirstDeprDate,
				CAST(NULL AS DATE) AS LastDeprDate,
				CAST(NULL AS DATE) AS FirstUsedDate,
				StandbyForDisposal,
				CAST(0 AS NUMERIC(20, 9)) AS MonthForDepr, 
				CAST(0 AS Tinyint) AS IsDeprAdjusted,  -- Co sua khau hao hay khong
				CAST(NULL AS DATE) AS DecreaseDate,
				AllocateByCapacity, 
				CAST(NULL AS DATE) AS LastSuspendDate, CAST(NULL AS DATE) AS LastResumeDate,
				CAST(NULL AS DATE) AS FirstDiposalDate,
				CAST(NULL AS INT) AS SoThangDaKhauHao,
				CAST(null  AS INT) AS SoThangConLai,
				CAST(0 AS NUMERIC(18, 2)) AS ProductionCapacity0,
				 CAST(NULL AS INT) as DeprMethod
		INTO #t_khts  
		FROM B20Asset WITH (NOLOCK)

	 

		IF EXISTS ( SELECT * FROM #t_GtCl0 WHERE AllocateByCapacity = 1 ) 
		BEGIN
		 
			UPDATE GTCL
			SET Depreciation0 = Depreciation0 * S.QUANTITYINPUT
			FROM #t_GtCl0 GTCL INNER JOIN #SANLUONG S
			ON GTCL.AssetId = S.AssetId
			WHERE AllocateByCapacity = 1 

		 
		END 

	 

		IF EXISTS ( SELECT * FROM #t_BienDong WHERE AllocateByCapacity = 1 ) 
		BEGIN
			UPDATE t_BienDong
			SET FlucDepr = FlucDepr * S.QUANTITYINPUT
			FROM #t_BienDong  t_BienDong INNER JOIN #SANLUONG S
			ON t_BienDong.AssetId = S.AssetId
			WHERE AllocateByCapacity = 1

		END 
 
		-- Gộp 2 loại để ra phần tính
		SET @_Cmd = N' ;WITH khts AS  '+@_nl+
					N' ( '+@_nl+
					N' SELECT AssetId AS Id, EquityId,  '+@_nl+
					N'			Depreciation0 AS MonthDepr, Depreciation0, 0 AS FlucDepr, '+@_nl+
					N'			CAST(0 AS NUMERIC(18, 2)) AS OriginalCost, CAST(0 AS NUMERIC(18, 2)) AS NetBookValue '+@_nl+
					N'	FROM #t_GtCl0 '+@_nl+
					N'	UNION ALL '+@_nl+
					N' SELECT AssetId AS Id, EquityId,  '+@_nl+
					N'			FlucDepr AS MonthDepr, 0 AS Depreciation0, FlucDepr, '+@_nl+
					N'			OriginalCost0 AS OriginalCost, NetBookValue0 AS NetBookValue '+@_nl+
					N' FROM #t_BienDong  '+@_nl+
					N' ) '+@_nl+
					N' INSERT #t_khts(BranchCode, ParentId, IsGroup, Id, EquityId, Name, Code, OriginalCost, NetBookValue, AmountForDepr,  '+@_nl+
					N'				MonthDepr, FirstDeprDate, LastDeprDate, FirstUsedDate, StandbyForDisposal, MonthForDepr, IsDeprAdjusted,  '+@_nl+
					N'				DecreaseDate, AllocateByCapacity, LastSuspendDate, LastResumeDate, FirstDiposalDate)        '+@_nl+
					N'	SELECT @_BranchCode AS BranchCode, '+@_nl+
					N'				CAST(-1 AS int) AS ParentId, CAST(0 AS bit) AS IsGroup, '+@_nl+
					N'				khts.Id, khts.EquityId, MAX(dmts.Name) AS Name, MAX(dmts.Code) AS Code, '+@_nl+
					N'				SUM(khts.OriginalCost) + MAX(ISNULL(tgts0.OriginalCost, 0)) AS OriginalCost, '+@_nl+
					N'				SUM(khts.NetBookValue) + MAX(ISNULL(tgts0.NetBookValue, 0)) AS NetBookValue, '+@_nl+
					N'				SUM(khts.OriginalCost) + MAX(ISNULL(tgts0.OriginalCost, 0)) AS AmountForDepr, '+@_nl+
					N'				SUM(khts.MonthDepr) AS MonthDepr, '+@_nl+
					N'				MAX(dmts.FirstDeprDate) AS FirstDeprDate, '+@_nl+
					N'				MAX(dmts.LastDeprDate) AS LastDeprDate, '+@_nl+
					N'				MAX(dmts.FirstUsedDate) AS FirstUsedDate, '+@_nl+
					N'				MAX(dmts.StandbyForDisposal) AS StandbyForDisposal, '+@_nl+
					N'				IIF(MAX(AllocateByCapacity) = 1,  '+@_nl+
					N'				MAX(dmts.ProductionCapacity) + MAX(ISNULL(SoThangSd.ProductionCapacity, 0)),  '+@_nl+
					N'				MAX(dmts.UsefulMonth) + MAX(ISNULL(SoThangSd.UsefulMonth, 0))) AS MonthForDepr,  '+@_nl+
					N'				CAST(0 AS Tinyint) AS IsDeprAdjusted,  -- Co sua khau hao hay khong '+@_nl+
					N'				MAX(tsGiam.DecreaseDate) AS DecreaseDate, '+@_nl+
					N'				ISNULL(MAX(dmts.AllocateByCapacity), 0) AS AllocateByCapacity,  '+@_nl+
					N'				MAX(LastSuspendDate) AS LastSuspendDate, MAX(LastResumeDate) AS LastResumeDate, '+@_nl+
					N'				CAST(NULL AS DATE) AS FirstDiposalDate  --  '+@_nl+
					N'	FROM khts  '+@_nl+
					N'			INNER JOIN #t_DmTs AS dmts ON khts.Id = dmts.Id '+@_nl+
					N'			LEFT OUTER JOIN #SoThangSd AS SoThangSd ON khts.Id = SoThangSd.AssetId AND khts.EquityId = SoThangSd.EquityId '+@_nl+
					N'			LEFT OUTER JOIN '+@_nl+
					N'				( '+@_nl+
					N'					SELECT AssetId, EquityId,  '+@_nl+
					N'							SUM((IncOriginalCost - DeOriginalCost)) AS OriginalCost, '+@_nl+
					N'							SUM((IncOriginalCost - DeOriginalCost) - (IncDepreciation - DeDepreciation)) AS NetBookValue '+@_nl+
					N'					FROM dbo.vB3' + @_DataCode_Branch + N'AssetDoc '+@_nl+
					N'					WHERE DocDate < @_DocDate1 AND IsActive = 1 '+@_nl+
					N'					GROUP BY AssetId, EquityId '+@_nl+
					N'				) AS tgts0 ON khts.Id = tgts0.AssetId AND khts.EquityId = tgts0.EquityId '+@_nl+
					N'			LEFT OUTER JOIN  '+@_nl+
					N'				( '+@_nl+
					N'					SELECT AssetId, MAX(DocDate) AS DecreaseDate '+@_nl+
					N'					FROM dbo.B3' + @_DataCode_Branch + N'AssetDoc '+@_nl+
					N'					WHERE DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND AssetTransType = ''GIAMTAISAN'' AND IsActive = 1 '+@_nl+
					N'					GROUP BY AssetId '+@_nl+
					N'				) AS tsGiam ON khts.Id = tsGiam.AssetId  '+@_nl+
					N'	GROUP BY khts.Id, khts.EquityId '
 
			EXECUTE sp_executesql @_cmd,
			N'@_DocDate1 DATE, @_DocDate2 DATE, @_BranchCode VARCHAR(8)',
			@_DocDate1, @_DocDate2,@_BranchCode
 
		-- Ngày kết thúc khấu hao tài sản (Ngày bắt đầu - 1), nếu phân bổ theo SL thì không quan tâm đến ngày kết thúc khấu hao
		UPDATE #t_khts SET LastDeprDate = DATEADD(day, -1, DATEADD(m, MonthForDepr, FirstDeprDate)) 
		WHERE AllocateByCapacity <> 1

	 
		-- Tính phân bổ CCDC
		IF @_AssetType IN (1, 2)
		BEGIN
		IF @_M_PP_Pb_CCDC = '1'
		begin
		UPDATE #t_khts SET LastDeprDate = EOMONTH(DATEADD(m, MonthForDepr - 1, FirstDeprDate))
		WHERE DAY(FirstDeprDate) <> 1 
		AND AllocateByCapacity <> 1
		end 
		  
		
 
    
		SET @_Cmd = N' UPDATE #t_khts   '+@_nl+
					N' SET LastDeprDate = DATEADD(day, -DAY(DecreaseDate), DATEADD(m, 1, DecreaseDate))  '+@_nl+
					N' FROM #t_khts AS ct INNER JOIN   '+@_nl+
					N' (SELECT AssetId, DocDate   '+@_nl+
					N' FROM dbo.vB3' + @_DataCode_Branch + N'AssetDoc   '+@_nl+
					N' WHERE AssetType = @_AssetType AND IsActive = 1 AND BranchCode = @_BranchCode  '+@_nl+
					N' AND DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND AssetTransType = ''GIAMTAISAN''  '+@_nl+
					N' ) AS TLy ON ct.Id = TLy.AssetId'
   
		EXECUTE sp_executesql @_cmd,N'@_DocDate1 DATE, @_DocDate2 DATE, @_AssetType VARCHAR(24), @_BranchCode VARCHAR(8)',
										@_DocDate1,@_DocDate2,@_AssetType,@_BranchCode
		END

		-- Tài sản đến thời điểm kết thúc khấu hao = GTCL tài sản đó
		UPDATE #t_khts SET MonthDepr = NetBookValue WHERE LastDeprDate BETWEEN @_DocDate1 AND @_DocDate2

	
	  

 -- Tính phân bổ CCDC. Nếu có thanh lý trong kỳ thì đưa hết GTCL vào phân bổ, không quan tâm phân bổ tròn tháng hay theo ngày
	IF @_AssetType = 0 --OR @_M_PP_Pb_CCDC <> '1'
	BEGIN
	-- Thanh lý ngay trong tháng đầu tiên tăng
		UPDATE #t_khts SET FirstDiposalDate = CASE WHEN DATEDIFF(MONTH, @_DocDate1, FirstDeprDate) = 0 AND DATEDIFF(YEAR, @_DocDate1, DecreaseDate) = 0 THEN FirstDeprDate ELSE @_DocDate1 END

	-- Xử lý tài sản giảm trong kỳ
		UPDATE #t_khts SET MonthDepr = ROUND((MonthDepr*dbo.ufn_sys_MonthDiffTs(FirstDiposalDate, DecreaseDate))/
		IIF(dbo.ufn_sys_MonthDiffTs(DATEADD(DAY, -1, FirstDiposalDate), @_DocDate2) = 0, 1, dbo.ufn_sys_MonthDiffTs(DATEADD(DAY, -1, FirstDiposalDate), @_DocDate2)), @_Round)
		WHERE DecreaseDate IS NOT NULL AND LastDeprDate > @_DocDate2 

		UPDATE #t_khts SET MonthDepr = MonthDepr - ABS(ROUND(MonthDepr*dbo.ufn_sys_MonthDiffTs(LastDeprDate, DATEADD(DAY, -1, DecreaseDate)), @_Round))
		WHERE DecreaseDate IS NOT NULL AND LastDeprDate <= @_DocDate2 AND DecreaseDate <= LastDeprDate

	-- Cập nhật khấu hao = 0 trong trường hợp ngày DecreaseDate = @_DocDate1
		UPDATE #t_khts SET MonthDepr = 0 
		WHERE DecreaseDate IS NOT NULL AND DecreaseDate = @_DocDate1
	END

	

 -- Xử lý thêm với phân bổ theo Sản lượng: Sử dụng Hệ số phân bổ khấu hao hàng tháng để làm sản lượng
 -- Nếu trong tháng không có hệ số phân bổ thì không tính khấu hao
	SET @_Cmd = N' UPDATE #t_khts SET MonthDepr = CASE WHEN ISNULL(b.DeprAllocationRate, 0) = 0 THEN 0 ELSE MonthDepr END   '+@_nl+
				N' FROM #t_khts tb    '+@_nl+
				N' LEFT OUTER JOIN   '+@_nl+
				N' (  '+@_nl+
				N'		SELECT b.AssetId, b.EquityId, SUM(b.DeprAllocationRate) AS DeprAllocationRate  '+@_nl+
				N'			FROM dbo.vB3' + @_DataCode_Branch + N'AssetDoc_DeprAllocationRate b   '+@_nl+
				N'		WHERE b.DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND ISNULL(b.AssetTransType, '''') <> ''KHAUHAO''   '+@_nl+
				N'		AND b.IsActive = 1  '+@_nl+
				N'		GROUP BY b.AssetId, b.EquityId  '+@_nl+
				N' ) b ON tb.Id = b.AssetId AND tb.EquityId = b.EquityId  '+@_nl+
				N' WHERE tb.AllocateByCapacity = 1 '

	--EXECUTE sp_executesql @_cmd,N'@_DocDate1 DATE, @_DocDate2 DATE', @_DocDate1,@_DocDate2

	DECLARE @_DateUsingBravo DATE = DATEADD(DAY, -1, dbo.ufn_B00FiscalYear_GetStartedUsingDate(@_BranchCode))

 -- Với những TSCĐ phân bổ SL: Nếu trong tháng có hệ số thì phân bổ, nếu không thì thôi
 -- Nếu sản lượng trong tháng + tổng sản lượng đã phân bổ >= tổng sản lượng dự kiến thì mặc định bằng Giá trị còn lại
	SET @_Cmd = N' UPDATE #t_khts SET MonthDepr = ROUND(  '+@_nl+
				N' IIF((ISNULL(b.DeprAllocationRate0, 0) + ISNULL(b.DeprAllocationRate, 0) + ISNULL(c.DeprAllocationRate0, 0) >= tb.MonthForDepr),  '+@_nl+
				N' NetBookValue,  '+@_nl+
				N' IIF(tb.MonthForDepr = 0 OR tb.MonthForDepr = ISNULL(b.DeprAllocationRate0, 0), 0, AmountForDepr * ISNULL(b.DeprAllocationRate, 0) / (tb.MonthForDepr))), @_Round) '+@_nl+
				N' FROM #t_khts tb  '+@_nl+
				N' OUTER APPLY '+@_nl+
				N' ( '+@_nl+
				N' SELECT SUM(x.DeprAllocationRate) AS DeprAllocationRate, SUM(x.DeprAllocationRate0) AS DeprAllocationRate0 '+@_nl+
				N' FROM '+@_nl+
				N' ( '+@_nl+
				N' SELECT DeprAllocationRate, 0 AS DeprAllocationRate0  '+@_nl+
				N' FROM vB3' + @_DataCode_Branch + N'AssetDoc_DeprAllocationRate b  '+@_nl+
				N' WHERE tb.Id = b.AssetId AND tb.EquityId = b.EquityId AND (b.DocDate BETWEEN @_DocDate1 AND @_DocDate2) AND ISNULL(b.AssetTransType, '''') <> ''KHAUHAO''  '+@_nl+
				N'     AND (b.DocDate < tb.DecreaseDate OR tb.DecreaseDate IS NULL) AND b.IsActive = 1 '+@_nl+
				N' UNION ALL '+@_nl+
				N' SELECT 0, DeprAllocationRate AS DeprAllocationRate0 -- Sản lượng đã phân bổ '+@_nl+
				N' FROM vB3' + @_DataCode_Branch + N'AssetDoc_Depreciation d '+@_nl+
				N' WHERE tb.Id = d.AssetId AND tb.EquityId = d.EquityId AND d.DocDate < @_DocDate1  '+@_nl+
				N'     AND (d.DocDate < tb.DecreaseDate OR tb.DecreaseDate IS NULL) AND d.IsActive = 1 '+@_nl+
				N' ) AS x '+@_nl+
				N' ) AS b '+@_nl+
				N' LEFT OUTER JOIN  '+@_nl+
				N' ( '+@_nl+
				N' SELECT c.AssetId, c.EquityId, '+@_nl+
				N' -- Sản lượng đã phân bổ trước khi Sử dụng ctr '+@_nl+
				N' SUM(IIF(c.DocDate < @_DocDate1, c.DeprAllocationRate, 0)) AS DeprAllocationRate0 '+@_nl+
				N' FROM B3' + @_DataCode_Branch + N'AssetDoc AS c '+@_nl+
				N' WHERE DocDate <= @_DateUsingBravo '+@_nl+
				N' AND c.AssetTransType = (N''KHAUHAO'') AND c.IsActive = 1 '+@_nl+
				N' GROUP BY c.AssetId, c.EquityId '+@_nl+
				N' ) AS c ON tb.Id = c.AssetId AND tb.EquityId = c.EquityId  '+@_nl+
				N' WHERE tb.AllocateByCapacity = 1 '                 
	--EXECUTE sp_executesql @_cmd,N'@_DocDate1 DATE, @_DocDate2 DATE, @_DateUsingBravo DATE, @_Round INT',@_DocDate1, @_DocDate2,@_DateUsingBravo,@_Round
	
	--26-02-2026 tạm rào lại 
		
		--select * from #t_khts return 

	ALTER TABLE #t_khts ADD MonthDeprSave NUMERIC(18, 2);
	ALTER TABLE #t_khts ADD MonthDeprSave1 NUMERIC(18, 2);

	UPDATE #t_khts SET MonthDepr = NetBookValue WHERE (NetBookValue < MonthDepr OR NetBookValue < 0)
 
	-- 21/11/24 KhuongNV: Lưu lại giá trị tháng khấu hao
	UPDATE #t_khts SET MonthDeprSave = MonthDepr

	-- Xử lý tình huống tự xác định khấu hao:
	SET @_cmd = N'
	IF EXISTS(SELECT * FROM #t_khts khts INNER JOIN vB3' + @_DataCode_Branch + N'AssetDoc ctts ON khts.Id = ctts.AssetId AND khts.EquityId = ctts.EquityId
	WHERE ctts.AssetTransType = ''KHAUHAO'' AND ctts.IsDeprAdjusted = 1 AND ctts.DocDate BETWEEN @_DocDate1 AND @_DocDate2)
	BEGIN  
		UPDATE #t_khts 
		SET IsDeprAdjusted = 1, 
			MonthDepr = ctts.IncDepreciation
		FROM #t_khts khts 
		INNER JOIN (
		SELECT AssetId, EquityId, SUM(IncDepreciation) AS IncDepreciation 
		FROM vB3' + @_DataCode_Branch + N'AssetDoc 
		WHERE AssetTransType = ''KHAUHAO'' AND IsDeprAdjusted = 1 AND DocDate BETWEEN @_DocDate1 AND @_DocDate2
		GROUP BY AssetId, EquityId
		) AS ctts ON khts.Id = ctts.AssetId AND khts.EquityId = ctts.EquityId
	END '

	EXECUTE sp_executesql @_cmd,N'@_DocDate1 DATE, @_DocDate2 DATE',@_DocDate1,@_DocDate2
 
	SET @_cmd=';WITH Cte '+@_nl+
		' AS ( '+@_nl+
		' SELECT DISTINCT DocDate,AssetId, 1 AS KhauHao   '+@_nl+
		' FROM vB3'+@_DataCode_Branch+'AssetDoc a'+@_nl+
		' WHERE IsActive=1 AND AssetTransType IN (''KHAUHAO'')  '+@_nl+
		'   AND DocDate<@_DocDate AND BranchCode=@_BranchCode '+@_nl+
		'   AND EXISTS(SELECT * FROM #t_khts WHERE Id=a.AssetId) '+@_nl+
		' ) '+@_nl+
		' UPDATE a '+@_nl+
		' SET SoThangDaKhauHao=ISNULL(b.SoThangDaKhauHao,0) '+@_nl+
		' FROM #t_khts a LEFT JOIN (SELECT AssetId,SUM(KhauHao) AS SoThangDaKhauHao  '+@_nl+
		'       FROM Cte GROUP BY AssetId) b ON a.Id=b.AssetId AND A.DeprMethod <> 3 ' 
	SET @_Declare='@_DocDate DATE,@_BranchCode VARCHAR(3)'

	EXEC sp_executesql @_cmd,@_Declare,@_DocDate1,@_BranchCode 

	--SoThangDaKhauHao cua tài sản, ccdc phân bổ theo sản lượng = số tổng lượng khấu hao khai báo - sản lượng đã phân bổ sản lượng 

	UPDATE #t_khts
	SET SoThangConLai = MonthForDepr - SoThangDaKhauHao
	where DeprMethod <> 3

	--DROP TABLE IF EXISTS #tblAssetMonthDepr
	--SELECT TOP 0 BranchCode,pa.Id,AssetId,ToolAssetId,MonthDepr INTO #tblAssetMonthDepr FROM B40AssetMonthDepr pa LEFT JOIN B40AssetMonthDeprDetail dt 
	--ON pa.Id = dt.ParentId

	--IF @_AssetType=0 
	--BEGIN
	
	--TRUNCATE TABLE #tblAssetMonthDepr
	
	--INSERT INTO #tblAssetMonthDepr(BranchCode, Id, AssetId, MonthDepr)
	--	SELECT BranchCode, pa.Id, AssetId, MonthDepr
	--	FROM B40AssetMonthDepr pa
	--		 LEFT JOIN B40AssetMonthDeprDetail dt ON pa.Id=dt.ParentId
	--	WHERE BranchCode=@_BranchCode AND pa.EffectiveDate=@_DocDate2 AND AssetId IS NOT NULL
	
	--IF EXISTS (SELECT *
	--			   FROM #t_khts AS tk
	--			   WHERE tk.Id IN(SELECT AssetId FROM #tblAssetMonthDepr))
	--	BEGIN
	--		UPDATE khts
	--		SET MonthDepr=t.MonthDepr , IsDeprAdjusted = 1
	--		FROM #t_khts khts
	--			 LEFT JOIN #tblAssetMonthDepr t ON khts.Id=t.AssetId
	--		WHERE khts.Id IN(SELECT AssetId FROM #tblAssetMonthDepr)
		
	--	END

	--END


	--IF @_AssetType = 1
	--BEGIN
	--		TRUNCATE TABLE #tblAssetMonthDepr

	--		INSERT INTO #tblAssetMonthDepr(BranchCode,Id,ToolAssetId,MonthDepr)
	--		SELECT BranchCode,pa.Id,ToolAssetId,MonthDepr FROM B40AssetMonthDepr pa LEFT JOIN B40AssetMonthDeprDetail dt 
	--			ON pa.Id = dt.ParentId WHERE BranchCode = @_BranchCode AND pa.EffectiveDate =@_DocDate2 AND ToolAssetId IS NOT NULL 

	--		IF EXISTS (SELECT * FROM #t_khts AS tk WHERE tk.Id IN (SELECT ToolAssetId FROM #tblAssetMonthDepr))
	--		BEGIN
	--			UPDATE #t_khts
	--			SET MonthDepr = t.MonthDepr,IsDeprAdjusted = 1
	--			FROM #t_khts khts INNER JOIN #tblAssetMonthDepr t ON khts.Id =t.ToolAssetId
	--			WHERE khts.Id IN (SELECT ToolAssetId FROM #tblAssetMonthDepr)
	--		END 
	--END 
	--DROP TABLE IF EXISTS #tblAssetMonthDepr


	IF @_DeprMethod = '3' OR EXISTS ( SELECT * FROM #t_DmTs WHERE AllocateByCapacity = 1)
	BEGIN 

		UPDATE t 
		SET ProductionCapacity0 = s.Quantity		 
		FROM  #t_khts t inner join #SanLuong s 
		ON t.Id = s.AssetId
		WHERE T.AllocateByCapacity = 1

		--	Trường  hợp không có nhập thành phẩm trong kỳ -> thì ko tính khấu hao các mã này
		DELETE #t_khts WHERE Id IN (SELECT sl.AssetId FROM #SanLuong AS sl WHERE sl.QuantityInput = 0)
	END 

	--select ProductionCapacity0,* from #t_khts return 
 
-- Thanh lý ngay trong tháng đầu tiên tăng
	SET @_cmd = N';WITH TLPB AS (  '+@_nl+
				N' SELECT b.AssetId, SUM(DeprAllocationRate) AS DeprAllocationRate, b.EquityId  '+@_nl+
				N' FROM vB3' + @_DataCode_Branch + N'AssetDoc_DeprAllocationRate b   '+@_nl+
				N' LEFT OUTER JOIN #t_khts c ON c.Id = b.AssetId AND c.EquityId = b.EquityId  '+@_nl+
				N' WHERE b.DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND ISNULL(b.AssetTransType, '''') <> ''KHAUHAO''   '+@_nl+
				N' AND b.IsActive = 1 AND (b.DocDate < c.DecreaseDate OR c.AllocateByCapacity = 1)  '+@_nl+
				N' GROUP BY AssetId, b.EquityId  '+@_nl+
				N' )  '+@_nl+
				N' SELECT t.BranchCode,t.ParentId,t.IsGroup,t.Id,t.EquityId,t.Name,t.Code,t.OriginalCost,t.NetBookValue,t.AmountForDepr,  '+@_nl+
				N' t.MonthDepr,t.FirstDeprDate,t.LastDeprDate,t.FirstUsedDate,t.StandbyForDisposal,t.MonthForDepr,t.IsDeprAdjusted,t.DecreaseDate,t.AllocateByCapacity,  '+@_nl+
				N' t.LastSuspendDate,t.LastResumeDate,t.FirstDiposalDate,t.MonthDeprSave,t.MonthDeprSave1,      '+@_nl+
				N' ISNULL(SanLuong.QuantityInPut, 0) AS DeprAllocationRate ,SoThangDaKhauHao,SoThangConLai ,t.ProductionCapacity0  '+@_nl+
				N' FROM #t_khts AS t  '+@_nl+
				N' LEFT  JOIN TLPB AS pb ON t.Id = pb.AssetId AND t.EquityId = pb.EquityId  '+@_nl+
				N' LEFT  JOIN #SanLuong AS  SanLuong ON t.Id = SanLuong.AssetId    '+@_nl+
				N'  WHERE MonthDepr > 0   '+@_nl+
				N' ORDER BY t.Code'

 EXECUTE sp_executesql @_cmd, N'@_DocDate1 DATE, @_DocDate2 DATE',@_DocDate1,@_DocDate2
 
 DROP TABLE IF EXISTS #t_BienDongCuoi;
 DROP TABLE IF EXISTS #SoThangSd; 
 DROP TABLE IF EXISTS #t_GtCl0;
 DROP TABLE IF EXISTS #t_BienDong;
 DROP TABLE IF EXISTS #t_khts;   
 DROP TABLE IF EXISTS #t_DmTs;
 DROP TABLE IF EXISTS #TLPB; 

END
GO


go

exec [usp_B30AssetDoc_CalcDepreciation_test]  @_Date='01/01/2026 00:00:00.000',@_Year='2026',@_AssetAccount=NULL,@_AssetId='3209522',@_AssetType=1,@_Round=0,@_BranchCode='I11',@_nUserId=1213,@_DeprMethod='3'