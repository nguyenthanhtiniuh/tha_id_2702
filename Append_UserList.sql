USE B10THACOIDACC
GO

/****** Object:  Table [dbo].[B00UserList]    Script Date: 2026-07-31 11:48:37 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

truncate table TblUserList
--insert into TblUserList 

drop table #TblUserList3107
select * into #TblUserList3107 from B10THACOID.dbo.B00UserList

 
SET IDENTITY_INSERT dbo.[B00UserList] ON;

exec usp_sys_Append_By_Id
@_TableSource = '#TblUserList3107'
,@_TableDestination='B00UserList'

SET IDENTITY_INSERT dbo.[B00UserList] Off ;

select * from B00UserList

 

drop table [B00UserList]
 

CREATE TABLE [dbo].[B00UserList](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ParentId] [int] NOT NULL,
	[IsGroup] [bit] NOT NULL,
	[UserName] [varchar](48) NOT NULL,
	[FullName] [nvarchar](256) NULL,
	[Ma_CbNv] [dbo].[CodeType] NOT NULL,
	[Checksum] [varbinary](20) NULL,
	[ChecksumDate] [datetime] NOT NULL,
	[Expire] [tinyint] NOT NULL,
	[MD5Hash] [varbinary](20) NULL,
	[BranchCode] [varchar](3) NULL,
	[CostCentreCode] [dbo].[CodeType] NOT NULL,
	[UsingLockDate] [tinyint] NOT NULL,
	[LockDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedAt] [smalldatetime] NULL,
	[ModifiedBy] [int] NOT NULL,
	[ModifiedAt] [smalldatetime] NOT NULL,
	[timestamp] [timestamp] NOT NULL,
	[EmployeeId] [int] NULL,
	[CustomerId] [int] NULL,
	[CostCentreId] [int] NULL,
	[LastLoginAt] [smalldatetime] NULL,
	[Is2FA] [bit] NOT NULL,
	[SecretCode2FA] [varchar](100) NULL,
	[Platform] [int] NOT NULL,
	[Mobile] [nvarchar](48) NOT NULL,
	[Email] [nvarchar](48) NOT NULL,
	[Login2FAType] [int] NOT NULL,
	[LastLogin2FAType] [int] NOT NULL,
	[FileName] [nvarchar](512) NULL,
	[UserType] [tinyint] NOT NULL,
	[PortalId] [int] NOT NULL,
	[UserId_Old] [int] NULL,
	[CheckKTT] [tinyint] NOT NULL,
	[ShowAllCus] [bit] NOT NULL,
	[ProfitCenterId] [int] NULL,
	[RouteCode] [dbo].[CodeType] NOT NULL,
	[RouteCodeListView] [varchar](1000) NULL,
	[RouteCodeList] [varchar](2000) NOT NULL,
	[DizCodeList] [varchar](24) NOT NULL,
	[RegionCode] [varchar](1000) NULL,
	[ManageCode] [varchar](1000) NULL,
	[SalesTargetCode] [varchar](1000) NULL,
	[IsAllowLSCS] [tinyint] NOT NULL,
	[ConfigTargetCodeDT] [varchar](1000) NOT NULL,
	[ConfigTargetCodeCP] [varchar](1000) NOT NULL,
	[ShowAllTargetCodeCP] [bit] NOT NULL,
	[ListTargetCodeCP] [varchar](1000) NOT NULL,
	[BranchList] [varchar](384) NULL,
	[IsAdmin] [tinyint] NOT NULL,
	[IsPurchase] [tinyint] NOT NULL,
	[DocList] [varchar](384) NULL,
	[EmployeeCodeB7] [varchar](384) NULL,
	[ParentUserId] [int] NULL,
	[UserDocProcessRoleId] [int] NULL,
	[ParentUserId2] [int] NULL,
	[Signature] [varbinary](max) NULL,
	[PurchaseDeptId] [varchar](384) NULL,
	[DeptCodeB7] [varchar](384) NULL,
	[AdminPurchase] [int] NOT NULL,
	[BranchNewList] [varchar](max) NULL,
	[BranchOldList] [varchar](max) NULL,
	[ProductClass] [varchar](24) NOT NULL,
	[AdminApproved] [tinyint] NOT NULL,
	[AdminZ] [tinyint] NOT NULL,
 CONSTRAINT [PK_B00UserList] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_B00UserList_UserName] UNIQUE NONCLUSTERED 
(
	[UserName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_ParentId]  DEFAULT ((1)) FOR [ParentId]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_IsGroup]  DEFAULT ((0)) FOR [IsGroup]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_FullName]  DEFAULT ('') FOR [FullName]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_Ma_CbNv]  DEFAULT ('') FOR [Ma_CbNv]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_ChecksumDate]  DEFAULT (getutcdate()) FOR [ChecksumDate]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_Expire]  DEFAULT ((0)) FOR [Expire]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_CostCentreCode]  DEFAULT ('') FOR [CostCentreCode]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_UsingLockDate]  DEFAULT ((0)) FOR [UsingLockDate]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_CreatedBy]  DEFAULT ((-1)) FOR [CreatedBy]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_CreatedAt]  DEFAULT (getutcdate()) FOR [CreatedAt]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_ModifiedBy]  DEFAULT ((-1)) FOR [ModifiedBy]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_ModifiedAt]  DEFAULT (getutcdate()) FOR [ModifiedAt]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_Is2FA]  DEFAULT ((0)) FOR [Is2FA]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_Platform]  DEFAULT ((7)) FOR [Platform]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_Mobile]  DEFAULT ('') FOR [Mobile]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_Email]  DEFAULT ('') FOR [Email]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_Login2FAType]  DEFAULT ((0)) FOR [Login2FAType]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_LastLogin2FAType]  DEFAULT ((0)) FOR [LastLogin2FAType]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_FileName]  DEFAULT ('') FOR [FileName]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_UserType]  DEFAULT ((0)) FOR [UserType]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_PortalId]  DEFAULT ((0)) FOR [PortalId]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_CheckKTT]  DEFAULT ((0)) FOR [CheckKTT]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF__B00UserLi__ShowA__07D0726F]  DEFAULT ((0)) FOR [ShowAllCus]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_RouteCode]  DEFAULT ('') FOR [RouteCode]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_RouteCodeList]  DEFAULT ('') FOR [RouteCodeList]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_DizCodeList]  DEFAULT ('') FOR [DizCodeList]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF__B00UserLi__IsAll__61FFCF42]  DEFAULT ((0)) FOR [IsAllowLSCS]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_ConfigTargetCodeDT]  DEFAULT ('') FOR [ConfigTargetCodeDT]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_ConfigTargetCodeCP]  DEFAULT ('') FOR [ConfigTargetCodeCP]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_ShowAllTargetCode]  DEFAULT ((0)) FOR [ShowAllTargetCodeCP]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_ExpenseTargetCode]  DEFAULT ('') FOR [ListTargetCodeCP]
GO

ALTER TABLE [dbo].[B00UserList] ADD  DEFAULT ((0)) FOR [IsAdmin]
GO

ALTER TABLE [dbo].[B00UserList] ADD  DEFAULT ((0)) FOR [IsPurchase]
GO

ALTER TABLE [dbo].[B00UserList] ADD  DEFAULT ((0)) FOR [ParentUserId]
GO

ALTER TABLE [dbo].[B00UserList] ADD  DEFAULT ((0)) FOR [UserDocProcessRoleId]
GO

ALTER TABLE [dbo].[B00UserList] ADD  DEFAULT ((0)) FOR [ParentUserId2]
GO

ALTER TABLE [dbo].[B00UserList] ADD  DEFAULT ((0)) FOR [AdminPurchase]
GO

ALTER TABLE [dbo].[B00UserList] ADD  DEFAULT ('') FOR [ProductClass]
GO

ALTER TABLE [dbo].[B00UserList] ADD  DEFAULT ((0)) FOR [AdminApproved]
GO

ALTER TABLE [dbo].[B00UserList] ADD  CONSTRAINT [DF_B00UserList_IsAdmin1]  DEFAULT ((0)) FOR [AdminZ]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Id nhóm mẹ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'ParentId'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Xác định bản ghi có phải nhóm hay không: 1 - Là nhóm, 0 - Không phải nhóm' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'IsGroup'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'User đăng nhập vào chương trình, để dạng Unique Key là duy nhất' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'UserName'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tên đầy đủ của người sử dụng' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'FullName'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Mã trong danh mục nhân viên' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'Ma_CbNv'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Mã hóa mật khẩu user' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'Checksum'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Ngày tạo mật khẩu user' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'ChecksumDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Hạn sử dụng của user' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'Expire'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Thuật toán mã hóa mật khẩu' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'MD5Hash'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Đơn vị cơ sở' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'BranchCode'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Mã trung tâm chi phí' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'CostCentreCode'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Sử dụng khóa số liệu theo người sử dụng' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'UsingLockDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Ngày khóa dữ liệu của người sử dụng' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'LockDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Trạng thái bản ghi: 0 - Đình chỉ, 1 - Hoạt động' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'IsActive'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tạo bởi' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'CreatedBy'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Thời gian tạo (UTC)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'CreatedAt'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Sửa đổi bởi' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'ModifiedBy'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Thời gian sửa đổi (UTC)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'ModifiedAt'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Xác định thời gian thay đổi dữ liệu cuối cùng của bản ghi. Kiểm tra việc ghi đè dữ liệu' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'timestamp'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Id nhân viên' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'EmployeeId'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Mật mã verify OTP' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'SecretCode2FA'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Dạng Flag: None = 0, AuthenticatorApp = 1, Email = 2, Sms = 4' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'Login2FAType'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'None = 0, AuthenticatorApp = 1, Email = 2, Sms = 4' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'LastLogin2FAType'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'User Bravo = 0, User Portal = 1' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'UserType'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Id bảng B00WebPortalConfig' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList', @level2type=N'COLUMN',@level2name=N'PortalId'
GO

EXEC sys.sp_addextendedproperty @name=N'TableDesc', @value=N'Khai báo User truy cập vào phần mềm' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'B00UserList'
GO


