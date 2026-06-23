SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================
--REP_RevenueListing
--Bảng kê Doanh thu
--Author: TINNT
--CreatedAt: 2026-05-15 08:29:49.113
-- ============================================

ALTER PROCEDURE usp_Kct_RevenueListing
    @_DocDate1 DATE = ''
   ,@_DocDate2 DATE = ''
   ,@_Account NVARCHAR(2000) = '511'
   ,@_CrspAccount VARCHAR(2000) = '521'
   ,@_ExcludeCrspAccount VARCHAR(2000) = '911'
   ,@_nUserId INT = 0
   ,@_LangId INT = 0
   ,@_CurrencyCode0 CHAR(3) = 'VND'
   ,@_BranchCode VARCHAR(3) = ''
   ,@_LAYOUT_XML NVARCHAR(MAX) = '' OUTPUT
   ,@_GroupBy_DocNo INT = 0
   ,@_StrTime VARCHAR(256) = '' OUTPUT
   ,@_M_BranchFollowRevenueByBizdoc NVARCHAR(128) = 'I24'
   ,@_BranchReportId INT=NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
    SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId)
    SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode)
    DECLARE @_Time1 DATETIME = GETDATE()
           ,@DebugStepTime DATETIME = GETDATE()
           ,@_Step NVARCHAR(2000)
           ,@_DebugMsg NVARCHAR(256) = N''
           ,@_nl CHAR(1) = CHAR(13)

    DECLARE @_Key NVARCHAR(MAX) = N''
           ,@_Key2 NVARCHAR(MAX) = N''

    DECLARE @_MoneyType AS dbo.MoneyType = 0
           ,@_QuantityType dbo.QuantityType = 0
           ,@_TINYINTType TINYINT = 0
           ,@_INTType INT = 0
           ,@_CodeType VARCHAR(24) = ''
           ,@_SMALLDATETIMEType SMALLDATETIME = NULL
           ,@_NameType NVARCHAR(256) = N''
           ,@_UnitType NVARCHAR(8) = N''
           ,@_BizDocIdType VARCHAR(16) = N''
           ,@_DataCode VARCHAR(8) = '' --varchar	8
           ,@_MESId VARCHAR(64)
           ,@_BranchCode_Filter VARCHAR(3) = ''
           ,@_DataCode_Filter VARCHAR(4) = ''

    SELECT TOP 1
           @_DataCode = DataCode
    FROM dbo.B00Branch
    WHERE BranchCode = @_BranchCode

 

  	-- VũLA sửa riêng cho THACO
	-- Xử lý dữ liệu đơn vị cơ sở và năm làm việc
	DECLARE @_BranchList TABLE (BranchCode VARCHAR(3), DataCode_Branch VARCHAR(8),_Scan int default 0)
	

  IF ISNULL(@_BranchReportId, 0) <> 0
	BEGIN
		DROP TABLE IF EXISTS #BranchCode0
		SELECT a.BranchCode0 
		INTO #BranchCode0
		FROM dbo.B20BranchReportDetail a
			INNER JOIN dbo.B20BranchReport b ON a.BranchReportId = b.Id
		WHERE b.Id = @_BranchReportId

		DECLARE @_BranchCode0 VARCHAR(3) = ''

		WHILE EXISTS (SELECT * FROM #BranchCode0)
		BEGIN
			SELECT TOP 1 @_BranchCode0 = BranchCode0 FROM #BranchCode0

			DELETE #BranchCode0 WHERE BranchCode0 = @_BranchCode0

			INSERT INTO @_BranchList (BranchCode, DataCode_Branch)
			SELECT BranchCode, DataCode FROM [dbo].[ufn_B00Branch_GetChildTable](@_BranchCode0)
		END

		DROP TABLE IF EXISTS #BranchCode0
	END ELSE
	BEGIN
		INSERT INTO @_BranchList (BranchCode, DataCode_Branch)
		SELECT BranchCode, DataCode
		FROM [dbo].[ufn_B00Branch_GetChildTable](@_BranchCode)
	END

    --select * from @_BranchList return 

    SET @_Key = N''
    IF @_Account <> ''
    BEGIN
        SET @_Key += N'(' + N'(Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + N'%'')' + N')'
    END
    IF @_CrspAccount <> ''
    BEGIN
        SET @_Key += N'OR (' + N'  (CrspAccount LIKE ''' + REPLACE(@_CrspAccount, ',', '%'') OR (CrspAccount LIKE ''')
                     + N'%'')' + N')'
    END
    IF @_ExcludeCrspAccount <> ''
    BEGIN
        SET @_Key += N' AND ' + N'(' + N'(CrspAccount NOT LIKE '''
                     + REPLACE(@_ExcludeCrspAccount, ',', '%'') AND (CrspAccount NOT LIKE ''') + N'%'')' + N')'
    END
    SELECT @_Step = N' Start: Khởi tạo dữ liệu cơ bản & GenKey xong.';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                   ,@_DebugStepTime = @DebugStepTime OUTPUT;
    DROP TABLE IF EXISTS #K_CtTmp
    SELECT TOP (0)
           CAST(NULL AS INT) AS Id
          ,vbgl.BranchCode
          ,@_NameType AS BranchInfor
          ,vbgl.DocDate
          ,vbgl.DocNo
          ,vbgl.Description
          ,vbgl.Description AS Description0
          ,vbgl.DocGroup
          ,vbgl.DocCode                        --Detail Infor
          ,vbgl.Stt
          ,vbgl.RowId                          --Customer
          ,vbgl.CustomerId
          ,vbgl.CustomerId0
          ,@_CodeType AS CustomerCode
          ,@_NameType AS CustomerName
          ,@_CodeType AS MESGroupCode
          ,@_NameType AS MESGroupInfor
                                               --Item
          ,@_INTType AS ItemId
          ,@_CodeType AS ItemCode
          ,@_NameType AS ItemName
          ,@_CodeType AS ItemType
          ,@_NameType AS ItemTypeInfor
          ,@_UnitType AS Unit                  --ProductLevel
          ,@_INTType AS ProductGroupId         --Nhóm sản phẩm
          ,@_CodeType AS ProductGroupCode
          ,@_NameType AS ProductGroupName
          ,@_INTType AS ProductLevelId         --Nhóm sản phẩm cấp 1
          ,@_CodeType AS ProductLevelCode
          ,@_NameType AS ProductLevelName      --GeneralLedger Infor
          ,vbgl.CurrencyCode
          ,vbgl.Account
          ,vbgl.CrspAccount
          ,@_CodeType AS CreditAccount
          ,@_CodeType AS DebitAccount          --Amount Infor
          ,@_QuantityType AS Quantity
          ,vbgl.OriginalAmount
          ,vbgl.Amount
          ,@_MoneyType AS DebitAmount
          ,@_MoneyType AS CreditAmount         --Original Amount Infor
          ,@_MoneyType AS OriginalDebitAmount
          ,@_MoneyType AS OriginalCreditAmount --Other Infor
          ,@_MoneyType AS No_Co
          ,@_MoneyType AS Co_No
          ,@_BizDocIdType AS BizDocId_C2
          ,vbgl.DocNo AS DocNo_C2
          ,@_MESId AS BizDocMESId_C2
          ,CAST('' AS NVARCHAR(64)) AS ContractCode
          ,@_INTType AS CreatedBy
          ,@_NameType AS CreatedBy_Name
          ,@_SMALLDATETIMEType AS CreatedAt
          ,@_INTType AS ModifiedBy
          ,@_NameType AS ModifiedBy_Name
          ,@_SMALLDATETIMEType AS ModifiedAt
          ,CAST('' AS NVARCHAR(8)) AS Thang
          ,CAST(0 AS INT) AS Order1
    INTO #K_CtTmp
    FROM dbo.B00CtTmp AS vbgl
    EXECUTE dbo.usp_B30GeneralLedger_GetData @_DocDate1 = @_DocDate1
                                            ,@_DocDate2 = @_DocDate2
                                            ,@_Key1 = @_Key
                                            ,@_Key2 = ''
                                            ,@_CtTmp = N'#K_CtTmp'
                                            ,@_nUserId = @_nUserId
                                            ,@_LangId = @_LangId
                                            ,@_BranchCode = @_BranchCode
                                            ,@_CurrencyCode0 = @_CurrencyCode0
                                            ,@_BranchReportId = @_BranchReportId
                                            ,@_PrintExec = 0
 
    UPDATE #K_CtTmp
    SET CustomerId = CustomerId0

    SELECT @_Step = N' Bước 1: Lấy xong dữ liệu sổ cái.';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                   ,@_DebugStepTime = @DebugStepTime OUTPUT;

    -- ========================================================
    -- 3. THU THẬP DỮ LIỆU THỰC TẾ Thẻ kho (#CtTmp)
    -- ========================================================
    SET @_Key2 += N'EXISTS (SELECT 1 FROM #K_CtTmp ctt WHERE ctt.RowId = #SFile_B30TheKho_GetData.RowId AND ctt.Stt = #SFile_B30TheKho_GetData.Stt
	AND ctt.BranchCode = #SFile_B30TheKho_GetData.BranchCode AND ctt.DocCode = #SFile_B30TheKho_GetData.DocCode 
	)'

    DROP TABLE IF EXISTS #CtTmp
    SELECT TOP (0)
           Stt
          ,RowId
          ,ItemId
          ,DocCode,BranchCode
          ,@_QuantityType AS Quantity
    INTO #CtTmp
    FROM dbo.B00CtTmp

    EXEC dbo.usp_B30StockLedger_GetData @_Date1 = @_DocDate1
                                       ,@_Date2 = @_DocDate2
                                       ,@_Key2 = @_Key2
                                       ,@_CtTmp = N'#CtTmp'
                                       ,@_BranchCode = @_BranchCode 
                                       ,@_BranchReportId = @_BranchReportId
                                       ,@_CurrencyCode0 = @_CurrencyCode0


    UPDATE gl
    SET gl.ItemId = stock.ItemId
    FROM #K_CtTmp AS gl
         INNER JOIN #CtTmp AS stock ON gl.Stt = stock.Stt
                                       AND gl.RowId = stock.RowId

    SELECT @_Step = N' Bước 2: Lấy xong dữ liệu thẻ kho. Cập nhật ItemId từ (Thẻ kho).';

    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                   ,@_DebugStepTime = @DebugStepTime OUTPUT;

    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#K_CtTmp'
                                            ,@_List_Cats = 'Customer'
                                            ,@_SetString_Other = ',kq.MESGroupCode = ISNULL(Customer.MESGroupCode,'''') '

    /*
    B30AccDocSales	B30AccDocSales1
    */
    DECLARE @_StrExec NVARCHAR(MAX) = N''
 
    

       -- ========================================================    
  -- 4.1 Bổ sung thêm đoạn update riêng cho các đơn vị theo dõi doanh thu theo Hợp đồng (I24)
  -- ========================================================	
  
   EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#K_CtTmp', @_List_Cats = 'Item', @_SetString_Other = ',kq.ProductLevelId = Item.ProductLevelId,kq.Unit = Item.Unit'
 

  while exists(select top 1 * from @_BranchList where _Scan = 0)
  begin 

  select top 1 @_BranchCode_Filter = BranchCode,@_DataCode_Filter =DataCode_Branch
     from @_BranchList
     where _Scan = 0
     order by BranchCode

     

     UPDATE @_BranchList SET _Scan = 1 WHERE BranchCode= @_BranchCode_Filter

  IF CHARINDEX(CONCAT(',', @_BranchCode_Filter, ','), CONCAT(',', @_M_BranchFollowRevenueByBizdoc, ',')) >= 1 AND ISNULL(@_BranchCode_Filter, '') <> ''
      BEGIN
          EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#K_CtTmp', @_List_Cats = 'Item'
            
          SELECT  @_StrExec = N'UPDATE kq
SET kq.ProductGroupId = biz.ProductGroupId
FROM #K_CtTmp kq INNER JOIN dbo.B3' + @_DataCode_Filter + N'BizDocSO AS biz ON kq.BizDocId_C2 = biz.BizDocId'
          EXEC ( @_StrExec )
    
      END
   
  BEGIN

 DECLARE   @_Declare NVARCHAR(MAX) = '@_DocDate1 DATE,@_DocDate2 DATE'  
  SELECT @_StrExec
      = N'
      IF  exists(select * from dbo.B3' + @_DataCode_Filter+ N'AccDocSales1 where 
      ProductGroupId IS NOT NULL AND DocDate BETWEEN @_DocDate1 AND @_DocDate2 )
      UPDATE kq
      SET	 kq.ProductGroupId = IIF(ISNULL(kq.ProductGroupId,0)=0, DocSales1.ProductGroupId,kq.ProductGroupId)		 
  FROM #K_CtTmp kq INNER JOIN dbo.B3' + @_DataCode_Filter+ N'AccDocSales1 AS DocSales1 
  ON kq.Stt = DocSales1.Stt and kq.RowId = DocSales1.RowId AND DocSales1.DocDate BETWEEN @_DocDate1 AND @_DocDate2
  AND DocSales1.ProductGroupId IS NOT NULL
  where ISNULL(kq.ProductGroupId,0)=0 
  
  '  
  
   
  SET @_Declare = '@_DocDate1 DATE,@_DocDate2 DATE'
   EXECUTE sys.sp_executesql @_StrExec, @_Declare,@_DocDate1  , @_DocDate2       
     
  SELECT @_StrExec
      = N'
      IF  exists(select * from dbo.B3' + @_DataCode_Filter+ N'AccDocJournalEntry where   ProductGroupId IS NOT NULL AND DocDate BETWEEN @_DocDate1 AND @_DocDate2 )      
      UPDATE kq
      SET	 kq.ProductGroupId = IIF(ISNULL(kq.ProductGroupId,0)=0, DocSales1.ProductGroupId,kq.ProductGroupId)		 
  FROM #K_CtTmp kq INNER JOIN dbo.B3' + @_DataCode_Filter+ N'AccDocJournalEntry AS DocSales1 ON kq.Stt = DocSales1.Stt 
  AND DocSales1.ProductGroupId IS NOT NULL
  and kq.RowId = DocSales1.RowId where ISNULL(kq.ProductGroupId,0)=0  '
     EXECUTE sys.sp_executesql @_StrExec, @_Declare,@_DocDate1  , @_DocDate2  

  END 

  END   

   UPDATE  kq
          SET kq.ProductLevelId = ProductClass.ProductLevelId
          FROM    #K_CtTmp kq
                  --Nhóm sp
                  INNER JOIN B20ProductGroup ProductGroup WITH ( NOLOCK ) ON kq.ProductGroupId = ProductGroup.Id
                  -- Nhóm sp HN2
                  INNER JOIN B20ProductClass ProductClass WITH ( NOLOCK ) ON ProductGroup.ProductClassId = ProductClass.Id
                  where isnull(kq.ProductLevelId, 0) = 0
  

 
  SELECT  @_Step = N' Bước 4. Xong Update các trường Code,Name theo danh mục cho bảng #K_CtTmp';
  EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step, @_DebugStepTime = @DebugStepTime OUTPUT;

   

    UPDATE k
    SET k.Thang = CONCAT(STR(YEAR(k.DocDate), 4), REPLACE(STR(MONTH(k.DocDate), 2), ' ', '0'))
    FROM #K_CtTmp AS k

      

    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#K_CtTmp'
                                            ,@_List_Cats = 'ProductGroup'
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#K_CtTmp'
                                            ,@_List_Cats = 'ProductLevel'

    UPDATE #K_CtTmp
    SET ItemTypeInfor = IIF(k.ItemType <> '', CONCAT(k.ItemType, ' : ', cl.Name), '')
    FROM #K_CtTmp AS k
         INNER JOIN dbo.B20Class AS cl ON k.ItemType = cl.Code
                                          AND cl.ParentCode = 'DMVT_Loai_Vt'



    UPDATE #K_CtTmp
    SET MESGroupInfor = IIF(k.MESGroupCode <> '', CONCAT(k.MESGroupCode, ' : ', cl.Name), '')
    FROM #K_CtTmp AS k
         INNER JOIN dbo.B20Class AS cl ON k.MESGroupCode = cl.Code
                                          AND cl.ParentCode = 'MESGroupCode'


    --loại trừ Kết chuyển chiết khấu bán hàng  
    DELETE #K_CtTmp
    WHERE (
              Account LIKE '511%'
              AND CrspAccount LIKE '521%'
          )
          OR
          (
              Account LIKE '521%'
              AND CrspAccount LIKE '511%'
          )
          OR CrspAccount LIKE '911%'

    /*Tiền doanh thu 511 = Phát sinh có - phát sinh nợ */
    UPDATE #K_CtTmp
    SET Amount = CreditAmount - DebitAmount
    DELETE #K_CtTmp
    WHERE Amount = 0
    UPDATE #K_CtTmp
    SET BranchInfor = CONCAT(bb.BranchCode, ' : ', bb.BranchName)
    FROM #K_CtTmp AS c
         INNER JOIN dbo.B00Branch AS bb ON c.BranchCode = bb.BranchCode
    IF @_GroupBy_DocNo = 1
    BEGIN
        ;WITH cte
         AS (SELECT kct.Stt
                   ,kct.DocDate
                   ,kct.DocNo
                   ,MAX(kct.Description) AS Description
                   ,(kct.Account) AS Account
                   ,(kct.CrspAccount) AS CrspAccount
                   ,SUM(kct.DebitAmount) AS DebitAmount
                   ,SUM(kct.CreditAmount) AS CreditAmount
                   ,SUM(kct.Quantity) AS Quantity
                   ,SUM(kct.Amount) AS Amount
                   ,MAX(kct.Id) AS Id
                   ,MAX(kct.DocCode) AS DocCode
                   ,kct.BranchInfor
             FROM #K_CtTmp AS kct
             GROUP BY kct.Stt
                     ,kct.DocNo
                     ,kct.DocDate
                     ,kct.Account
                     ,kct.CrspAccount
                     ,kct.BranchInfor)
        SELECT *
        FROM cte AS k
        ORDER BY k.BranchInfor
                ,k.DocDate
                ,k.DocNo
    END
    ELSE
    BEGIN
        SELECT *
        FROM #K_CtTmp AS kct
        ORDER BY kct.DocDate
                ,kct.DocNo

        --thêm bảng lấy dữ liệu chưa có gán thông tin MESGroupCode 
        SELECT *
        FROM #K_CtTmp AS kct
        WHERE kct.MESGroupCode = ''
        ORDER BY kct.DocDate
                ,kct.DocNo

        --thêm bảng lấy dữ liệu chưa có gán thông tin ProductLevelCode
        SELECT *
        FROM #K_CtTmp AS kct
        WHERE kct.ProductLevelCode = ''
        ORDER BY kct.DocDate
                ,kct.DocNo

    END
    SET @_StrTime = RTRIM(LTRIM(dbo.ufn_sys_StrExcuteTime(@_Time1, GETDATE())))
    SET @_DebugMsg
        = N'--- TỔNG THỜI GIAN CHẠY SP: ' + CAST(DATEDIFF(ms, @_Time1, GETDATE()) AS VARCHAR) + N' ms ~ '
          + CAST(DATEDIFF(ss, @_Time1, GETDATE()) AS VARCHAR) + N' ss ---';
    PRINT @_DebugMsg
    DROP TABLE IF EXISTS #K_CtTmp
                        ,#CtTmp
END
GO



set dateformat dmy 

exec usp_Kct_RevenueListing @_DocDate1='01/01/2026 00:00:00.000',@_DocDate2='10/01/2026 00:00:00.000',@_Account='511,521',@_CrspAccount='521',@_ExcludeCrspAccount='911,521,3332,333301,33381',@_BranchCode='I00',@_StrTime='00:00:05'  ,@_BranchReportId=17641848