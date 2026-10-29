SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE dbo.usp_B30AccDoc_GetDataInfo 
    @_IdList XML = NULL
  , @_BranchCode VARCHAR(3) = '' OUTPUT
  , @_LangId INT = 0
  , @_nUserId INT = 0
  , @_FiscalYear VARCHAR(8) = ''
  , @_ParentCommandKey NVARCHAR(24) = ''
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @_DataCode              VARCHAR(16)   = ''
          , @_StrExec               NVARCHAR(MAX) = ''
          , @_DocName               VARCHAR(64)   = ''
          , @_DetailName            VARCHAR(64)   = ''
          , @_EntityAssetName       VARCHAR(400)  = 'B30AccDocEntityAsset'
          , @_FinancialPlanLockDate DATE          = ''
          , @_StartDate             DATE          = '';

    -- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào  
    SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId);
    SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode);

    SELECT TOP (1)
           @_DocName    = TableHeader
         , @_DetailName = Ct0_TableName
    FROM B10THACOID.dbo.B00DmCt
    WHERE Ma_Ct = @_ParentCommandKey
    ORDER BY Ma_Ct ASC;

    SELECT TOP (1)
           @_StartDate             = StartDate
         , @_FinancialPlanLockDate = FinancialPlanLockDate
    FROM B10THACOID.dbo.B00FiscalYear
    WHERE Name = @_FiscalYear
          AND BranchCode = @_BranchCode
    ORDER BY Name
           , BranchCode;

    IF @_IdList IS NOT NULL
    BEGIN

        DROP TABLE IF EXISTS #IdList;
        SELECT tbl.col.value('@Id', 'INT') AS Id
        INTO #IdList
        FROM @_IdList.nodes('/NewDataSet/Ct') AS tbl(col);

        SELECT @_DataCode = DataCode
        FROM dbo.B00Branch
        WHERE BranchCode = @_BranchCode;

        SELECT @_DocName = REPLACE(@_DocName, 'B30', 'B3' + @_DataCode);

        DROP TABLE IF EXISTS #AccDoc;
        SELECT TOP (0)
               Stt
             , DocNo
        INTO #AccDoc
        FROM dbo.B30AccDoc;

        SELECT @_StrExec
            = '
		INSERT INTO #AccDoc(Stt,DocNo)
		SELECT Stt,DocNo    
        FROM dbo.' + @_DocName
              + '
        WHERE Id IN
              (
                  SELECT Id FROM #IdList
              )
              AND BranchCode = ''' + @_BranchCode + ''' ';
        EXEC (@_StrExec);

        --lay du lieu chi tiet
        IF @_DetailName = 'B30AccDocOther'
            SELECT @_DetailName = 'vB30AccDocOther_Edit';
        SELECT @_DetailName = REPLACE(@_DetailName, 'B30', 'B3' + @_DataCode);
        SELECT @_DocName = REPLACE(@_DocName, 'B30', 'B3' + @_DataCode);

		--2026-10-05 => thêm đoạn kiểm tra khóa sổ
        BEGIN
            DECLARE @_Count_Record INT = 0;
            SELECT @_StrExec
                = N'  SELECT @_Count_Record =  COUNT(*) FROM ' + @_DetailName + ' dt
			WHERE dt.DocDate BETWEEN ''' + CONVERT(VARCHAR(11), @_StartDate) + N''' AND '''
                  + CONVERT(VARCHAR(11), @_FinancialPlanLockDate) + N''''
                  + N'   
				  AND dt.Stt IN
              (
                  SELECT Stt FROM #AccDoc
              )
				  ';

            EXECUTE sys.sp_executesql @_StrExec
                                    , N'@_Count_Record INT  OUTPUT	'
                                    , @_Count_Record OUTPUT;

            -- Kiểm tra => nếu dữ liệu trong thời gian khóa => thì dừng lại
            IF
            (
                SELECT @_Count_Record
            ) <> 0
            BEGIN
                DECLARE @_ErrGroupMsg NVARCHAR(128)
                    = N'Dữ liệu đã khóa sổ! Kiểm tra lại dữ liệu "Quản lý năm làm việc và khóa dữ liệu", trường "Khóa dữ liệu KHTC".';
                RAISERROR(@_ErrGroupMsg, 16, 1);
                RETURN;
            END;
 
        END;

        SELECT @_StrExec
            = '
	 SELECT dt.*,acc.DocNo,ISNULL(dt.Description, Ct.Description) AS Description0,CT.CurrencyCode
        FROM ' + @_DetailName + ' dt 
			  LEFT JOIN #AccDoc ACC on DT.Stt = Acc.Stt
			  INNER JOIN ' + @_DocName
              + ' CT ON   DT.Stt = CT.Stt 
        WHERE dt.Stt IN
              (
                  SELECT Stt FROM #AccDoc
              )';
        EXEC (@_StrExec);




        SELECT @_EntityAssetName = REPLACE(@_EntityAssetName, 'B30', 'B3' + @_DataCode);
        SELECT @_StrExec
            = '
	 SELECT EntityAsset.*,ISNULL(EntityAsset.Description, DT.Description) AS Description,DT.Id as _ParentIdentityKey,acc.DocNo,us.UserName as CreatedName,MODI.UserName as ModifiedName
        FROM ' + @_EntityAssetName
              + ' EntityAsset
			  LEFT JOIN #AccDoc ACC ON EntityAsset.Stt = ACC.Stt
			  INNER JOIN ' + @_DetailName
              + ' DT ON   EntityAsset.ParentRowId = DT.RowId  
                LEFT JOIN B00Userlist us on EntityAsset.CreatedBy = us.Id
                LEFT JOIN B00Userlist MODI on EntityAsset.ModifiedBy = MODI.Id
        WHERE dt.Stt IN
              (
                  SELECT Stt FROM #AccDoc
              ) AND EntityAsset.IsActive = 1
               ORDER BY EntityAsset.BuiltinOrder asc 
               ';
        EXEC (@_StrExec);

        DROP TABLE #AccDoc
                 , #IdList;

    END;
END;
GO
GO

SET DATEFORMAT DMY;
EXEC usp_B30AccDoc_GetDataInfo @_IdList = '<?xml version="1.0" standalone="yes"?>
<NewDataSet>
	<Ct Id="2841" />
</NewDataSet>'
                                  , @_BranchCode = 'T00'
                                  , @_LangId = 0
                                  , @_nUserId = 1213
                                  , @_FiscalYear = '2026'
                                  , @_ParentCommandKey = 'BN';