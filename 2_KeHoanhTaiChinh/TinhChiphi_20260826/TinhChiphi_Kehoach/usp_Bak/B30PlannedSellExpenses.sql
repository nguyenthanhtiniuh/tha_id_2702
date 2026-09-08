USE B10THACOIDACC_Data
GO

/****** Object:  Table [dbo].[B30PlannedSellExpenses]    Script Date: 2026-08-25 2:18:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
DROP TABLE IF EXISTS B30PlannedSellExpenses
CREATE TABLE dbo.B30PlannedSellExpenses
(
    Id INT IDENTITY(1, 1) NOT NULL
  , ParentId INT NOT NULL
  , IsGroup BIT NOT NULL
  , BranchCode CHAR(3) NOT NULL
  , FiscalYear dbo.CodeType NOT NULL
  , DocDate DATE NOT NULL
  , DocNo NVARCHAR(64) NOT NULL
  , ItemId INT NULL
  , ProductId INT NULL
  , Quantity dbo.QuantityType NOT NULL
  , Amount dbo.MoneyType NOT NULL
  , VariableAmount dbo.MoneyType NOT NULL
  , FixedAmount dbo.MoneyType NOT NULL
  , IsActive BIT NOT NULL
  , CreatedBy INT NOT NULL
  , CreatedAt SMALLDATETIME NULL
  , ModifiedBy INT NOT NULL
  , ModifiedAt SMALLDATETIME NOT NULL
  , timestamp TIMESTAMP NOT NULL
  , TypeCOGS VARCHAR(24) NULL
  , CONSTRAINT PK_B30PlannedSellExpenses
        PRIMARY KEY NONCLUSTERED (Id ASC)
        WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON
            , ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF
             ) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_ParentId
    DEFAULT ((-1)) FOR ParentId
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_IsGroup
    DEFAULT ((0)) FOR IsGroup
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_FiscalYear
    DEFAULT ('') FOR FiscalYear
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_DocDate
    DEFAULT ('') FOR DocDate
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_DocNo
    DEFAULT ('') FOR DocNo
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_Amount1
    DEFAULT ((0)) FOR Quantity
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_Amount
    DEFAULT ((0)) FOR Amount
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_DirectAmount
    DEFAULT ((0)) FOR VariableAmount
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_IndirectAmount
    DEFAULT ((0)) FOR FixedAmount
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_IsActive
    DEFAULT ((1)) FOR IsActive
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_CreatedBy
    DEFAULT ((-1)) FOR CreatedBy
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_CreatedAt
    DEFAULT (GETUTCDATE()) FOR CreatedAt
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_ModifiedBy
    DEFAULT ((-1)) FOR ModifiedBy
GO

ALTER TABLE dbo.B30PlannedSellExpenses
ADD CONSTRAINT DF_B30PlannedSellExpenses_ModifiedAt
    DEFAULT (GETUTCDATE()) FOR ModifiedAt
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Id nhóm mẹ'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'ParentId'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Xác định bản ghi có phải nhóm hay không: 1 - Là nhóm, 0 - Không phải nhóm'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'IsGroup'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Đơn vị cơ sở'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'BranchCode'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Năm tài chính phát sinh'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'FiscalYear'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Ngày tính giá thành'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'DocDate'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Số chứng từ'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'DocNo'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Id Vật tư, hàng hóa'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'ItemId'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Mã sản phẩm'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'ProductId'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Số lượng kế hoạch'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'Quantity'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Giá thành sản phẩm'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'Amount'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Giá vốn kế hoạch - Biến phí'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'VariableAmount'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Giá vốn kế hoạch - Định phí'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'FixedAmount'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Trạng thái bản ghi: 0 - Đình chỉ, 1 - Hoạt động'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'IsActive'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Tạo bởi'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'CreatedBy'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Thời gian tạo (UTC)'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'CreatedAt'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Sửa đổi bởi'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'ModifiedBy'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Thời gian sửa đổi (UTC)'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'ModifiedAt'
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Xác định thời gian thay đổi dữ liệu cuối cùng của bản ghi. Kiểm tra việc ghi đè dữ liệu'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
                              , @level2type = N'COLUMN'
                              , @level2name = N'timestamp'
GO

EXEC sys.sp_addextendedproperty @name = N'TableDesc'
                              , @value = N'Giá thành sản phẩm'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'dbo'
                              , @level1type = N'TABLE'
                              , @level1name = N'B30PlannedSellExpenses'
GO


