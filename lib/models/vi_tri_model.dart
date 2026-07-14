class ViTri {
  double _latitude;
  double _longitude;

  // Constructor
  ViTri({
    required double latitude,
    required double longitude,
  })  : _latitude = latitude,
        _longitude = longitude;

  // Getter & Setter cho latitude
  double get latitude => _latitude;
  set latitude(double value) {
    if (value < -90.0 || value > 90.0) {
      throw ArgumentError('Vĩ độ (Latitude) phải nằm trong khoảng từ -90 đến 90.');
    }
    _latitude = value;
  }

  // Getter & Setter cho longitude
  double get longitude => _longitude;
  set longitude(double value) {
    if (value < -180.0 || value > 180.0) {
      throw ArgumentError('Kinh độ (Longitude) phải nằm trong khoảng từ -180 đến 180.');
    }
    _longitude = value;
  }

  // Chuyển sang Map
  Map<String, dynamic> toMap() {
    return {
      'latitude': _latitude,
      'longitude': _longitude,
    };
  }

  // Tạo từ Map
  factory ViTri.fromMap(Map<String, dynamic> map) {
    return ViTri(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
