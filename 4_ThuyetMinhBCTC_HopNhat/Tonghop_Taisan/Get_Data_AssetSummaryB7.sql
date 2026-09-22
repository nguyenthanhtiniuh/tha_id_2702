DECLARE @_lst_branch_B7 NVARCHAR(MAX) = ''
DECLARE @_branch_B7 NVARCHAR(3) = ''


DECLARE @_DocDate DATE
DECLARE @_DocDate1 DATE
DECLARE @_DocDate2 DATE

---
-- => Nhập mã đơn vị
--SELECT * FROM b20dmsroute
SELECT @_lst_branch_B7 = 'A46,A70,A74,B13,B27,B73'

SELECT @_lst_branch_B7 = 'A46'



--
-- => Nhập tháng muốn lấy dữ liệu
SELECT @_DocDate = '20260601'

---
SELECT @_DocDate2 = EOMONTH(@_DocDate)
SELECT @_DocDate1 = DATEFROMPARTS(YEAR(@_DocDate2), MONTH(@_DocDate2), '01')
---

DROP TABLE IF EXISTS #T_Dvcs_B7
SELECT value AS BranchCode
INTO #T_Dvcs_B7
FROM STRING_SPLIT(@_lst_branch_B7, ',')

WHILE EXISTS (SELECT * FROM #T_Dvcs_B7)
BEGIN

    SELECT TOP 1
           @_branch_B7 = BranchCode
    FROM #T_Dvcs_B7
    ORDER BY BranchCode ASC

    DELETE B40AssetSummary
    WHERE BranchCode = @_branch_B7
          AND
          (
              DocDate1 = @_DocDate1
              AND DocDate2 = @_DocDate2
          )

    INSERT INTO B40AssetSummary
    EXEC TO101_B7ACC.B7_THACO.dbo.usp_Tth_AssetSummaryTable_inherit @_DocDate1 = @_DocDate1
                                                                  , @_DocDate2 = @_DocDate2
                                                                  , @_LangId = 0
                                                                  , @_BranchCode = @_branch_B7

    DELETE #T_Dvcs_B7
    WHERE BranchCode = @_branch_B7
END

