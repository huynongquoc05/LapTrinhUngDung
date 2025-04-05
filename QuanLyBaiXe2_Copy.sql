
Drop database QuanLyBaiXe2

/*
    MÔ TẢ CƠ SỞ DỮ LIỆU QUẢN LÝ DỊCH VỤ GỬI XE

    Cơ sở dữ liệu này được thiết kế để quản lý dịch vụ gửi xe ô tô và xe máy, hỗ trợ cả xe vé tháng và vé lượt, 
    với khả năng theo dõi trạng thái bãi xe và lịch sử giao dịch. Hệ thống gồm 5 bảng, 3 thủ tục, và 1 trigger.

    1. CHỨC NĂNG CÁC BẢNG:
    - MonthlySubscriptions: Lưu thông tin xe đăng ký trả tháng, bao gồm biển số (LicensePlate), loại xe (VehicleType), 
      thời gian đăng ký (StartDate, EndDate), phí tháng (MonthlyFee), trạng thái hoạt động (IsActive), và trạng thái 
      xe trong bãi (IsOut). Bảng này dùng để kiểm tra xe có thuộc diện vé tháng hay không.
    - FeeRates: Lưu giá phí cố định theo loại xe, gồm phí giờ (HourlyRate), phí tháng (MonthlyRate), và phí phạt mất vé 
      (LostTicketFee). Bảng này cung cấp dữ liệu để tính phí cho các giao dịch.
    - ParkingTickets: Lưu thông tin vé xe theo lượt, bao gồm mã vé (TicketCode), biển số (LicensePlate), loại xe (VehicleType), 
      giờ vào (EntryTime), phí gửi xe (Fee), trạng thái hiệu lực (IsValid), trạng thái mất vé (IsLost), phí phạt (LostFee), 
      trạng thái xe trong bãi (IsOut), và liên kết với bãi xe (LotID). Bảng này quản lý xe không đăng ký tháng.
    - ParkingLot: Quản lý thông tin bãi xe, gồm tên bãi (LotName), số slot tối đa (MaxSlots), và số slot trống hiện tại 
      (AvailableSlots). Bảng này theo dõi tình trạng chỗ trống trong bãi.
    - Transactions: Lưu lịch sử giao dịch, bao gồm biển số (LicensePlate), loại giao dịch (TransactionType: Monthly, Hourly, LostFee), 
      số tiền (Amount), thời gian giao dịch (TransactionDate), và liên kết với vé (TicketID) hoặc đăng ký tháng (SubscriptionID). 
      Bảng này dùng để theo dõi doanh thu và lịch sử hoạt động.

    2. LUỒNG NGHIỆP VỤ DỰA TRÊN CÁC THỦ TỤC:
    - sp_VehicleEntry: Xử lý xe vào bãi
      + Kiểm tra biển số trong MonthlySubscriptions:
        * Nếu là xe vé tháng còn hạn (IsActive = 1, EndDate >= GETDATE()):
          - Cập nhật IsOut = 0 (xe vào bãi).
          - Giảm AvailableSlots trong ParkingLot.
          - Ghi giao dịch Monthly với Amount = 0 vào Transactions.
        * Nếu không:
          - Tạo vé mới trong ParkingTickets với EntryTime, IsValid = 1, IsOut = 0.
          - Giảm AvailableSlots trong ParkingLot.
      + Nghiệp vụ chia theo 2 hướng xe vào và xe ra, có liên kết giữa nhiều bảng, cần dùng thủ tục phức tạp thay vì chèn chay từng bản.

    - sp_VehicleExit: Xử lý xe vé lượt ra khỏi bãi
      + Tìm vé trong ParkingTickets với TicketCode và IsValid = 1.
      + Tính phí gửi xe (Fee = HourlyRate * Số giờ) dựa trên EntryTime và giờ hiện tại.
      + Nếu IsLost = 1, cộng phí phạt (LostFee).
      + Cập nhật ParkingTickets: Fee, LostFee, IsValid = 0, IsOut = 1.
      + Tăng AvailableSlots trong ParkingLot.
      + Ghi giao dịch Hourly (và LostFee nếu có) vào Transactions.

    - sp_MonthlyVehicleExit: Xử lý xe vé tháng ra khỏi bãi
      + Tìm xe trong MonthlySubscriptions với LicensePlate, IsActive = 1, IsOut = 0.
      + Cập nhật IsOut = 1 (xe ra khỏi bãi).
      + Tăng AvailableSlots trong ParkingLot.
      + (Tùy chọn) Ghi giao dịch Monthly với Amount = 0 vào Transactions để theo dõi.

    3. TRIGGER:
    - tr_CheckParkingLot: Kích hoạt sau khi chèn bản ghi vào ParkingTickets, kiểm tra AvailableSlots trong ParkingLot không âm. 
      Nếu âm, hủy giao dịch và báo lỗi.

    4. TỔNG QUAN:
    Cơ sở dữ liệu này hỗ trợ quản lý xe vé tháng và vé lượt một cách linh hoạt, với khả năng theo dõi trạng thái bãi xe và lịch sử giao dịch. 
    Các thủ tục đảm bảo tính toàn vẹn dữ liệu và tự động hóa quy trình, trong khi trigger bảo vệ giới hạn bãi xe.
*/

/*
4 phần cơ sở dữ liệu
Phần 1 các bảng


Phần 2: các view - Dòng 189

vw_VehiclesInParkingLot - 194: Liệt kê các xe đang đỗ trong bãi, bao gồm cả vé tháng và vé lượt, chưa ra khỏi bãi.

vw_HourlyRevenueByMonth -223: Thống kê tổng doanh thu vé lượt theo tháng (phí gửi và phí mất vé).

vw_BaoCaoDoanhThuVeLuotChiTiet - 240 : Báo cáo chi tiết doanh thu vé lượt theo từng giao dịch và tổng hợp theo tháng.

vw_BaoCaoDangKyThang 302: Báo cáo chi tiết đăng ký vé tháng kèm dòng tổng doanh thu vé tháng.


Phần 3: các thủ tục và trigger

sp_VehicleEntry - 381 : Xử lý xe vào bãi dựa trên biển số, loại xe và bãi đỗ. Nếu xe có vé tháng hợp lệ, cập nhật trạng thái và giảm số lượng chỗ trống. 
Nếu không có vé tháng, kiểm tra chỗ trống, tạo vé gửi xe mới và giảm số lượng chỗ trống.

sp_VehicleExit - 482: Xử lý xe rời bãi, tính phí gửi xe dựa trên thời gian gửi và phí theo giờ. 
Cập nhật trạng thái vé và bãi đỗ, ghi nhận giao dịch cho cả phí gửi xe và phí mất vé (nếu có).

sp_MonthlyVehicleExit -577 : Xử lý xe có vé tháng rời bãi, cập nhật trạng thái vé và bãi đỗ, ghi nhận giao dịch vé tháng.

tr_CheckParkingLot 654 : Kiểm tra số lượng chỗ trống trong bãi xe sau khi thêm vé gửi xe, nếu bãi đầy thì hủy bỏ thao tác thêm vé.

sp_CalculateTotalRevenue - 678: Tính tổng doanh thu từ vé theo giờ và vé tháng, có thể lọc theo năm và tháng.

AddMonthlySubscription - 735 : Thủ tục đăng ký vé tháng




Phần 4:Thêm vài bản ghi
*/

create database QuanLyBaiXe2


use quanlybaixe2



----Phần 1: Các bảng dữ liệu
-----------------------------
-------------------------------------
--------------------------------------
CREATE TABLE MonthlySubscriptions (
    SubscriptionID INT PRIMARY KEY IDENTITY(1,1),
    LicensePlate NVARCHAR(20) NOT NULL, -- Biển số xe
    VehicleType NVARCHAR(10) NOT NULL CHECK (VehicleType IN ('Car', 'Motorcycle')), -- Loại xe
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    MonthlyFee DECIMAL(10, 2) NOT NULL,
    IsActive BIT DEFAULT 1, -- Còn hiệu lực không
    IsOut BIT DEFAULT 1 -- Xe đã ra khỏi bãi chưa (1: Đã ra, 0: Còn trong bãi)
);


INSERT INTO MonthlySubscriptions (LicensePlate, VehicleType, StartDate, EndDate, MonthlyFee, IsActive, IsOut)
VALUES 
    ('29A-12345', 'Car', '2025-04-01', '2025-04-30', 1000000, 1, 1), -- Xe ô tô trả tháng
    ('30F-67890', 'Motorcycle', '2025-04-01', '2025-04-30', 500000, 1, 1); -- Xe máy trả tháng

INSERT INTO MonthlySubscriptions (LicensePlate, VehicleType, StartDate, EndDate, MonthlyFee, IsActive, IsOut)
VALUES 
    ('29A-54321', 'Car', '2025-04-01', '2025-05-01', 1000000, 1, 1), -- Xe ô tô trả tháng
    ('30F-09876', 'Motorcycle', '2025-04-01', '2025-05-01', 500000, 1, 1); -- Xe máy trả tháng

select *from MonthlySubscriptions


CREATE TABLE ParkingLot (
    LotID INT PRIMARY KEY IDENTITY(1,1),
    LotName NVARCHAR(50) NOT NULL, -- Tên bãi xe
    MaxSlots INT NOT NULL, -- Số slot tối đa
    AvailableSlots INT NOT NULL, -- Số slot trống hiện tại
    CONSTRAINT CHK_Slots CHECK (AvailableSlots >= 0 AND AvailableSlots <= MaxSlots)
);
ALTER TABLE MonthlySubscriptions
ADD LotID INT NULL,
    FOREIGN KEY (LotID) REFERENCES ParkingLot(LotID);

INSERT INTO ParkingLot (LotName, MaxSlots, AvailableSlots)
VALUES 
    ('Bãi A', 50, 50), -- Bãi A: 50 chỗ, hiện trống hết
    ('Bãi B', 30, 30); -- Bãi B: 30 chỗ, hiện trống hết


CREATE TABLE ParkingTickets (--chỉ cấp cho xe vé lượt
    TicketID INT PRIMARY KEY IDENTITY(1,1),
    TicketCode NVARCHAR(20) UNIQUE NOT NULL, -- Mã vé
    LicensePlate NVARCHAR(20) NOT NULL, -- Biển số xe
    VehicleType NVARCHAR(10) NOT NULL CHECK (VehicleType IN ('Car', 'Motorcycle')), -- Loại xe
    EntryTime DATETIME NOT NULL, -- Giờ vào
    Fee DECIMAL(10, 2) NULL, -- Phí tính khi thanh toán
    IsValid BIT DEFAULT 1, -- Vé còn hiệu lực không (1: Còn, 0: Hết)
    IsLost BIT DEFAULT 0, -- Vé có mất không
    LostFee DECIMAL(10, 2) DEFAULT 0, -- Phí phạt mất vé
    IsOut BIT DEFAULT 0, -- Xe đã ra khỏi bãi chưa (0: Còn trong, 1: Đã ra)
    LotID INT NOT NULL, -- Liên kết với bãi xe
    FOREIGN KEY (LotID) REFERENCES ParkingLot(LotID)
);

CREATE TABLE FeeRates (
    FeeRateID INT PRIMARY KEY IDENTITY(1,1),
    VehicleType NVARCHAR(10) NOT NULL CHECK (VehicleType IN ('Car', 'Motorcycle')),
    HourlyRate DECIMAL(10, 2) NOT NULL, -- Phí theo giờ
    MonthlyRate DECIMAL(10, 2) NOT NULL, -- Phí trả tháng
    LostTicketFee DECIMAL(10, 2) NOT NULL -- Phí phạt mất vé
);

INSERT INTO FeeRates (VehicleType, HourlyRate, MonthlyRate, LostTicketFee)
VALUES 
    ('Car', 10000, 1000000, 50000), -- Ô tô: 10k/giờ, 1 triệu/tháng, phạt mất vé 50k
    ('Motorcycle', 2000, 500000, 30000); -- Xe máy: 2k/giờ, 500k/tháng, phạt mất vé 30k



CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    LicensePlate NVARCHAR(20) NOT NULL, -- Biển số xe (không cần VehicleID)
    TransactionType NVARCHAR(20) NOT NULL CHECK (TransactionType IN ('Monthly', 'Hourly', 'LostFee')),
    Amount DECIMAL(10, 2) NOT NULL,
    TransactionDate DATETIME NOT NULL,
    TicketID INT NULL, -- Liên kết với vé (nếu có)
    SubscriptionID INT NULL, -- Liên kết với đăng ký tháng (nếu có)
    FOREIGN KEY (TicketID) REFERENCES ParkingTickets(TicketID),
    FOREIGN KEY (SubscriptionID) REFERENCES MonthlySubscriptions(SubscriptionID)
);




-----Phần 2: các view
-----------------------------
-------------------------------------
--------------------------------------
---View này để kiểm tra xe nào đang đỗ trong các bãi
create VIEW vw_VehiclesInParkingLot
AS
SELECT 
    LicensePlate,
    VehicleType,
    'Monthly' AS TicketType, -- Phân loại vé tháng
    --NULL AS TicketCode,      -- Vé tháng không có TicketCode
    EntryTime = StartDate,   -- Dùng StartDate làm thời gian "vào" cho vé tháng (có thể thay đổi)
    LotID           -- Vé tháng không liên kết trực tiếp với ParkingLot trong thiết kế hiện tại
FROM MonthlySubscriptions
WHERE IsOut = 0 AND IsActive = 1 AND EndDate >= GETDATE()

UNION ALL

SELECT 
    LicensePlate,
    VehicleType,
    'Hourly' AS TicketType,  -- Phân loại vé lượt
    --TicketCode,
    EntryTime,
    LotID
FROM ParkingTickets
WHERE IsOut = 0 AND IsValid = 1;
-------
select*from vw_VehiclesInParkingLot



--Tổng doanh thu theo vẽ lượt
CREATE VIEW vw_HourlyRevenueByMonth
AS
SELECT 
    YEAR(TransactionDate) AS RevenueYear,
    MONTH(TransactionDate) AS RevenueMonth,
    SUM(CASE WHEN TransactionType = 'Hourly' THEN Amount ELSE 0 END) AS HourlyFee,
    SUM(CASE WHEN TransactionType = 'LostFee' THEN Amount ELSE 0 END) AS LostFee,
    SUM(Amount) AS TotalHourlyRevenue
FROM Transactions
WHERE TransactionType IN ('Hourly', 'LostFee')
GROUP BY YEAR(TransactionDate), MONTH(TransactionDate);
------

SELECT * FROM vw_HourlyRevenueByMonth
ORDER BY RevenueYear, RevenueMonth;


--báo cáo doanh thu chi tiết từ vé  lượt:
CREATE VIEW vw_BaoCaoDoanhThuVeLuotChiTiet
AS
WITH HourlyTransactions AS (
    -- Lấy chi tiết giao dịch vé lượt
    SELECT 
        TransactionID,
        LicensePlate,
        TransactionType,
        Amount,
        TransactionDate,
        TicketID,
        YEAR(TransactionDate) AS RevenueYear,
        MONTH(TransactionDate) AS RevenueMonth
    FROM Transactions
    WHERE TransactionType IN ('Hourly', 'LostFee')
),
TotalRevenue AS (
    -- Tính tổng doanh thu vé lượt
    SELECT 
        NULL AS TransactionID,
        NULL AS LicensePlate,
        'Total' AS TransactionType,
        SUM(Amount) AS Amount,
        NULL AS TransactionDate,
        NULL AS TicketID,
        RevenueYear,
        RevenueMonth
    FROM HourlyTransactions
    GROUP BY RevenueYear, RevenueMonth
)
-- Kết hợp chi tiết và tổng
SELECT 
    TransactionID,
    LicensePlate,
    TransactionType,
    Amount,
    TransactionDate,
    TicketID,
    RevenueYear,
    RevenueMonth
FROM HourlyTransactions
UNION ALL
SELECT 
    TransactionID,
    LicensePlate,
    TransactionType,
    Amount,
    TransactionDate,
    TicketID,
    RevenueYear,
    RevenueMonth
FROM TotalRevenue;
-------

SELECT * 
FROM vw_BaoCaoDoanhThuVeLuotChiTiet
WHERE RevenueMonth = 4 and RevenueYear=2015



---view Báo cáo đăng ký tháng:
create VIEW vw_BaoCaoDangKyThang 
AS
WITH SubscriptionDetails AS (
    SELECT 
        SubscriptionID,
        LicensePlate,
        VehicleType,
        StartDate,
        EndDate,
        MonthlyFee AS Fee  -- Đổi tên MonthlyFee thành Fee
    FROM MonthlySubscriptions
),
TotalSubscription AS (
    SELECT 
        NULL AS SubscriptionID,
        NULL AS LicensePlate,
        NULL AS VehicleType,
        NULL AS StartDate,
        NULL AS EndDate,
        SUM(Fee) AS Fee
    FROM SubscriptionDetails
)
SELECT 
    SubscriptionID,
    LicensePlate,
    VehicleType,
    StartDate,
    EndDate,
    Fee  -- Hiển thị cột Fee
FROM SubscriptionDetails

UNION ALL

SELECT 
    SubscriptionID,
    LicensePlate,
    VehicleType,
    StartDate,
    EndDate,
    Fee
FROM TotalSubscription;



--------------

SELECT * FROM vw_BaoCaoDangKyThang ;







------Phần 3: các thủ tục và trigger
-----------------------------
-------------------------------------
--------------------------------------
/*
    Thủ tục sp_VehicleEntry thực hiện quá trình xe vào bãi dựa trên thông tin biển số, loại xe và bãi đỗ.

    1. Kiểm tra xem xe có đăng ký vé tháng không:
       - Nếu có (vé tháng còn hiệu lực và chưa hết hạn):
         + Cập nhật trạng thái IsOut = 0 trong bảng MonthlySubscriptions để đánh dấu xe đang trong bãi.
         + Giảm số lượng chỗ trống trong bảng ParkingLot.
         + Ghi nhận giao dịch vào bảng Transactions với loại 'Monthly' và số tiền là 0.

    2. Nếu xe không có vé tháng:
       - Kiểm tra bãi xe còn chỗ không:
         + Nếu hết chỗ, trả lỗi 'Bãi xe đã hết chỗ!' và kết thúc thủ tục.
       - Nếu còn chỗ:
         + Tạo vé gửi xe mới trong bảng ParkingTickets với mã vé dạng 'TICKET-yyyyMMdd-XXX' (XXX là số thứ tự trong ngày).
         + Giảm số lượng chỗ trống trong bảng ParkingLot.

    Chú ý:
    - Nếu xe có vé tháng, không cần tạo vé gửi xe theo giờ.
    - Khi xe vào, số lượng chỗ trống trong bãi luôn giảm đi 1.
*/

create PROCEDURE sp_VehicleEntry
    @LicensePlate NVARCHAR(20),
    @VehicleType NVARCHAR(10),
    @LotID INT
AS
BEGIN
    DECLARE @SubscriptionID INT;
    DECLARE @ExistingTicketID INT;

    -- Kiểm tra vé tháng
    SELECT @SubscriptionID = SubscriptionID
    FROM MonthlySubscriptions
    WHERE LicensePlate = @LicensePlate AND IsActive = 1 AND EndDate >= GETDATE();

    IF @SubscriptionID IS NOT NULL
    BEGIN
        -- Xe trả tháng
        -- Kiểm tra xem xe đã ở trong bãi chưa
        IF EXISTS (SELECT 1 FROM MonthlySubscriptions WHERE SubscriptionID = @SubscriptionID AND IsOut = 0)
        BEGIN
            RAISERROR ('Xe vé tháng này đã ở trong bãi!', 16, 1);
            RETURN;
        END

        UPDATE MonthlySubscriptions
        SET IsOut = 0,
            LotID = @LotID -- Ghi LotID khi xe vào
        WHERE SubscriptionID = @SubscriptionID;

        UPDATE ParkingLot
        SET AvailableSlots = AvailableSlots - 1
        WHERE LotID = @LotID;

        INSERT INTO Transactions (LicensePlate, TransactionType, Amount, TransactionDate, SubscriptionID)
        VALUES (@LicensePlate, 'Monthly', 0, GETDATE(), @SubscriptionID);
		SELECT N'Xe vé tháng vào bãi thành công, ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' vé tháng được cập nhật, ' + 
       CAST((SELECT @@ROWCOUNT) AS NVARCHAR) + N' giao dịch được ghi' AS Message;
    END
    ELSE
    BEGIN
        -- Xe theo giờ
        -- Kiểm tra xem xe đã có vé còn hiệu lực trong bãi chưa
        SELECT @ExistingTicketID = TicketID
        FROM ParkingTickets
        WHERE LicensePlate = @LicensePlate AND IsValid = 1 AND IsOut = 0;

        IF @ExistingTicketID IS NOT NULL
        BEGIN
            RAISERROR ('Xe này đã có vé còn hiệu lực trong bãi!', 16, 1);
            RETURN;
        END

        -- Kiểm tra chỗ trống trong bãi
        IF (SELECT AvailableSlots FROM ParkingLot WHERE LotID = @LotID) <= 0
        BEGIN
            RAISERROR ('Bãi xe đã hết chỗ!', 16, 1);
            RETURN;
        END

        -- Tạo vé mới
        INSERT INTO ParkingTickets (TicketCode, LicensePlate, VehicleType, EntryTime, LotID)
        VALUES ('TICKET-' + FORMAT(GETDATE(), 'yyyyMMdd') + '-' + RIGHT('000' + CAST((SELECT COUNT(*) + 1 FROM ParkingTickets WHERE EntryTime >= CAST(GETDATE() AS DATE)) AS NVARCHAR), 3),
                @LicensePlate, @VehicleType, GETDATE(), @LotID);

        UPDATE ParkingLot
        SET AvailableSlots = AvailableSlots - 1
        WHERE LotID = @LotID;
		SELECT N'Xe vé lượt vào bãi thành công, ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' vé xe được cấp, ' + 
       CAST((SELECT @@ROWCOUNT) AS NVARCHAR) + N' giao dịch được ghi' AS Message;
    END
END;





/*
    Thủ tục sp_VehicleExit xử lý quá trình xe rời khỏi bãi đỗ dựa trên mã vé và trạng thái mất vé.

    1. Lấy thông tin từ bảng ParkingTickets:
       - Kiểm tra xem vé có hợp lệ không (tồn tại và còn hiệu lực).
       - Nếu vé không hợp lệ, báo lỗi và kết thúc thủ tục.

    2. Xác định phí gửi xe:
       - Lấy mức phí theo giờ và phí phạt mất vé từ bảng FeeRates dựa trên loại xe.
       - Tính số giờ gửi xe dựa trên khoảng cách giữa thời gian vào bãi và thời gian hiện tại.
       - Nếu thời gian gửi xe dưới 1 giờ, tính phí tối thiểu là 1 giờ.
       - Nhân số giờ với mức phí theo giờ để tính tổng phí.

    3. Cập nhật trạng thái vé:
       - Lưu lại phí gửi xe, trạng thái mất vé (nếu có), và đánh dấu vé đã hết hiệu lực và xe đã rời bãi.

    4. Cập nhật số lượng chỗ trống trong bảng ParkingLot:
       - Tăng số chỗ trống của bãi xe thêm 1.

    5. Ghi nhận giao dịch vào bảng Transactions:
       - Nếu vé hợp lệ, ghi giao dịch với loại 'Hourly' và số tiền tương ứng.
       - Nếu vé bị mất, ghi thêm một giao dịch với loại 'LostFee' và số tiền phạt mất vé.

    Chú ý:
    - Mỗi giao dịch được ghi lại riêng biệt trong bảng Transactions.
    - Nếu vé bị mất, hệ thống sẽ tính cả phí gửi xe lẫn phí phạt mất vé.
    - Vé hết hạn sau khi xe rời khỏi bãi để tránh sử dụng lại.
*/

create PROCEDURE sp_VehicleExit
    @LicensePlate NVARCHAR(20),
    @TicketCode NVARCHAR(20) = NULL, -- Tham số tùy chọn, NULL nếu mất vé
    @IsLost BIT = 0                 -- Mặc định không mất vé
AS
BEGIN
    DECLARE @ValidTicketCode NVARCHAR(20), @VehicleType NVARCHAR(10), @EntryTime DATETIME, @LotID INT;
    DECLARE @HourlyRate DECIMAL(10, 2), @LostFee DECIMAL(10, 2), @Fee DECIMAL(10, 2), @Hours INT;

    -- Tìm vé còn hiệu lực của biển số xe
    SELECT @ValidTicketCode = TicketCode, @VehicleType = VehicleType, @EntryTime = EntryTime, @LotID = LotID
    FROM ParkingTickets
    WHERE LicensePlate = @LicensePlate AND IsValid = 1 AND IsOut = 0;

    IF @ValidTicketCode IS NULL
    BEGIN
        RAISERROR ('Không tìm thấy vé còn hiệu lực cho biển số xe này!', 16, 1);
        RETURN;
    END

    -- Kiểm tra vé nộp (nếu có)
    IF @TicketCode IS NOT NULL
    BEGIN
        IF @TicketCode != @ValidTicketCode
        BEGIN
            RAISERROR ('Vé nộp không khớp với vé còn hiệu lực của xe này!', 16, 1);
            RETURN;
        END
    END

    -- Nếu mất vé, yêu cầu @TicketCode = NULL và @IsLost = 1
    IF @IsLost = 1 AND @TicketCode IS NOT NULL
    BEGIN
        RAISERROR ('Trường hợp mất vé phải truyền TicketCode = NULL!', 16, 1);
        RETURN;
    END

    -- Tính phí
    SELECT @HourlyRate = HourlyRate, @LostFee = LostTicketFee
    FROM FeeRates WHERE VehicleType = @VehicleType;

    SET @Hours = DATEDIFF(HOUR, @EntryTime, GETDATE());
    IF @Hours < 1 SET @Hours = 1;
    SET @Fee = @HourlyRate * @Hours;

    -- Cập nhật vé
    UPDATE ParkingTickets
    SET Fee = @Fee,
        IsLost = @IsLost,
        LostFee = CASE WHEN @IsLost = 1 THEN @LostFee ELSE 0 END,
        IsValid = 0,
        IsOut = 1
    WHERE TicketCode = @ValidTicketCode;

    -- Cập nhật bãi xe
    UPDATE ParkingLot
    SET AvailableSlots = AvailableSlots + 1
    WHERE LotID = @LotID;

    -- Ghi giao dịch
    INSERT INTO Transactions (LicensePlate, TransactionType, Amount, TransactionDate, TicketID)
    VALUES (@LicensePlate, 'Hourly', @Fee, GETDATE(), (SELECT TicketID FROM ParkingTickets WHERE TicketCode = @ValidTicketCode));
	SELECT 
        N'Xe biển số ' + @LicensePlate + 
        N' đã ra khỏi bãi thành công, phí là ' + CAST(@Fee AS NVARCHAR) + ' VND' AS Message;

    IF @IsLost = 1
    BEGIN
        INSERT INTO Transactions (LicensePlate, TransactionType, Amount, TransactionDate, TicketID)
        VALUES (@LicensePlate, 'LostFee', @LostFee, GETDATE(), (SELECT TicketID FROM ParkingTickets WHERE TicketCode = @ValidTicketCode));
		SELECT 
            N'Xe biển số ' + @LicensePlate + 
            N' bị phạt do mất vé, phí phạt là ' + CAST(@LostFee AS NVARCHAR) + ' VND' AS Message;
    END
END;


/*
    Thủ tục sp_MonthlyVehicleExit xử lý quá trình xe có vé tháng rời khỏi bãi đỗ.

    1. Kiểm tra xe vé tháng:
       - Truy vấn bảng MonthlySubscriptions để tìm SubscriptionID dựa trên biển số xe.
       - Kiểm tra xem xe có vé tháng còn hiệu lực không (IsActive = 1, EndDate >= ngày hiện tại).
       - Kiểm tra xe đã ra khỏi bãi chưa (IsOut = 0).
       - Nếu không tìm thấy vé hợp lệ hoặc xe đã ra khỏi bãi, báo lỗi và kết thúc thủ tục.

    2. Cập nhật trạng thái xe:
       - Đánh dấu IsOut = 1 trong bảng MonthlySubscriptions để xác nhận xe đã rời khỏi bãi.

    3. Cập nhật số lượng chỗ trống trong bảng ParkingLot:
       - Tăng số chỗ trống trong bãi xe thêm 1.

    4. Ghi nhận giao dịch vào bảng Transactions (tùy chọn):
       - Lưu lại thông tin xe rời bãi với loại giao dịch 'Monthly' và số tiền = 0.
       - Giao dịch này giúp theo dõi thời gian xe vào/ra đối với vé tháng.

    Chú ý:
    - Vé tháng không bị tính phí mỗi lần ra vào, nhưng việc cập nhật trạng thái giúp quản lý chỗ đỗ hiệu quả.
    - Nếu xe ra nhưng không cập nhật IsOut, hệ thống có thể không kiểm soát đúng số lượng xe trong bãi.
*/

create PROCEDURE sp_MonthlyVehicleExit
    @LicensePlate NVARCHAR(20)
AS
BEGIN
    DECLARE @SubscriptionID INT, @LotID INT;

    -- Kiểm tra xe vé tháng và lấy LotID
    SELECT @SubscriptionID = SubscriptionID, @LotID = LotID
    FROM MonthlySubscriptions
    WHERE LicensePlate = @LicensePlate 
      AND IsActive = 1 
      AND EndDate >= GETDATE() 
      AND IsOut = 0;

    IF @SubscriptionID IS NULL
    BEGIN
        RAISERROR ('Không tìm thấy xe vé tháng hoặc xe đã ra!', 16, 1);
        RETURN;
    END

    -- Cập nhật trạng thái xe ra
    UPDATE MonthlySubscriptions
    SET IsOut = 1,
        LotID = NULL -- Đặt LotID về NULL khi xe ra
    WHERE SubscriptionID = @SubscriptionID;

    -- Cập nhật số lượng chỗ trống trong bãi (nếu LotID không NULL)
    IF @LotID IS NOT NULL
    BEGIN
        UPDATE ParkingLot
        SET AvailableSlots = AvailableSlots + 1
        WHERE LotID = @LotID;
    END

    -- (Tùy chọn) Ghi giao dịch để theo dõi
    INSERT INTO Transactions (LicensePlate, TransactionType, Amount, TransactionDate, SubscriptionID)
    VALUES (@LicensePlate, 'Monthly', 0, GETDATE(), @SubscriptionID);
	SELECT N'Xe vé tháng đã ra khỏi bãi thành công, ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' vé tháng được cập nhật, ' + 
       CAST((SELECT @@ROWCOUNT) AS NVARCHAR) + N' giao dịch được ghi' AS Message;
END;


/*
    Trigger tr_CheckParkingLot đảm bảo rằng bãi đỗ xe không bị quá tải khi có xe mới vào.

    1. Lấy thông tin bãi đỗ xe:
       - Truy vấn bảng INSERTED để lấy LotID của vé mới được thêm vào bảng ParkingTickets.

    2. Kiểm tra số lượng chỗ trống:
       - Truy vấn bảng ParkingLot để lấy số lượng chỗ trống hiện tại của bãi xe tương ứng.

    3. Xử lý khi bãi xe đầy:
       - Nếu AvailableSlots < 0, nghĩa là số chỗ đỗ đã bị vượt quá giới hạn.
       - Kích hoạt lỗi bằng RAISERROR để thông báo rằng bãi xe đã hết chỗ.
       - ROLLBACK TRANSACTION để hủy bỏ thao tác INSERT và tránh tình trạng quá tải.

    Chú ý:
    - Trigger này chạy AFTER INSERT, tức là chỉ kích hoạt sau khi có một bản ghi mới được thêm vào ParkingTickets.
    - Việc ROLLBACK TRANSACTION sẽ đảm bảo rằng nếu có lỗi xảy ra, vé sẽ không được thêm vào bảng ParkingTickets.
    - Để tránh lỗi logic, cần đảm bảo rằng AvailableSlots trong bảng ParkingLot được cập nhật đúng sau mỗi lượt xe vào/ra.
*/

CREATE TRIGGER tr_CheckParkingLot
ON ParkingTickets
AFTER INSERT
AS
BEGIN
    DECLARE @LotID INT, @AvailableSlots INT;

    SELECT @LotID = LotID
    FROM INSERTED;

    SELECT @AvailableSlots = AvailableSlots
    FROM ParkingLot
    WHERE LotID = @LotID;

    IF @AvailableSlots < 0
    BEGIN
        RAISERROR ('Bãi xe đã vượt quá giới hạn!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;



----Thủ tục tính tổng doanh thu
create PROCEDURE sp_CalculateTotalRevenue
    @Year INT = NULL, -- Nếu NULL, tính tất cả các năm
    @Month INT = NULL -- Nếu NULL, tính tất cả các tháng trong năm
AS
BEGIN
    -- Tính doanh thu từ vé lượt
    WITH HourlyRevenue AS (
        SELECT 
            YEAR(TransactionDate) AS RevenueYear,
            MONTH(TransactionDate) AS RevenueMonth,
            SUM(Amount) AS HourlyRevenue
        FROM Transactions
        WHERE TransactionType IN ('Hourly', 'LostFee')
            AND (@Year IS NULL OR YEAR(TransactionDate) = @Year)
            AND (@Month IS NULL OR MONTH(TransactionDate) = @Month)
        GROUP BY YEAR(TransactionDate), MONTH(TransactionDate)
    ),
    
    -- Tính doanh thu từ vé tháng
    MonthlyRevenue AS (
        SELECT 
            YEAR(ms.StartDate) AS RevenueYear,
            MONTH(ms.StartDate) AS RevenueMonth,
            -- Phân bổ doanh thu cho từng tháng dựa trên số ngày thực tế
            SUM(ms.MonthlyFee * 
                CAST(
                    -- Tính số ngày trong tháng
                    DATEDIFF(DAY, 
                        GREATEST(ms.StartDate, DATEFROMPARTS(YEAR(ms.StartDate), MONTH(ms.StartDate), 1)),
                        LEAST(ms.EndDate, EOMONTH(ms.StartDate, 0))
                    ) + 1 AS DECIMAL(10, 2)) 
                / DATEDIFF(DAY, ms.StartDate, ms.EndDate)) AS MonthlyRevenue
        FROM MonthlySubscriptions ms
        WHERE ms.IsActive = 1
            AND (@Year IS NULL OR YEAR(ms.StartDate) = @Year)
            AND (@Month IS NULL OR MONTH(ms.StartDate) = @Month)
        GROUP BY YEAR(ms.StartDate), MONTH(ms.StartDate)
    )

    -- Gộp kết quả từ hai CTE và tính tổng doanh thu
    SELECT 
        COALESCE(h.RevenueYear, m.RevenueYear) AS RevenueYear,
        COALESCE(h.RevenueMonth, m.RevenueMonth) AS RevenueMonth,
        ISNULL(h.HourlyRevenue, 0) AS HourlyRevenue,
        ISNULL(m.MonthlyRevenue, 0) AS MonthlyRevenue,
        ISNULL(h.HourlyRevenue, 0) + ISNULL(m.MonthlyRevenue, 0) AS TotalRevenue
    FROM HourlyRevenue h
    FULL OUTER JOIN MonthlyRevenue m
        ON h.RevenueYear = m.RevenueYear 
        AND h.RevenueMonth = m.RevenueMonth
    ORDER BY RevenueYear, RevenueMonth;
END;

-----


---Thủ tục đăng ký vé tháng--
CREATE PROCEDURE AddMonthlySubscription
    @LicensePlate NVARCHAR(20),
    @VehicleType NVARCHAR(10),
    @StartDate DATE,
    @EndDate DATE,
    @MonthlyFee DECIMAL(10, 2),
    @LotID INT = NULL -- Optional, có thể không có LotID
AS
BEGIN
    -- Kiểm tra xem xe có đang đăng ký rồi không (nếu có điều kiện này)
    IF EXISTS (SELECT 1 FROM MonthlySubscriptions WHERE LicensePlate = @LicensePlate AND IsActive = 1 AND IsOut = 0)
    BEGIN
        RAISERROR('Xe này đã có đăng ký tháng và đang còn trong bãi!', 16, 1);
        RETURN;
    END

    -- Thêm đăng ký tháng mới
    INSERT INTO MonthlySubscriptions (LicensePlate, VehicleType, StartDate, EndDate, MonthlyFee, IsActive, IsOut, LotID)
    VALUES (@LicensePlate, @VehicleType, @StartDate, @EndDate, @MonthlyFee, 1, 1, @LotID);
    
    -- Trả về ID của đăng ký mới
    SELECT SCOPE_IDENTITY() AS SubscriptionID;
END













--Phần 4 : Chạy thử với 1 vài bản ghi dữ liệu
-----------------------------
-------------------------------------
--------------------------------------
EXEC sp_CalculateTotalRevenue;
EXEC sp_CalculateTotalRevenue @Year = 2025, @Month = 4;


-- Xe 1 vào (có vẽ tháng)
EXEC sp_VehicleEntry @LicensePlate = '29A-12345', @VehicleType = 'Car', @LotID = 1;

-- Kiểm tra kết quả
SELECT * FROM MonthlySubscriptions WHERE LicensePlate = '29A-12345' ; -- IsOut = 0
SELECT * FROM ParkingLot WHERE LotID = 1; -- AvailableSlots = 49
SELECT * FROM Transactions WHERE LicensePlate = '29A-12345'; -- Amount = 0


--Xe số 2:
-- Xe vào
EXEC sp_VehicleEntry @LicensePlate = '51K-98765', @VehicleType = 'Motorcycle', @LotID = 1;
SELECT * FROM ParkingTickets WHERE LicensePlate = '51K-98765' and IsValid=1; 
SELECT * FROM ParkingLot WHERE LotID = 1; 
SELECT * FROM Transactions WHERE LicensePlate = '51K-98765'; 

-- Xe ra (thanh toán)
EXEC sp_VehicleExit @LicensePlate ='51K-98765',@TicketCode ='', @IsLost = 0;

-- Kiểm tra kết quả
SELECT * FROM ParkingTickets WHERE LicensePlate = '51K-98765'; -- Fee = 4000, IsValid = 0, IsOut = 1
SELECT * FROM ParkingLot WHERE LotID = 1; -- AvailableSlots = 49 (giảm khi vào, tăng khi ra)
SELECT * FROM Transactions WHERE LicensePlate = '51K-98765'; -- Amount = 4000

--Xe 3
-- Xe vào
EXEC sp_VehicleEntry @LicensePlate = '29B-54321', @VehicleType = 'Car', @LotID = 2;

SELECT * FROM ParkingTickets WHERE LicensePlate = '29B-54321' and IsValid=1; -- Fee = 30000, LostFee = 50000, IsValid = 0, IsOut = 1
SELECT * FROM ParkingLot WHERE LotID = 2; -- AvailableSlots = 29 (giảm khi vào, tăng khi ra)

-- Cập nhật IsLost trước khi xe ra
UPDATE ParkingTickets
SET IsLost = 1
WHERE TicketCode = 'TICKET-20250402-002';


-- Xe ra (thanh toán)
EXEC sp_VehicleExit @LicensePlate = '29B-54321', @TicketCode = 'TICKET-20250403-012', @IsLost = 0;

-- Kiểm tra kết quả
SELECT * FROM ParkingTickets WHERE LicensePlate = '29B-54321'; -- Fee = 30000, LostFee = 50000, IsValid = 0, IsOut = 1
SELECT * FROM ParkingLot WHERE LotID = 2; -- AvailableSlots = 29 (giảm khi vào, tăng khi ra)
SELECT * FROM Transactions WHERE LicensePlate = '29B-54321'; -- 2 giao dịch: Hourly (30000), LostFee (50000)


select *from Transactions

select *from ParkingLot


--Xe 4 vào bãi
EXEC sp_VehicleEntry @LicensePlate = '52H-45678', @VehicleType = 'Motorcycle', @LotID = 1;

SELECT * FROM ParkingTickets WHERE LicensePlate = '52H-45678' and IsValid=1;
--Vé mới được tạo với TicketCode = 'TICKET-20250402-003'.
--IsValid = 1 (vé còn hiệu lực), IsOut = 0 (xe còn trong bãi).
--Fee và LostFee chưa được tính (NULL).
SELECT * FROM ParkingLot WHERE LotID = 1;
--AvailableSlots giảm từ 49 (sau Xe 2 ra) xuống 48 vì Xe 4 vào.
SELECT * FROM Transactions WHERE LicensePlate = '52H-45678';
--: Không có bản ghi nào vì giao dịch chỉ được ghi khi xe ra (với vé lượt).

--Xe 4 ra:
EXEC sp_VehicleExit @LicensePlate ='52H-45678', @IsLost = 1;

SELECT * FROM ParkingTickets WHERE LicensePlate = '52H-45678';
--Fee = 4000 (2 giờ * 2000 VND/giờ cho xe máy).
--IsValid = 0 (vé hết hiệu lực), IsOut = 1 (xe đã ra).
--IsLost = 0, LostFee = 0 (không mất vé).
SELECT * FROM ParkingLot WHERE LotID = 1;
--AvailableSlots tăng từ 48 lên 49 vì Xe 4 đã ra.
SELECT * FROM Transactions WHERE LicensePlate = '52H-45678';
--Giao dịch Hourly được ghi với Amount = 4000 (phí gửi xe 2 giờ).
--Không có giao dịch LostFee vì IsLost = 0.




--Thực hiện Xe 1 ra khỏi bãi
EXEC sp_MonthlyVehicleExit @LicensePlate = '29A-12345';


SELECT * FROM MonthlySubscriptions WHERE LicensePlate = '29A-12345';
--IsOut = 1 (xe đã ra khỏi bãi).

SELECT * FROM ParkingLot WHERE LotID = 1;
--AvailableSlots tăng từ 49 (sau khi Xe 4 ra) lên 50 vì Xe 1 ra.
SELECT * FROM Transactions WHERE LicensePlate = '29A-12345';
--Giao dịch thứ nhất (ID 1) là khi xe vào.
--Giao dịch thứ hai (ID 6) là khi xe ra, với Amount = 0 để theo dõi (có thể bỏ bước này nếu bạn không cần).





SELECT * FROM vw_VehiclesInParkingLot;






select sum(amount) from Transactions



select *from Transactions

