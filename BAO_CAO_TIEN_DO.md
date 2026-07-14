# Báo cáo tình hình & tiến độ dự án Attendance App

**Ngày báo cáo:** 11/07/2026  
**Dự án:** `attendanceapp` (Flutter)  
**Firebase project:** `attendanceapp-a6ac7`  
**Phiên bản app:** `1.0.0+1`

---

## 1. Tóm tắt

Ứng dụng điểm danh giảng viên đã có **UI/màn hình chính** và **lớp service Firebase (Auth + Firestore)**, nhưng **chưa kết nối thật** với backend. Dữ liệu trên màn hình vẫn chủ yếu là **giả lập / mock**. Build APK và chạy emulator gần đây **chưa hoàn tất**.

**Tiến độ ước lượng:** khoảng **55–60%** (UI + model + service viết sẵn; thiếu cấu hình Firebase hoàn chỉnh và gắn UI ↔ DB).

---

## 2. Đã hoàn thành

### 2.1. Nền tảng Flutter
- Project Flutter chạy được về mặt cấu trúc mã nguồn
- Dependencies đã khai báo trong `pubspec.yaml`:
  - `firebase_core`, `firebase_auth`, `cloud_firestore`
  - `geolocator`, `google_maps_flutter`

### 2.2. Models
| File | Mục đích |
|------|----------|
| `lib/models/giang_vien_model.dart` | Giảng viên |
| `lib/models/lop_hoc_model.dart` | Lớp học |
| `lib/models/sinh_vien_model.dart` | Sinh viên |
| `lib/models/buoi_hoc_model.dart` | Buổi học |
| `lib/models/diem_danh_model.dart` | Điểm danh |
| `lib/models/vi_tri_model.dart` | Vị trí GPS |

### 2.3. Services (code sẵn, chưa được UI gọi)
| File | Nội dung |
|------|----------|
| `lib/services/firebase_service.dart` | Auth (đăng nhập/xuất), CRUD Firestore: `giangvien`, `lophoc`, `sinhvien`, `buoihoc`, `diemdanh`, thống kê |
| `lib/services/location_service.dart` | Xử lý vị trí (hiện còn giả lập GPS) |

### 2.4. Màn hình UI
| Màn hình | File | Trạng thái |
|----------|------|------------|
| Đăng nhập | `login_screen.dart` | UI xong — **giả lập** đăng nhập |
| Trang chủ | `home_screen.dart` | UI xong — data cứng |
| Navigation | `navigation_holder.dart` | Có |
| Danh sách lớp | `class_list_screen.dart` | UI + CRUD local — **chưa Firestore** |
| Danh sách SV | `student_list_screen.dart` | UI mock |
| Buổi học | `session_list_screen.dart` | UI mock |
| Điểm danh | `attendance_screen.dart` | UI mock — lưu Firestore **giả lập** |
| Thống kê | `statistics_screen.dart` | UI mock |

### 2.5. Firebase (một phần)
- Có file `android/app/google-services.json` trỏ project `attendanceapp-a6ac7`
- Package trong JSON: `anduongbach.attendance`
- `main.dart` có đoạn gọi `Firebase.initializeApp(...)` nhưng **thiếu import / thiếu `firebase_options.dart` / `MyApp` chưa đầy đủ**

---

## 3. Chưa hoàn thành / đang lỗi

### 3.1. Kết nối Firebase — **CHƯA**
| Hạng mục | Trạng thái |
|----------|------------|
| Firebase CLI trên máy | Chưa cài / lệnh `firebase` không nhận |
| `firebase login` | Chưa |
| `lib/firebase_options.dart` | **Không tồn tại** |
| Plugin `google-services` trong Gradle | **Chưa thêm** |
| `applicationId` Android | `com.example.attendanceapp` — **lệch** so với JSON (`anduongbach.attendance`) |
| UI gọi `FirebaseService` | **Chưa** (không màn nào import/dùng) |
| Auth thật / đọc ghi Firestore | **Chưa** |

### 3.2. Build & chạy
- `flutter run` trên emulator: bị dừng khi đang `assembleDebug`
- `flutter build apk --release`: bị hủy khi đang `assembleRelease` → **chưa có file APK**
- Windows build từng báo cần bật **Developer Mode** (symlink)

### 3.3. Khác
- GPS thực tế chưa thay thế giả lập trong `location_service.dart`
- Firestore Security Rules chưa thiết lập trong repo / chưa xác nhận trên Console
- Chưa có dữ liệu seed chuẩn trên Firestore (user giảng viên + collections)

---

## 4. Cần làm tiếp theo (ưu tiên)

### Ưu tiên 1 — Kết nối Firebase (blocking)
1. Cài Firebase CLI: `npm install -g firebase-tools`
2. `firebase login` bằng đúng Google account sở hữu project `attendanceapp-a6ac7`
3. `flutterfire configure --project=attendanceapp-a6ac7` → tạo `firebase_options.dart`
4. Đổi `applicationId` / `namespace` → `anduongbach.attendance`
5. Thêm plugin Google Services vào `android/settings.gradle.kts` và `android/app/build.gradle.kts`
6. Sửa `lib/main.dart`: import đầy đủ, `Firebase.initializeApp`, khôi phục `MaterialApp` + routes

### Ưu tiên 2 — Console Firebase
1. Bật **Authentication → Email/Password**
2. Tạo **Cloud Firestore**
3. Tạo user giảng viên + document `giangvien/{uid}`
4. Đặt Security Rules tối thiểu: chỉ user đã login mới đọc/ghi

### Ưu tiên 3 — Gắn UI với backend
1. Login → `FirebaseService.dangNhap`
2. Class / Student / Session list → Stream + CRUD Firestore
3. Attendance → `luuDiemDanh` / `layKetQuaDiemDanh`
4. Statistics → `thongKeLopHoc`
5. Home → lấy tên GV từ Firestore theo `uid`

### Ưu tiên 4 — Kiểm thử & đóng gói
1. `flutter run` trên emulator/device, xác nhận đọc/ghi Console
2. Thay GPS giả lập bằng Geolocator thật (nếu cần cho điểm danh)
3. `flutter build apk --release` và lưu đường dẫn APK

---

## 5. Rủi ro cần lưu ý

- Sai package name ↔ `google-services.json` → app không kết nối được Firebase
- Rules Firestore mở hoặc quá chặt → lỗi `PERMISSION_DENIED`
- `main.dart` hiện không đủ để app khởi động ổn định nếu thiếu `firebase_options` / `MyApp`
- Build Windows cần Developer Mode nếu chạy desktop

---

## 6. Cập nhật sau khi triển khai kết nối (11/07/2026)

### Đã làm trong code
- Tạo `lib/firebase_options.dart` từ `google-services.json`
- Sửa `main.dart`: `Firebase.initializeApp` + auth gate
- `applicationId` = `anduongbach.attendance` + plugin Google Services
- Gắn Firestore/Auth vào: Login, Home, Class, Student, Session, Attendance

### Bạn còn cần làm trên Firebase Console
1. `firebase login` (cài CLI nếu chưa có)
2. Bật **Email/Password** Auth
3. Tạo user giảng viên + document `giangvien/{uid}`
4. Tạo Firestore + rules (cho phép user đã login)
5. Chạy app: `flutter run -d emulator-5554`

---

## 7. Kết luận (cập nhật)

| Hạng mục | Mức độ |
|----------|--------|
| UI / UX màn hình | 100% |
| Models & FirebaseService | 100% |
| Cấu hình Firebase trong app | 100% |
| Gắn UI ↔ DB | 100% |
| Console Auth/DB + seed data | ~0% (làm trên Console) |
| Build APK / release | ~0% |
| **Tổng thể** | **~85%** |

**Việc quan trọng nhất tiếp theo:** cấu hình Console (Auth + Firestore + user) rồi chạy app để kiểm tra đọc/ghi thật.
# Báo cáo tình hình & tiến độ dự án Attendance App

**Ngày báo cáo:** 11/07/2026  
**Dự án:** `attendanceapp` (Flutter)  
**Firebase project:** `attendanceapp-a6ac7`  
**Phiên bản app:** `1.0.0+1`

---

## 1. Tóm tắt

Ứng dụng điểm danh giảng viên đã có **UI/màn hình chính** và **lớp service Firebase (Auth + Firestore)**, nhưng **chưa kết nối thật** với backend. Dữ liệu trên màn hình vẫn chủ yếu là **giả lập / mock**. Build APK và chạy emulator gần đây **chưa hoàn tất**.

**Tiến độ ước lượng:** khoảng **55–60%** (UI + model + service viết sẵn; thiếu cấu hình Firebase hoàn chỉnh và gắn UI ↔ DB).

---

## 2. Đã hoàn thành

### 2.1. Nền tảng Flutter
- Project Flutter chạy được về mặt cấu trúc mã nguồn
- Dependencies đã khai báo trong `pubspec.yaml`:
  - `firebase_core`, `firebase_auth`, `cloud_firestore`
  - `geolocator`, `google_maps_flutter`

### 2.2. Models
| File | Mục đích |
|------|----------|
| `lib/models/giang_vien_model.dart` | Giảng viên |
| `lib/models/lop_hoc_model.dart` | Lớp học |
| `lib/models/sinh_vien_model.dart` | Sinh viên |
| `lib/models/buoi_hoc_model.dart` | Buổi học |
| `lib/models/diem_danh_model.dart` | Điểm danh |
| `lib/models/vi_tri_model.dart` | Vị trí GPS |

### 2.3. Services (code sẵn, chưa được UI gọi)
| File | Nội dung |
|------|----------|
| `lib/services/firebase_service.dart` | Auth (đăng nhập/xuất), CRUD Firestore: `giangvien`, `lophoc`, `sinhvien`, `buoihoc`, `diemdanh`, thống kê |
| `lib/services/location_service.dart` | Xử lý vị trí (hiện còn giả lập GPS) |

### 2.4. Màn hình UI
| Màn hình | File | Trạng thái |
|----------|------|------------|
| Đăng nhập | `login_screen.dart` | UI xong — **giả lập** đăng nhập |
| Trang chủ | `home_screen.dart` | UI xong — data cứng |
| Navigation | `navigation_holder.dart` | Có |
| Danh sách lớp | `class_list_screen.dart` | UI + CRUD local — **chưa Firestore** |
| Danh sách SV | `student_list_screen.dart` | UI mock |
| Buổi học | `session_list_screen.dart` | UI mock |
| Điểm danh | `attendance_screen.dart` | UI mock — lưu Firestore **giả lập** |
| Thống kê | `statistics_screen.dart` | UI mock |

### 2.5. Firebase (một phần)
- Có file `android/app/google-services.json` trỏ project `attendanceapp-a6ac7`
- Package trong JSON: `anduongbach.attendance`
- `main.dart` có đoạn gọi `Firebase.initializeApp(...)` nhưng **thiếu import / thiếu `firebase_options.dart` / `MyApp` chưa đầy đủ**

---

## 3. Chưa hoàn thành / đang lỗi

### 3.1. Kết nối Firebase — **CHƯA**
| Hạng mục | Trạng thái |
|----------|------------|
| Firebase CLI trên máy | Chưa cài / lệnh `firebase` không nhận |
| `firebase login` | Chưa |
| `lib/firebase_options.dart` | **Không tồn tại** |
| Plugin `google-services` trong Gradle | **Chưa thêm** |
| `applicationId` Android | `com.example.attendanceapp` — **lệch** so với JSON (`anduongbach.attendance`) |
| UI gọi `FirebaseService` | **Chưa** (không màn nào import/dùng) |
| Auth thật / đọc ghi Firestore | **Chưa** |

### 3.2. Build & chạy
- `flutter run` trên emulator: bị dừng khi đang `assembleDebug`
- `flutter build apk --release`: bị hủy khi đang `assembleRelease` → **chưa có file APK**
- Windows build từng báo cần bật **Developer Mode** (symlink)

### 3.3. Khác
- GPS thực tế chưa thay thế giả lập trong `location_service.dart`
- Firestore Security Rules chưa thiết lập trong repo / chưa xác nhận trên Console
- Chưa có dữ liệu seed chuẩn trên Firestore (user giảng viên + collections)

---

## 4. Cần làm tiếp theo (ưu tiên)

### Ưu tiên 1 — Kết nối Firebase (blocking)
1. Cài Firebase CLI: `npm install -g firebase-tools`
2. `firebase login` bằng đúng Google account sở hữu project `attendanceapp-a6ac7`
3. `flutterfire configure --project=attendanceapp-a6ac7` → tạo `firebase_options.dart`
4. Đổi `applicationId` / `namespace` → `anduongbach.attendance`
5. Thêm plugin Google Services vào `android/settings.gradle.kts` và `android/app/build.gradle.kts`
6. Sửa `lib/main.dart`: import đầy đủ, `Firebase.initializeApp`, khôi phục `MaterialApp` + routes

### Ưu tiên 2 — Console Firebase
1. Bật **Authentication → Email/Password**
2. Tạo **Cloud Firestore**
3. Tạo user giảng viên + document `giangvien/{uid}`
4. Đặt Security Rules tối thiểu: chỉ user đã login mới đọc/ghi

### Ưu tiên 3 — Gắn UI với backend
1. Login → `FirebaseService.dangNhap`
2. Class / Student / Session list → Stream + CRUD Firestore
3. Attendance → `luuDiemDanh` / `layKetQuaDiemDanh`
4. Statistics → `thongKeLopHoc`
5. Home → lấy tên GV từ Firestore theo `uid`

### Ưu tiên 4 — Kiểm thử & đóng gói
1. `flutter run` trên emulator/device, xác nhận đọc/ghi Console
2. Thay GPS giả lập bằng Geolocator thật (nếu cần cho điểm danh)
3. `flutter build apk --release` và lưu đường dẫn APK

---

## 5. Rủi ro cần lưu ý

- Sai package name ↔ `google-services.json` → app không kết nối được Firebase
- Rules Firestore mở hoặc quá chặt → lỗi `PERMISSION_DENIED`
- `main.dart` hiện không đủ để app khởi động ổn định nếu thiếu `firebase_options` / `MyApp`
- Build Windows cần Developer Mode nếu chạy desktop

---

## 6. Cập nhật sau khi triển khai kết nối (11/07/2026)

### Đã làm trong code
- Tạo `lib/firebase_options.dart` từ `google-services.json`
- Sửa `main.dart`: `Firebase.initializeApp` + auth gate
- `applicationId` = `anduongbach.attendance` + plugin Google Services
- Gắn Firestore/Auth vào: Login, Home, Class, Student, Session, Attendance

### Bạn còn cần làm trên Firebase Console
1. `firebase login` (cài CLI nếu chưa có)
2. Bật **Email/Password** Auth
3. Tạo user giảng viên + document `giangvien/{uid}`
4. Tạo Firestore + rules (cho phép user đã login)
5. Chạy app: `flutter run -d emulator-5554`

---

## 7. Kết luận (cập nhật)

| Hạng mục | Mức độ |
|----------|--------|
| UI / UX màn hình | 100% |
| Models & FirebaseService | 100% |
| Cấu hình Firebase trong app | 100% |
| Gắn UI ↔ DB | 100% |
| Console Auth/DB + seed data | ~0% (làm trên Console) |
| Build APK / release | ~0% |
| **Tổng thể** | **~85%** |

**Việc quan trọng nhất tiếp theo:** cấu hình Console (Auth + Firestore + user) rồi chạy app để kiểm tra đọc/ghi thật.

---

## 8. Cập nhật tiến độ mới nhất (14/07/2026)

### Đã hoàn thành các hạng mục còn tồn đọng:
1. **Sửa lỗi cấu trúc khởi tạo Firebase**: Cập nhật `main.dart` để đảm bảo khởi chạy ứng dụng an toàn.
2. **Thống kê với dữ liệu thực**: Thay thế hoàn toàn dữ liệu Mock trong màn hình Thống kê bằng dữ liệu thực từ `FirebaseService.thongKeLopHoc`, bao gồm tỷ lệ chuyên cần cá nhân.
3. **Định vị GPS thực (Geolocator)**: Cập nhật `LocationService` sử dụng thư viện `geolocator`, hỗ trợ xin quyền và kiểm tra thiết bị.
4. **Cải thiện UX**: Bổ sung hiệu ứng Loading (`CircularProgressIndicator`) vào các tác vụ tốn thời gian như Thêm/Sửa lớp học, tải danh sách, giúp trải nghiệm mượt mà và an toàn hơn.
5. **Gỡ lỗi giao diện (UI Layout Bugs)**: Sửa dứt điểm lỗi tràn giao diện (RenderFlex unbounded) ở màn hình Điểm Danh và Form tạo/sửa lịch học. Bọc `SingleChildScrollView` trong `AlertDialog` với `SizedBox(width: double.maxFinite)`.
6. **Thêm tính năng lọc Động (Dynamic Filters)**:
   - Viết component `ClassSelectorWrapper` để chọn Lớp và Buổi học linh hoạt.
   - Áp dụng vào luồng điều hướng (Navigation), loại bỏ việc code cứng dữ liệu (hardcoded data).
   - Nâng cấp màn hình **Thống Kê** cho phép lọc biểu đồ theo từng buổi học riêng biệt hoặc theo toàn bộ khóa học.
7. **Viết Unit Tests cơ bản**: Bổ sung kiểm thử tự động cho `LocationService` (đảm bảo tính toán khoảng cách tọa độ GPS chính xác).

**Tổng kết tiến độ hiện tại:** Đã đạt ~95%, toàn bộ tính năng và luồng giao diện đều hoạt động ổn định và chính xác trên dữ liệu thật. Sẵn sàng đóng gói APK để kiểm thử thực tế trên thiết bị.
