-- Kiểm tra mối liên hệ ngày bắt đầu sử dụng, ngày bắt đầu khấu hao, ngày kết thúc khấu hao,...  
-- 16/07/2012 ThắngĐQ: Thêm điều kiện bắt ngày chờ thanh lý so sánh với ngày bắt đầu khấu hao  
CREATE OR ALTER PROC dbo.usp_B20Asset_Check_Dates
    @_FirstUsedDate AS DATE = NULL,
    @_SuspendDate AS DATE = NULL,
    @_FirstDeprDate AS DATE = NULL,
    @_LastDeprDate AS DATE = NULL,
    @_DecreaseDate AS DATE = NULL,
    @_StandbyForDisposal AS DATE = NULL,
    @_IncreaseDate AS DATE = NULL,
    @_CheckType TINYINT = NULL
AS
--RETURNS TINYINT AS  
BEGIN
    DECLARE @_RetVal TINYINT = 0,
            @_Message NVARCHAR(MAX) = ''

    -- Check số đầu và cuối  
    IF ISNULL(@_CheckType, 0) = 1
    BEGIN

        IF ISNULL(@_FirstUsedDate, '') <> ''
           AND ISNULL(@_SuspendDate, '') <> ''
           AND @_FirstUsedDate > @_SuspendDate
        BEGIN
            SELECT @_RetVal = 1,
                   @_Message = N'-- Ngày 1 luôn nhỏ hơn ngày 2: Đ '
        END
        BEGIN
            SELECT @_RetVal = 0
        END
    END

    -- Ngày bắt đầu khấu hao phải khác rỗng  
    IF ISNULL(@_FirstDeprDate, '') = ''
        SELECT @_RetVal = 0,
               @_Message = @_Message + N'-- Ngày bắt đầu khấu hao phải khác rỗng'

    IF ISNULL(@_FirstUsedDate, '') <> ''
       AND @_FirstUsedDate < @_FirstDeprDate
        SELECT @_RetVal = 1,
               @_Message = @_Message + N'-- Ngày bắt đầu sử dụng phải sau ngày bắt đầu khấu hao  '
 
    IF ISNULL(@_IncreaseDate, '') <> ''
       AND @_FirstDeprDate > @_IncreaseDate
        SELECT @_RetVal = 1,
               @_Message = @_Message + N'-- Ngày bắt đầu khấu hao phải nhỏ hơn ngày tăng'
 
    IF ISNULL(@_StandbyForDisposal, '') <> ''
       AND ISNULL(@_FirstUsedDate, '') <> ''
       AND @_FirstUsedDate > @_StandbyForDisposal
        SELECT @_RetVal = 1,
               @_Message = @_Message + N'-- Ngày bắt đầu sử dụng phải nhỏ hơn ngày chờ thanh lý  '

    -- 16/07/2012 ThắngĐQ: Thêm điều kiện bắt ngày chờ thanh lý so sánh với ngày bắt đầu khấu hao  

    IF ISNULL(@_StandbyForDisposal, '') <> ''
       AND ISNULL(@_FirstDeprDate, '') <> ''
       AND @_FirstDeprDate > @_StandbyForDisposal
        SELECT @_RetVal = 1,
               @_Message = @_Message + N'-- Ngày bắt đầu khấu hao phải nhỏ hơn ngày chờ thanh lý  '


    IF ISNULL(@_FirstDeprDate, '') <> ''
       AND ISNULL(@_LastDeprDate, '') <> ''
       AND @_FirstDeprDate > @_LastDeprDate
        SELECT @_RetVal = 1,
               @_Message = @_Message + N'-- Ngày bắt đầu khấu hao phải nhỏ hơn ngày kết thúc khấu hao  '


    IF ISNULL(@_DecreaseDate, '') <> ''
       AND ISNULL(@_FirstUsedDate, '') <> ''
       AND @_FirstUsedDate > @_DecreaseDate
        SELECT @_RetVal = 1,
               @_Message = @_Message + N'-- Ngày bắt đầu sử dụng phải nhỏ hơn ngày giảm tài sản    '

    SELECT @_RetVal
    PRINT @_Message
END
GO

SET DATEFORMAT DMY

EXEC usp_B20Asset_Check_Dates @_FirstUsedDate = '01/08/2026 00:00:00.000',
                              @_SuspendDate = NULL,
                              @_FirstDeprDate = '01/08/2026 00:00:00.000',
                              @_LastDeprDate = NULL,
                              @_DecreaseDate = NULL,
                              @_StandbyForDisposal = NULL,
                              @_IncreaseDate = '31/07/2026 00:00:00.000',
                              @_CheckType = NULL