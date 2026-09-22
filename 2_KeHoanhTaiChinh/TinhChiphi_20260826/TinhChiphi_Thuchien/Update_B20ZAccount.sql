--Cap nhat Step cho bang B20ZAccount

DROP TABLE IF EXISTS #tableName;

CREATE TABLE #tableName
(
    Code VARCHAR(512)
  , Name VARCHAR(512)
  , Step INT
  , BranchCode VARCHAR(512)
  , Id INT
);

INSERT INTO #tableName
(
    Code
  , Name
  , Step
  , BranchCode
)
VALUES
('CDC', 'Công đoạn chung', '1', 'I01')
, ('I02-LRA', 'Lắp ráp thùng', '5', 'I02')
, ('I02-KXM', 'Hàn khung xe máy', '3', 'I02')
, ('I02-HOD', 'Hàn LKCK ô tô - DD', '4', 'I02')
, ('CDC', 'Công đoạn chung', '1', 'I02')
, ('I04-LRA', 'Lắp ráp trong nước', '10', 'I04')
, ('I04-NEM', 'Sản xuất nệm trong nước', '9', 'I04')
, ('I04-MAY', 'May trong nước', '8', 'I04')
, ('I04-LRA1', 'Lắp ráp xuất khẩu', '7', 'I04')
, ('I04-CAT', 'Cắt trong nước', '6', 'I04')
, ('I04-MAY1', 'May xuất khẩu', '5', 'I04')
, ('I04-MAY2', 'May túi khí xuất khẩu', '4', 'I04')
, ('I04-CAT1', 'Cắt xuất khẩu', '3', 'I04')
, ('I04-CAT2', 'Cắt túi khí xuất khẩu', '2', 'I04')
, ('CDC', 'Công đoạn chung', '1', 'I04')
, ('I08-LRA', 'Lắp ráp', '3', 'I08')
, ('I08-CBA', 'Cắt bấm', '2', 'I08')
, ('CDC', 'Công đoạn chung', '1', 'I08')
, ('CDC', 'Công đoạn chung', '1', 'I09')
, ('I09-NLS_CASC', 'Nhiệt luyện và Sơn', '3', 'I09')
, ('I09-LRA_CASC', 'Lắp ráp', '4', 'I09')
, ('I09-TPH_CASC', 'Tạo phôi', '2', 'I09')
, ('CDC', 'Công đoạn chung', '1', 'I10')
, ('I10-LRA1', 'CTSV - Lắp ráp SMRM', '2', 'I10')
, ('I10-DDK', 'CTSV - Đóng kiện', '3', 'I10')
, ('I10-KCL', 'CTSV - Kiểm định', '4', 'I10')
, ('CDC', 'Công đoạn chung', '1', 'I11')
, ('I11-GCK', 'Gia công khuôn', '2', 'I11')
, ('I11-DHI', 'Định hình', '4', 'I11')
, ('I11-LRA', 'Lắp ráp', '6', 'I11')
, ('I11-HTH', 'Hoàn thiện', '5', 'I11')
, ('I11-SON', 'Sơn', '7', 'I11')
, ('I11-DBD', 'Đùn', '3', 'I11')
, ('I14-GHA', 'Giao hàng', '4', 'I14')
, ('I14-DHK', 'Sản xuất dàn nóng', '2', 'I14')
, ('I14-DHG', 'Sản xuất ống gas', '3', 'I14')
, ('CDC', 'Công đoạn chung', '1', 'I14')
, ('CDC', 'Công đoạn chung', '1', 'I15')
, ('I15-LRA_TPC', 'Lắp ráp', '4', 'I15')
, ('I15-SON_TPC', 'Sơn', '3', 'I15')
, ('I15-DHI_TPC', 'Định hình', '2', 'I15')
, ('I17-SXD', 'Sản xuất dung dịch', '2', 'I17')
, ('I17-SXK', 'Sản xuất keo', '3', 'I17')
, ('CDC', 'Công đoạn chung', '1', 'I17')
, ('CDC', 'Công đoạn chung', '1', 'I19')
, ('CDC', 'Công đoạn chung', '1', 'I20')
, ('CDC', 'Công đoạn chung', '1', 'I21')
, ('CDC', 'Công đoạn chung', '1', 'I22')
, ('CDC', 'Công đoạn chung', '1', 'I23')
, ('I24-SX0', 'Sản xuất', '2', 'I24')
, ('CDC', 'Công đoạn chung', '1', 'I24')
, ('I25-GTP', 'Gia công tạo phôi', '2', 'I25')
, ('I25-GNH1_TAG', 'In và gia công nhiệt (Du lịch)', '3', 'I25')
, ('CDC', 'Công đoạn chung', '1', 'I25')
, ('I25-GPK', 'Lắp phụ kiện (Tải - Bus)', '6', 'I25')
, ('I25-GNH', 'In và gia công nhiệt (Tải - Bus)', '5', 'I25')
, ('I25-GPK1', 'Lắp phụ kiện (Du lịch)', '4', 'I25')
, ('I26-LRA', 'Lắp ráp', '3', 'I26')
, ('I26-GMI', 'Gấp mí', '4', 'I26')
, ('I26-DHI', 'Định hình', '2', 'I26')
, ('CDC', 'Công đoạn chung', '1', 'I26')
, ('CDC', 'Công đoạn chung', '1', 'I27')
, ('I27-CBA', 'Cắt bấm', '2', 'I27')
, ('I27-LRA', 'Lắp ráp', '3', 'I27')
, ('I29-CAT', 'Cắt biên dạng', '4', 'I29')
, ('I29-DHI', 'Ép biên dạng', '3', 'I29')
, ('I29-CBI', 'Gia công', '2', 'I29')
, ('I29-LRA', 'Lắp ráp', '5', 'I29')
, ('CDC', 'Công đoạn chung', '1', 'I29');


DROP TABLE IF EXISTS #zacc
SELECT Id
     , StageCode
     , StageId
     , BranchCode
INTO #zacc
FROM vB20ZAccount
WHERE StageCode IN
      (
          SELECT Code FROM #tableName
      )
ORDER BY BranchCode ASC

UPDATE #tableName
SET Id = acc.Id
FROM #tableName      AS t
    INNER JOIN #zacc AS acc
        ON t.BranchCode = acc.BranchCode
		AND acc. StageCode =t.Code
--SELECT * FROM #tableName
------------------
UPDATE zacc
SET step = tab.Step
FROM B20ZAccount          AS zacc
    INNER JOIN #tableName AS tab
        ON zacc.Id = tab.Id
WHERE zacc.id IN
      (
          SELECT Id FROM #tableName
      )

------------------
SELECT *
FROM B20ZAccount
WHERE id IN
      (
          SELECT Id FROM #tableName
      )


DROP TABLE IF EXISTS #tableName
DROP TABLE IF EXISTS #zacc