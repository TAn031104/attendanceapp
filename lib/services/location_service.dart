import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../models/vi_tri_model.dart';
import 'firebase_service.dart';

class LocationService {
  // Bán kính Trái Đất trung bình theo mét
  static const double _earthRadius = 6371000.0;

  // Tính khoảng cách giữa 2 tọa độ bằng công thức Haversine
  double tinhKhoangCach(ViTri vt1, ViTri vt2) {
    double lat1Rad = vt1.latitude * math.pi / 180.0;
    double lat2Rad = vt2.latitude * math.pi / 180.0;
    
    double deltaLatRad = (vt2.latitude - vt1.latitude) * math.pi / 180.0;
    double deltaLngRad = (vt2.longitude - vt1.longitude) * math.pi / 180.0;

    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * 
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
        
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return _earthRadius * c; // Khoảng cách theo mét
  }

  // Kiểm tra chủ lớp có đứng trong phạm vi lớp học không (mặc định 100m)
  bool kiemTraHopLe(ViTri lopHoc, ViTri hienTai, {double gioiHanMet = 100.0}) {
    double khoangCach = tinhKhoangCach(lopHoc, hienTai);
    return khoangCach <= gioiHanMet;
  }

  // Lấy vị trí GPS hiện tại từ Geolocator
  Future<ViTri> layViTriHienTai() async {
    if (FirebaseService.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return ViTri(latitude: 10.7725, longitude: 106.6578);
    }

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Dịch vụ định vị đang bị tắt.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Quyền truy cập vị trí bị từ chối.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Quyền truy cập vị trí bị từ chối vĩnh viễn.');
    } 

    Position position = await Geolocator.getCurrentPosition();
    return ViTri(latitude: position.latitude, longitude: position.longitude);
  }
}
