# Báo cáo Tổng quan & Chi tiết Kỹ thuật Dự án Attendance App (Ứng dụng Điểm danh)

Dự án phát triển ứng dụng di động hỗ trợ quản lý lớp học và điểm danh học viên sử dụng framework **Flutter** kết hợp cơ sở dữ liệu thời gian thực **Firebase (Authentication & Cloud Firestore)**.

---

## 1. Giới thiệu dự án
Ứng dụng **Attendance App** thiết kế dành cho giảng viên/chủ lớp học, hỗ trợ các quy trình quản lý học viên, quản lý lịch học, tự động hóa điểm danh thông qua việc xác thực tọa độ GPS thực tế của thiết bị, và hiển thị thống kê trực quan.

### Công nghệ sử dụng:
*   **Frontend Framework:** Flutter (Dart) với Material 3 Design
*   **Backend & DB:** Firebase (Authentication, Cloud Firestore)
*   **Thư viện lõi (Dependencies):**
    *   `firebase_core` & `firebase_auth` (Xác thực người dùng)
    *   `cloud_firestore` (Lưu trữ và đồng bộ cơ sở dữ liệu dạng NoSQL)
    *   `geolocator` (Định vị GPS thiết bị)
    *   `google_maps_flutter` (Bản đồ địa hình lớp học)

---

## 2. Kiến trúc dữ liệu (Database Schema - Cloud Firestore)

Cơ sở dữ liệu lưu trữ dưới dạng các Collection trên Cloud Firestore với các trường cụ thể:

### 2.1. Chủ Lớp (`chulop` collection)
Lưu thông tin tài khoản giảng viên đăng ký ứng dụng.
*   `uid` (String): ID định danh tài khoản từ Firebase Auth.
*   `maChuLop` (String): Mã số chủ lớp.
*   `hoTen` (String): Họ và tên chủ lớp.
*   `email` (String): Địa chỉ email.
*   `ngayTao` (Timestamp): Thời gian đăng ký tài khoản.

### 2.2. Lớp Học (`lophoc` collection)
Lưu trữ thông tin các lớp do chủ lớp quản lý.
*   `maLop` (String - Document ID): Mã lớp học (duy nhất).
*   `tenLop` (String): Tên lớp học.
*   `monHoc` (String): Môn giảng dạy.
*   `moTa` (String?): Mô tả thêm.
*   `uidChuLop` (String): ID tài khoản chủ lớp sở hữu lớp này.
*   `siSoToiDa` (int): Sĩ số học viên tối đa.
*   `hocPhi` (double): Mức học phí.
*   `donViHocPhi` (String): Đơn vị tính học phí (theo buổi, theo tháng...).
*   `ngayBatDau` (Timestamp): Ngày bắt đầu lớp.
*   `ngayKetThuc` (Timestamp?): Ngày kết thúc dự kiến.
*   `trangThai` (String): Trạng thái hoạt động ("Đang hoạt động", "Đã kết thúc").
*   `ngayTao` (Timestamp): Thời gian tạo lớp.

### 2.3. Buổi Học (`buoihoc` collection)
Lưu thông tin lịch học/ca học cụ thể của từng lớp.
*   `maBuoiHoc` (String - Document ID): Mã buổi học (ví dụ: `TOAN8_01_buoi1`).
*   `maLop` (String): Mã lớp học liên kết.
*   `uidChuLop` (String): ID tài khoản chủ lớp.
*   `ngayHoc` (Timestamp): Ngày diễn ra buổi học.
*   `gioBatDau` (String): Giờ bắt đầu (định dạng `HH:mm`).
*   `gioKetThuc` (String): Giờ kết thúc.
*   `diaDiem` (String): Phòng học / Địa điểm học.
*   `viTriLop` (Map): Tọa độ GPS của địa điểm học gồm `latitude` và `longitude`.
*   `noiDungBuoiHoc` (String?): Nội dung / Đề cương giảng dạy.
*   `trangThai` (String): Trạng thái buổi học ("Sắp diễn ra", "Đã hoàn thành").

### 2.4. Học Viên (`hocvien` collection)
Lưu danh sách học viên trong từng lớp học.
*   `maHocVien` (String - Document ID): Mã học viên (duy nhất).
*   `hoTen` (String): Họ và tên học viên.
*   `email` (String?): Địa chỉ email liên hệ.
*   `maLop` (String): Mã lớp học học viên tham gia.
*   `uidChuLop` (String): ID tài khoản chủ lớp.
*   `ngayThamGia` (Timestamp): Ngày bắt đầu tham gia lớp.
*   `trangThai` (String): Trạng thái đi học ("Đang học", "Đã nghỉ").

### 2.5. Điểm Danh (`diemdanh` collection)
Lưu kết quả điểm danh học viên theo từng buổi học.
*   `Document ID` ghép theo dạng: `${maBuoiHoc}_${maHocVien}`
*   `maHocVien` (String): Mã học viên được điểm danh.
*   `maBuoiHoc` (String): Mã buổi học thực hiện điểm danh.
*   `maLop` (String): Mã lớp học liên kết.
*   `uidChuLop` (String): ID tài khoản chủ lớp thực hiện.
*   `trangThai` (TrangThaiDiemDanh): Kết quả điểm danh gồm các trạng thái:
    *   `coMat` (Có mặt)
    *   `diTre` (Đi trễ)
    *   `vang` (Vắng mặt)
    *   `coPhep` (Vắng có phép)
*   `thoiGianDiemDanh` (Timestamp): Thời điểm nhấn nút lưu điểm danh.

---

## 3. Các chức năng chính & Các màn hình UI đã hoàn thành

Ứng dụng được xây dựng hoàn chỉnh bao gồm các phân hệ chính sau:

### 3.1. Phân hệ Xác thực (Authentication)
*   **Màn hình Đăng nhập (`login_screen.dart`):** Người dùng đăng nhập bằng Email và Mật khẩu. Trạng thái đăng nhập được kiểm soát liên tục thông qua Stream `authStateChanges()` ở `main.dart` để tự động điều hướng vào màn hình làm việc hoặc màn hình đăng nhập.

### 3.2. Màn hình Trang chủ Dashboard (`home_screen.dart`)
*   Hiển thị tóm tắt thống kê nhanh số lượng lớp học đang phụ trách.
*   Cung cấp các lối tắt truy cập nhanh tới các chức năng điểm danh, quản lý lớp.
*   Thiết kế Sidebar Drawer giúp điều hướng toàn diện ứng dụng.

### 3.3. Phân hệ Quản lý Lớp học (`class_list_screen.dart`)
*   Hiển thị danh sách toàn bộ các lớp học kèm theo thanh tìm kiếm động.
*   Cho phép Thêm mới, Chỉnh sửa, và Xóa thông tin lớp học trực tiếp đồng bộ lên Cloud Firestore.
*   Mỗi thẻ lớp học tích hợp nút điều hướng nhanh tới Danh sách học viên và Danh sách buổi học tương ứng.

### 3.4. Phân hệ Quản lý Học viên (`hoc_vien_list_screen.dart`)
*   Liệt kê toàn bộ danh sách học viên trong một lớp.
*   Hỗ trợ đầy đủ chức năng CRUD học viên. Có hiệu ứng Loading khi tương tác cơ sở dữ liệu.

### 3.5. Phân hệ Lịch học & Buổi học (`session_list_screen.dart`)
*   Quản lý lịch học của từng lớp cụ thể.
*   Tích hợp tính năng tạo nhanh nhiều buổi học tự động theo chu kỳ (ví dụ: lặp lại hàng tuần vào thứ 2 và thứ 4).

### 3.6. Phân hệ Điểm danh & Xác thực GPS (`attendance_screen.dart`)
*   Hiển thị danh sách học viên dạng bảng kiểm điểm danh với các tùy chọn: *Có mặt, Đi trễ, Vắng mặt, Vắng có phép*.
*   **Tự động xác thực vị trí (GPS Verification):** Sử dụng thư viện `geolocator` để lấy tọa độ thực tế của chủ lớp tại thời điểm điểm danh, so sánh khoảng cách với tọa độ GPS thiết lập của phòng học. Nếu khoảng cách ngoài giới hạn (ví dụ >100m) ứng dụng sẽ đưa ra cảnh báo để tránh việc điểm danh hộ hay gian lận từ xa.

### 3.7. Cổng thông tin Điểm danh chung (`all_sessions_list_screen.dart`)
*   Đây là trung tâm điều phối tất cả các buổi học của toàn bộ các lớp.
*   **Tính năng lọc nâng cao (Mới cập nhật):**
    *   *Lọc theo lớp học:* Chọn hiển thị buổi học của một lớp cụ thể từ danh sách lớp thực tế của giảng viên, hỗ trợ hiển thị tên lớp rõ ràng thay vì mã lớp khó nhớ.
    *   *Lọc theo ngày học:* Tích hợp bộ chọn ngày từ lịch trực quan (`showDatePicker`), hỗ trợ lọc nhanh các ca dạy trong ngày.
    *   *Bộ tìm kiếm đa năng:* Cho phép gõ tìm kiếm tức thời (Client-side filtering) theo Tên lớp, Mã lớp, Phòng học, Nội dung hay Ngày học dạng chuỗi hiển thị.
    *   *Chống tràn màn hình (Overflow Fixes):* Khắc phục triệt để lỗi tràn layout dọc khi mở bàn phím và lỗi tràn layout ngang bên phải do tên lớp quá dài trong dropdown bằng cách áp dụng `resizeToAvoidBottomInset: false` và `isExpanded: true`.

### 3.8. Phân hệ Thống kê Báo cáo (`statistics_screen.dart`)
*   Phân tích dữ liệu điểm danh thực tế từ cơ sở dữ liệu Firestore.
*   Cung cấp các biểu đồ tròn thống kê tổng tỷ lệ đi học, đi trễ, vắng mặt của cả lớp.
*   Liệt kê tỷ lệ đi học chuyên cần của từng học viên cụ thể trong lớp để giảng viên đánh giá năng lực học tập.
*   Hỗ trợ lọc biểu đồ linh hoạt theo từng buổi học đơn lẻ hoặc tổng quan cả khóa học.

---

## 4. Các dịch vụ hệ thống (Services)

*   `FirebaseService` ([firebase_service.dart](file:///c:/Users/Admin/Downloads/attendanceapp/attendanceapp/attendanceapp/lib/services/firebase_service.dart)): Đóng gói toàn bộ các hàm kết nối API Firebase: đăng nhập/đăng xuất, CRUD dữ liệu trên Cloud Firestore sử dụng phương pháp ghi theo lô (WriteBatch) để tối ưu hóa hiệu năng mạng và chi phí truy vấn Database, đồng thời tính toán thống kê số liệu chuyên cần.
*   `LocationService` ([location_service.dart](file:///c:/Users/Admin/Downloads/attendanceapp/attendanceapp/attendanceapp/lib/services/location_service.dart)): Đảm nhận việc kiểm tra quyền truy cập vị trí của thiết bị, bật GPS, định vị tọa độ hiện tại và tính toán khoảng cách toán học giữa hai điểm tọa độ theo thuật toán Haversine.

---

## 5. Kết quả Kiểm thử & Chất lượng Mã nguồn

Dự án đã triển khai tích hợp kiểm thử tự động (Unit Tests) để đảm bảo chất lượng:
*   **Unit Tests:** Kiểm tra độ chính xác của hàm tính khoảng cách GPS và logic kiểm tra vị trí hợp lệ trong `LocationService` ([location_service_test.dart](file:///c:/Users/Admin/Downloads/attendanceapp/attendanceapp/attendanceapp/test/location_service_test.dart)).
*   **Kết quả chạy thử:** Chạy lệnh `flutter test` thành công, vượt qua 100% các bài test quy định.

Ứng dụng hiện tại đạt độ hoàn thiện **~97%**, hoạt động mượt mà trên dữ liệu thực tế kết nối trực tiếp với đám mây Firebase Cloud Firestore, sẵn sàng đóng gói xuất bản bản cài đặt thử nghiệm (APK).
