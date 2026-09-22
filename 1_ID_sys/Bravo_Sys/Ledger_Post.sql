/*
B00LedgerConfig: Khai báo 2 loại định nghĩa tham số post sổ: post sổ cái, và post thẻ kho
*/
SELECT *
FROM B00LedgerConfig
WHERE id = 1


/*
B00LedgerConfigColumn: Danh sách các cột khi tạo view, thống nhất tên cột, thứ tự cột khi tạo view
*/
SELECT * FROM B00LedgerConfigColumn WHERE LedgerId = 1 ORDER BY ModifiedAt DESC

/*
B00LedgerConfigView: Danh sách các view theo nghiệp vụ để post sổ cái hoặc thẻ kho.
Chú ý riêng view vB30GeneralLedger_Other (Hạch toán bù trừ xử lý insert thẳng vào từ view vào
bảng sổ cái, cấu trúc khác với các view còn lại nên không cần khai báo ở đây).
*/
SELECT * FROM B00LedgerConfigView WHERE LedgerId = 1 ORDER BY ModifiedAt DESC

/*
B00LedgerConfigViewTable: Danh sách các bảng (table) để tạo cấu trúc view
Là bảng con của B00LedgerConfigView, liên kết theo:
B00LedgerConfigView: Id  B00LedgerConfigViewTable: ConfigViewId
*/

SELECT * FROM B00LedgerConfigViewTable WHERE  ConfigViewId IN (21,22)

/*
B00LedgerConfigViewColumn: Danh sách các cột để tạo cấu trúc view
Là bảng con của B00LedgerConfigView, liên kết theo:
B00LedgerConfigView: Id  B00LedgerConfigViewColumn: ConfigViewId
*/

SELECT * FROM B00LedgerConfigViewColumn WHERE  ConfigViewId IN (21,22)

SELECT * FROM B00LedgerConfigPost
/*
B00LedgerConfigPost: Cấu hình post sổ cái và thẻ kho
Khai báo danh sách cột làm cơ sở xử lý cập nhật từ view vào bảng Sổ cái, Thẻ kho, hỗ trợ kỹ thuật
cho việc khi thêm cột vào bảng sổ cái, thẻ kho, view post liên quan chỉ khai báo thêm cột và không
cần phải sửa vào thủ tục usp_B30AccDoc_Post, usp_B30AccDoc_PostAfterSave
*/


/*
Sửa 2 thủ tục usp_B30AccDoc_Post, usp_B30AccDoc_PostAfterSave để xử lý post sổ
Command:
SYSLedgerConfig: Cấu hình tạo view, post sổ cái, thẻ kho (Explore)
EDIT_SYSLedgerConfig: Cập nhật cấu hình tạo view, post sổ cái, thẻ kho (Editor)
Khi thêm mới 1 cột thứ tự làm ghi nhận như sau:
Bước 1: Thêm cấu trúc cột vào Sổ cái (B30GeneralLedger), Thẻ kho (B30StockLedger)
Bước 2: Xác định cấu trúc thêm mới cho cấu hình Sổ cái hay Thẻ kho (Có thể cả 2 và làm lần lượt,
các làm sẽ giống nhau)

Bước 3: Trên màn hình cấu hình chọn khai báo
Chọn Page dữ liệu “Cấu hình tạo view (Sổ cái, thẻ kho)
Chọn mục “3. Danh sách view” và vào từng mục tên view để thêm cột cho từng view.
Trong mục này có 2 phần (xem phần chi tiết các bảng để biết ý nghĩa tạo)
Chi tiết bảng tạo view (B00LedgerConfigViewTable)
Chi tiết các cột tạo view ((B00LedgerConfigViewColumn): Chủ yếu khai báo thêm 1 dòng ở
mục này tương ứng với từng nhóm nghiệp vụ.
Chọn mục “4. Danh sách các cột view”: xem lại ý nghĩa bảng (B00LedgerConfigColumn) để thêm 1
cột tương ứng của view
Khi xử lý xong bước này, chương trình sẽ căn cứ tạo lại các view Sổ cái thẻ kho.

Bước 4: Chọn Page dữ liệu “Cấu hình xử lý Post Sổ cái, thẻ kho
Đây là bước khai báo để xử lý cho thủ tục AccDocPost, chú ý mục này chỉ dành cho post sổ cái.
Thêm 1 cột trong dữ liệu này và khai báo theo mô tả cột của bảng B00LedgerConfigPost.

Một số chú ý:
Bảng B00LedgerConfig: Chỉ có 2 dòng, không cho sửa đổi với 1 dòng khai báo cho post sổ cái, 1
dòng khai báo cho thẻ kho.
Bắt buộc phải khai báo danh sách các cột trong TAB “Danh sách các cột của view” để post lấy dữ liệu
theo danh sách này.
Bắt buộc phải khai báo tab “Cấu hình xử lý Post Sổ cái, thẻ kho” khi thêm cột mới do Post lấy cấu trúc
ở đây để tạo bảng #_PostEntry
Trong khai báo cấu hình Post:
Kiểu của cột mục đích chỉ để tạo cấu trúc bảng temp #_PostEntries (trong thủ tục
AccDocPost)
Giá trị mặc định: Dùng để tránh việc insert giá trị Null vào bảng Sổ cái
1 Cột có thể vừa là cột trong bảng sổ cái và bảng temp #_PostEntries hoặc thuộc 1 trong 2
bảng.
Căn cứ vào khai báo thủ tục AccDocPost cho Sổ cái, Thẻ kho theo các bước:
Tạo bảng temp #_PostEntries từ bảng B00LedgerConfigPost_Entries
Chèn dữ liệu từ view sổ cái vào bảng #_PostEntries
Cập nhật thêm giá trị một số cột cho bảng #_PostEntries theo dõi: Đối tượng, Sản phẩm,
Ngoại tệ, Ngân hàng (xử lý cấu trúc trong thủ tục)

Cập nhật, update từ bảng tem (#_PostEntries) vào Sổ cái, Thẻ kho
Đối với post chứng từ Bù trừ, Thẻ kho: Truy suất thẳng từ view (không qua bảng temp)
Command: SYSLedgerConfig mặc định không đưa ra màn hình chính, khi sử dụng cần kéo khai báo
thêm.
Để tự động tạo các view cần chạy thủ tục usp_B00LedgerConfig_General sau khi khai báo (tham số
@_LedgerId = 1 (Sổ cái), @_LedgerId = 2 (Thẻ kho).
Có thể tạo view thủ công bằng câu lệnh được hiển thị tại màn hình explore (SYSLedgerConfig)
*/