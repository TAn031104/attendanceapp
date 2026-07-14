import 'package:flutter_test/flutter_test.dart';
import 'package:attendanceapp/services/location_service.dart';
import 'package:attendanceapp/models/vi_tri_model.dart';

void main() {
  group('LocationService Tests', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    test('tinhKhoangCach should calculate distance correctly between two points', () {
      // Point 1: 10.7725, 106.6578 (e.g. HCM)
      final point1 = ViTri(latitude: 10.7725, longitude: 106.6578);
      // Point 2: 10.7735, 106.6578 (slightly north)
      final point2 = ViTri(latitude: 10.7735, longitude: 106.6578);

      final distance = locationService.tinhKhoangCach(point1, point2);
      
      // The distance should be roughly 111 meters (1 degree lat ~ 111km, 0.001 degree ~ 111m)
      expect(distance, inInclusiveRange(110.0, 112.0));
    });

    test('kiemTraHopLe should return true if within allowed distance', () {
      final point1 = ViTri(latitude: 10.7725, longitude: 106.6578);
      final point2 = ViTri(latitude: 10.7728, longitude: 106.6578); // very close, ~33m

      final isValid = locationService.kiemTraHopLe(point1, point2, gioiHanMet: 100.0);
      expect(isValid, isTrue);
    });

    test('kiemTraHopLe should return false if outside allowed distance', () {
      final point1 = ViTri(latitude: 10.7725, longitude: 106.6578);
      final point2 = ViTri(latitude: 10.7800, longitude: 106.6578); // far away, >800m

      final isValid = locationService.kiemTraHopLe(point1, point2, gioiHanMet: 100.0);
      expect(isValid, isFalse);
    });
  });
}
