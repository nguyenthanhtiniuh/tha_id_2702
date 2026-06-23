SET ANSI_NULLS ON;


GO
SET QUOTED_IDENTIFIER ON;


GO
--22-06-2026
--ver check
CREATE OR ALTER PROCEDURE usp_REP_Tinh_BusinessPlan_ByMESGroup_VerCheck
@_DocDate1 DATE='20260101', @_DocDate2 DATE='20260131', @_DocDatePlan2 DATE='20251231', @_ProductId VARCHAR (24)='', @_BranchCode NVARCHAR (24)='I09', 
@_Account NVARCHAR (2000)='511,521', @_ExcludeCrspAccount VARCHAR (254)='911', @_nUserId INT=0, @_LangId INT=0, @_CurrencyCode0 CHAR (3)='VND', 
@_LAYOUT_XML NVARCHAR (MAX)='' OUTPUT, @_IsRound INT=0, @_DefinitionTableName NVARCHAR (32)=N'B10BusinessPlanDetail', @_tblTmp NVARCHAR (32)='',
@_RepId1 VARCHAR (16)='I000000007', @_BranchReportId INT=NULL, @_StrTime NVARCHAR (128)=NULL OUTPUT, @_IsGetPlan INT=0 
,@_Message Nvarchar(max)='' OUTPUT
AS
BEGIN
    SET NOCOUNT ON; -- ======================================================== -- 1. KHỞI TẠO BIẾN VÀ BẢNG TẠM CƠ SỞ -- ========================================================
    DECLARE @_Time1 AS DATETIME = GETDATE(), @_Time2 AS DATETIME;
    DECLARE @_Num_Round AS INT = CASE WHEN @_IsRound = 1 THEN 1000000 ELSE 1 END;
    DECLARE @_nl AS CHAR (1) = CHAR(13), @_Key2 AS VARCHAR (MAX) = '';
    DECLARE @DebugStepTime AS DATETIME = GETDATE(), @_Step AS NVARCHAR (2000), @_DebugMsg AS NVARCHAR (256) = N''; -- ======================================================== -- 2. XỬ LÝ BỘ LỌC CHI NHÁNH VÀ TÀI KHOẢN -- ========================================================
    DECLARE @_MoneyType AS dbo.MoneyType = 0, @_TINYINTType AS TINYINT = 0, @_INTType AS INT = 0, @_CodeType AS VARCHAR (24) = '', @_NameType AS NVARCHAR (256) = N'';
    DECLARE @_Key AS VARCHAR (MAX) = 'Stt = ''' + @_RepId1 + ''' ';
    DECLARE @_Key_Acc AS VARCHAR (MAX) = '';
    IF @_Account <> ''
        SET @_Key_Acc = N'((Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + '%''))';
    IF @_ExcludeCrspAccount <> ''
        SET @_Key_Acc += ' AND ((CrspAccount NOT LIKE ''' + REPLACE(@_ExcludeCrspAccount, ',', '%''') + '%''))';
    SELECT @_Step = N' Start: Khởi tạo dữ liệu cơ bản & GenKey xong.';
    EXECUTE dbo.usp_sys_CheckDebugTime @_StepName = @_Step, @_DebugStepTime = @DebugStepTime OUTPUT;
    DROP TABLE IF EXISTS #ColList;
    CREATE TABLE #ColList (
        Tt         INT           ,
        M_DocDate1 INT           ,
        M_DocDate2 INT           ,
        Y_DocDate  INT           ,
        ColName    NVARCHAR (128),
        UserData0  NVARCHAR (128),
        Row_0_VN   NVARCHAR (256),
        Row_0_EN   NVARCHAR (256),
        UserData1  NVARCHAR (128),
        Row_1_VN   NVARCHAR (256),
        Row_1_EN   NVARCHAR (256),
        _TextAlign NVARCHAR (24)  DEFAULT '',
        _Width     NVARCHAR (24)  DEFAULT '',
        _Format    NVARCHAR (24)  DEFAULT '',
        _ForeColor NVARCHAR (24)  DEFAULT '',
        _BackColor NVARCHAR (24)  DEFAULT '',
        Type       INT           
    );
    INSERT INTO #ColList
    EXECUTE dbo.usp_GenerateReportHeader_ActualPlan @_DocDate1 = @_DocDate1, @_DocDate2 = @_DocDate2, @_LAYOUT_XML = @_LAYOUT_XML OUTPUT; -- VũLA sửa riêng cho THACO -- Xử lý dữ liệu đơn vị cơ sở và năm làm việc
    DECLARE @_BranchList TABLE (
        BranchCode      VARCHAR (3),
        DataCode_Branch VARCHAR (8),
        _Scan           INT         DEFAULT 0);
    IF ISNULL(@_BranchReportId, 0) <> 0
        BEGIN
            DROP TABLE IF EXISTS #BranchCode0;
            SELECT a.BranchCode0
            INTO   #BranchCode0
            FROM   dbo.B20BranchReportDetail AS a
                   INNER JOIN
                   dbo.B20BranchReport AS b
                   ON a.BranchReportId = b.Id
            WHERE  b.Id = @_BranchReportId;
            DECLARE @_BranchCode0 AS VARCHAR (3) = '';
            WHILE EXISTS (SELECT *
                          FROM   #BranchCode0)
                BEGIN
                    SELECT TOP 1 @_BranchCode0 = BranchCode0
                    FROM   #BranchCode0;
                    DELETE #BranchCode0
                    WHERE  BranchCode0 = @_BranchCode0;
                    INSERT INTO @_BranchList (BranchCode, DataCode_Branch)
                    SELECT BranchCode,
                           DataCode
                    FROM   [dbo].[ufn_B00Branch_GetChildTable](@_BranchCode0);
                END
            DROP TABLE IF EXISTS #BranchCode0;
        END
    ELSE
        BEGIN
            INSERT INTO @_BranchList (BranchCode, DataCode_Branch)
            SELECT BranchCode,
                   DataCode
            FROM   [dbo].[ufn_B00Branch_GetChildTable](@_BranchCode);
        END -- ======================================================== -- 3. THU THẬP DỮ LIỆU SỔ CÁI (GENERAL LEDGER) -- ========================================================
    DROP TABLE IF EXISTS #CtTmpGeneralLedger;
    SELECT TOP 0 CAST (-1 AS INT) AS Id,
                 BranchCode,
                 DocDate,
                 DocCode,
                 CAST ('' AS NVARCHAR (24)) AS Col_DocDate,
                 CAST ('' AS NVARCHAR (24)) AS M_DocDate,
                 CAST ('' AS NVARCHAR (24)) AS Y_DocDate,
                 CAST ('' AS NVARCHAR (24)) AS MesGroupCode,
                 CustomerId0,
                 CustomerId,
                 Amount2,
                 OriginalAmount2,
                 Stt,
                 RowId,
                 DebitAccount,
                 CreditAccount,
                 Account,
                 CrspAccount,
                 Amount,
                 OriginalAmount,
                 OriginalAmount AS Co_No,
                 OriginalAmount AS No_Co,
                 CAST (NULL AS INT) AS DocGroup,
                 ItemId,
                 CAST (NULL AS VARCHAR (24)) AS ItemCode,
                 CAST (NULL AS INT) AS ProductId,
                 CAST ('' AS NVARCHAR (128)) AS _FormatStyleKey,
                 DebitAmount,
                 OriginalDebitAmount,
                 CreditAmount,
                 Quantity,
                 CurrencyCode,
                 --Nhóm sản phẩm hợp nhất cấp 1
    CAST (NULL AS INT) AS ProductLevelId,
                 --Nhóm sản phẩm hợp nhất cấp 2
    CAST (NULL AS INT) AS ProductClassId,
                 --Nhóm sản phẩm 
    CAST (NULL AS INT) AS ProductGroupId,
                 --Dòng sản phẩm 
    CAST (NULL AS INT) AS ProductLineId,
                 @_CodeType AS Thang
    INTO   #CtTmpGeneralLedger
    FROM   dbo.B00CtTmp WITH (NOLOCK);
    EXECUTE dbo.usp_B30GeneralLedger_GetData @_DocDate1 = @_DocDate1, @_DocDate2 = @_DocDate2, @_Key1 = @_Key_Acc, @_Key2 = '', @_CtTmp = N'#CtTmpGeneralLedger', @_nUserId = @_nUserId, @_LangId = @_LangId, @_BranchReportId = @_BranchReportId, @_BranchCode = @_BranchCode, @_CurrencyCode0 = @_CurrencyCode0;
    SELECT @_Step = N' Bước 1: Lấy xong dữ liệu Số phát sinh sổ cái (#CtTmpGeneralLedger).';
    EXECUTE dbo.usp_sys_CheckDebugTime @_StepName = @_Step, @_DebugStepTime = @DebugStepTime OUTPUT;
    DELETE #CtTmpGeneralLedger
    WHERE  Amount = 0;
    UPDATE  #CtTmpGeneralLedger
        SET Amount         = IIF (DocGroup = 1, -Amount, Amount),
            OriginalAmount = IIF (DocGroup = 1, -OriginalAmount, OriginalAmount),
            Quantity       = IIF (DocGroup = 1, -Quantity, Quantity);
    UPDATE  #CtTmpGeneralLedger
        SET Co_No = CreditAmount - DebitAmount;
    DELETE #CtTmpGeneralLedger
    WHERE  (Account LIKE '511%'
            AND CrspAccount LIKE '521%')
           OR (Account LIKE '521%'
               AND CrspAccount LIKE '511%')
           OR CrspAccount LIKE '911%'; --tao bang lay so ke hoach
    DROP TABLE IF EXISTS #FinPlan;
    SELECT TOP (0) DocDate,
                   CAST (NULL AS INT) AS _Year,
                   CAST (NULL AS INT) AS _Month,
                   CAST ('' AS NVARCHAR (24)) AS Col_DocDate,
                   CustomerId,
                   ProfitCenterId,
                   ItemId,
                   CAST (NULL AS TINYINT) AS ItemType,
                   CAST (NULL AS INT) AS ProductId,
                   CAST (0 AS NUMERIC (18, 0)) AS OriginalUnitCost,
                   CAST (0 AS NUMERIC (18, 0)) AS Amount,
                   CAST (0 AS NUMERIC (18, 0)) AS OriginalAmount,
                   BranchCode,
                   --Nhóm sản phẩm hợp nhất cấp 1
    CAST (NULL AS INT) AS ProductLevelId,
                   --Nhóm sản phẩm hợp nhất cấp 2
    CAST (NULL AS INT) AS ProductClassId,
                   --Nhóm sản phẩm 
    CAST (NULL AS INT) AS ProductGroupId,
                   --Dòng sản phẩm 
    CAST (NULL AS INT) AS ProductLineId,
                   --Phân loại khách hàng
    CAST ('' AS VARCHAR (24)) AS MESGroupCode
    INTO   #FinPlan
    FROM   dbo.B00CtTmp;
    EXECUTE dbo.usp_sys_DefaultTable @_Table = '#FinPlan';
    IF @_IsGetPlan = 1
        EXECUTE usp_FinPlanDetail_GetData @_CtTmp = '#FinPlan', @_BranchCode = @_BranchCode, @_PrintExec = 0;
    UPDATE  #CtTmpGeneralLedger
        SET M_DocDate = MONTH(DocDate),
            Y_DocDate = YEAR(DocDate);
    UPDATE  GE
        SET GE.Thang = cl.ColName
    FROM    #CtTmpGeneralLedger AS GE
            INNER JOIN
            #ColList AS cl
            ON GE.M_DocDate = cl.Tt
               AND GE.Y_DocDate = cl.Y_DocDate
               AND cl.Type = '0';
    UPDATE  ctgl
        SET ctgl.MESGroupCode = cus.MESGroupCode
    FROM    #CtTmpGeneralLedger AS ctgl
            INNER JOIN
            dbo.B20Customer AS cus WITH (NOLOCK)
            ON ctgl.CustomerId0 = cus.Id;
    DROP TABLE IF EXISTS #tblTmp1Grid2;
    CREATE TABLE #tblTmp1Grid2 (
        Id           INT            DEFAULT 0,
        --BranchCode   NVARCHAR (24)  DEFAULT '',
        Key_Where    VARCHAR (4000) DEFAULT '',
        VarValue     VARCHAR (64)   DEFAULT '',
        VarKey       VARCHAR (24)   DEFAULT '',
        BuiltinOrder INT           ,
        IsPrint      INT           
    );
    EXECUTE dbo.usp_sys_CreateTable @_Table = '#tblTmp1Grid2', @_BaseTable = @_DefinitionTableName;
    SELECT @_Key = 'Stt = ''' + @_RepId1 + ''' ';
    EXECUTE dbo.usp_sys_Append @_TableSource = @_DefinitionTableName, @_TableDestination = '#tblTmp1Grid2 ', @_Where_TableSource = @_Key; -- Thêm các cột động vào khung báo cáo
    DECLARE @_AlterCols AS NVARCHAR (MAX) = N'';
    DECLARE @_AlterColsOriginal AS NVARCHAR (MAX) = N'';
    SELECT @_AlterCols = STRING_AGG(QUOTENAME(ColName) + ' NUMERIC(18,2) DEFAULT 0 NOT NULL', ', ')
    FROM   #ColList;
    DECLARE @_SqlAlterHeaders AS NVARCHAR (MAX) = N'ALTER TABLE #tblTmp1Grid2 ADD ' + @_AlterCols + N';';
    EXECUTE sys.sp_executesql @_SqlAlterHeaders; -- ======================================================== -- 5. XỬ LÝ DỮ LIỆU THỰC TẾ (SINGLE-PASS AGGREGATION) -- ========================================================
    UPDATE  #CtTmpGeneralLedger
        SET CustomerId = CustomerId0;
    UPDATE  #CtTmpGeneralLedger
        SET Col_DocDate     = FORMAT(DocDate, 'yyyyMM'),
            M_DocDate       = MONTH(DocDate),
            Y_DocDate       = YEAR(DocDate),
            Amount2         = ISNULL(Amount2, 0),
            OriginalAmount2 = ISNULL(OriginalAmount2, 0);
    UPDATE  #CtTmpGeneralLedger
        SET Amount2         = ISNULL(Amount, 0),
            OriginalAmount2 = ISNULL(OriginalAmount, 0);
    UPDATE  #CtTmpGeneralLedger
        SET ProductLevelId = ISNULL(item.ProductLevelId, NULL),
            ProductClassId = ISNULL(item.ProductClassId, NULL),
            ProductGroupId = ISNULL(item.ProductGroupId, NULL),
            ProductLineId  = ISNULL(item.ProductLineId, NULL),
            ItemCode       = item.Code
    FROM    #CtTmpGeneralLedger AS tmm
            INNER JOIN
            B20Item AS item WITH (NOLOCK)
            ON tmm.ItemId = item.Id;
    SET @_LAYOUT_XML = N'<panelReporter>' + @_nl + N'   <Controls> ' + @_nl + N' ' + CONCAT(@_LAYOUT_XML, @_nl, '') + @_nl + N'   </Controls> ' + @_nl + N'</panelReporter>' + @_nl;
    DROP TABLE IF EXISTS #kq_MesGroup;
    SELECT TOP (0) BranchCode
    INTO   #kq_MesGroup
    FROM   #CtTmpGeneralLedger;
    DECLARE @query AS NVARCHAR (MAX) = N'SELECT * FROM #CtTmpGeneralLedger where isnull(MesGroupCode,'''') <>'''' ';
    DECLARE @_jsonData AS NVARCHAR (MAX) = (SELECT *
                                            FROM   #ColList AS cl
                                            FOR    JSON AUTO);
    DECLARE @_ColName_Total AS NVARCHAR (128) = (SELECT   TOP (1) ColName
                                                 FROM     #ColList
                                                 WHERE    Tt = 0
                                                 ORDER BY Tt ASC);
    EXECUTE dbo.usp_pivot_KHTC @query_ColList = ' SELECT  ColName FROM #ColList  ', @on_cols_ColList = 'ColName', @_ColName_Total = @_ColName_Total, @query = @query, @on_rows = 'BranchCode', @on_cols = 'Thang', @agg_func = 'SUM', @agg_col = 'Co_No', @bang = '#kq_MesGroup', @_PrintExec = 0;
    DROP TABLE IF EXISTS #kq_ProductLevel;
    SELECT TOP (0) BranchCode
    INTO   #kq_ProductLevel
    FROM   #CtTmpGeneralLedger;
    SELECT @query = N'SELECT * FROM #CtTmpGeneralLedger where isnull(ProductLevelId,0) <>0  ';
    EXECUTE dbo.usp_pivot_KHTC @query_ColList = ' SELECT  ColName FROM #ColList    ', @on_cols_ColList = 'ColName', @_ColName_Total = @_ColName_Total, @query = @query, @on_rows = 'BranchCode', @on_cols = 'Thang', @agg_func = 'SUM', @agg_col = 'Co_No', @bang = '#kq_ProductLevel', @_PrintExec = 0;
    DECLARE @_SqlSetStr AS NVARCHAR (MAX);
    SELECT @_SqlSetStr = STRING_AGG(QUOTENAME(ColName) + ' = ISNULL(b.' + QUOTENAME(ColName) + ', 0)', ', ')
    FROM   #ColList;
    SELECT   G2.*,
             S.BranchCode,
             @_NameType AS BranchInfo 
    INTO     #tblTmp1Grid2_Result
    FROM     #tblTmp1Grid2 AS G2 OUTER APPLY @_BranchList AS S
    ORDER BY BranchCode ASC;
    UPDATE  #tblTmp1Grid2_Result
        SET BranchInfo = concat(re.BranchCode, ' - ', br.BranchName)
    FROM    #tblTmp1Grid2_Result AS re
            INNER JOIN
            B00Branch AS br
            ON re.BranchCode = br.BranchCode; --UPDATE HMCT
    DECLARE @_SqlUpdateAgg AS NVARCHAR (MAX) = N' 
        UPDATE a
        SET ' + @_SqlSetStr + N'
        FROM #tblTmp1Grid2_Result a
        INNER JOIN #kq_MesGroup b ON a.BranchCode = b.BranchCode     WHERE VarKey=''MESGroupCode'' ';
    EXECUTE sys.sp_executesql @_SqlUpdateAgg; --ProductLevelId
    SELECT @_SqlUpdateAgg = N' 
        UPDATE a
        SET ' + @_SqlSetStr + N'
        FROM #tblTmp1Grid2_Result a
        INNER JOIN #kq_ProductLevel b ON a.BranchCode = b.BranchCode     WHERE VarKey=''ProductLevelId'' ';
    EXECUTE sys.sp_executesql @_SqlUpdateAgg;

    declare @_SqlSelectStr  nvarchar(max) = ''
    
    select @_SqlSelectStr = STRING_AGG(   '   ISNULL(MESGroup.' + QUOTENAME(ColName) + ', 0) - ISNULL(ProductLevel.' + QUOTENAME(ColName) + ', 0)  as '+ QUOTENAME(ColName) , ', ') FROM   #ColList;

    select @_SqlSetStr = STRING_AGG( QUOTENAME(''+ColName)+    ' =   ISNULL(Summa.' + QUOTENAME(ColName) + ', 0)   ' , ', ') FROM   #ColList;

    SELECT @_SqlUpdateAgg = N' 
    ;WITH CTE_MESGroup AS (SELECT * FROM #tblTmp1Grid2_Result WHERE   VarKey=''MESGroupCode''  )
    , CTE_ProductLevel AS (SELECT * FROM #tblTmp1Grid2_Result WHERE   VarKey=''ProductLevelId''  )
    , CTE_Summary AS  (SELECT  ProductLevel.BranchCode,'+@_SqlSelectStr+' FROM CTE_MESGroup MESGroup INNER JOIN CTE_ProductLevel  ProductLevel ON MESGroup.BranchCode  =  ProductLevel.BranchCode  )
    UPDATE re
    SET '+@_SqlSetStr+'
    FROM #tblTmp1Grid2_Result re INNER JOIN CTE_Summary Summa on re.BranchCode = Summa.BranchCode
    WHERE   ISNULL(VarKey,'''') = ''''  ' 
 
      EXEC (@_SqlUpdateAgg) 


      select @_SqlUpdateAgg = '
      update #tblTmp1Grid2_Result
      SET _FormatStyleKey = ''RedColor''
      where isnull('+@_ColName_Total+',0) <> 0 AND ISNULL(VarKey,'''') = '''' '
        EXEC (@_SqlUpdateAgg) 


       
       declare @_BranchLst_Err nvarchar(max)

       ;with cte as 
       (select distinct BranchInfo from #tblTmp1Grid2_Result WHERE _FormatStyleKey = 'RedColor')
       select @_BranchLst_Err =  STRING_AGG(BranchInfo, NCHAR(13) + NCHAR(10)) from cte

    IF EXISTS (SELECT 1 FROM #tblTmp1Grid2_Result WHERE _FormatStyleKey = 'RedColor' AND ISNULL(VarKey,'')='')
    begin
          
		select @_Message = N'Các đơn vị cần lưu ý xem lại !'+ NCHAR(13) + NCHAR(10) + @_BranchLst_Err
    end 

 
    SELECT   *
    FROM     #tblTmp1Grid2_Result
    WHERE    IsPrint = 1
    ORDER BY BranchCode, BuiltinOrder;

    SET @_StrTime = RTRIM(LTRIM(dbo.ufn_sys_StrExcuteTime(@_Time1, GETDATE())));
    SET @_DebugMsg = N'--- TỔNG THỜI GIAN CHẠY SP: ' + CAST (DATEDIFF(ms, @_Time1, GETDATE()) AS VARCHAR) + N' ms ~ ' + CAST (DATEDIFF(ss, @_Time1, GETDATE()) AS VARCHAR) + N' ss ---';
    DROP TABLE IF EXISTS #ColList, #BranchCode0, #CtTmp, #tblTmp1, #tblTmp1Grid2, #AggregatedData, #AggGrid2;
END 

go 

set dateformat dmy
exec 


usp_REP_Tinh_BusinessPlan_ByMESGroup_VerCheck @_DocDate1='01/01/2026 00:00:00.000',@_DocDate2='30/01/2026 00:00:00.000',@_BranchCode='I00',@_nUserId=1213,@_LangId=0,@_CurrencyCode0='VND',@_IsRound=0,@_RepId1='I000000007',@_BranchReportId=17641848,@_StrTime='00:00:00'  ,@_IsGetPlan=0