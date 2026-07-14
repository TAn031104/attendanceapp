import 'package:cloud_firestore/cloud_firestore.dart';

enum TrangThaiDiemDanh {
  coMat, // Có mặt
  diTre, // Đi trễ
  vang,  // Vắng
  coPhep // Có phép
}

extension TrangThaiExtension on TrangThaiDiemDanh {
  String get tenTiengViet {
    switch (this) {
      case TrangThaiDiemDanh.coMat:
        return 'Có mặt';
      case TrangThaiDiemDanh.diTre:
        return 'Đi trễ';
      case TrangThaiDiemDanh.vang:
        return 'Vắng';
      case TrangThaiDiemDanh.coPhep:
        return 'Có phép';
    }
  }

  static TrangThaiDiemDanh parse(String value) {
    switch (value.toLowerCase()) {
      case 'có mặt':
      case 'comat':
      case 'present':
        return TrangThaiDiemDanh.coMat;
      case 'đi trễ':
      case 'ditre':
      case 'late':
        return TrangThaiDiemDanh.diTre;
      case 'có phép':
      case 'cophep':
        return TrangThaiDiemDanh.coPhep;
      case 'vắng':
      case 'vang':
      case 'absent':
      default:
        return TrangThaiDiemDanh.vang;
    }
  }
}

class DiemDanh {
  String maHocVien;
  String maBuoiHoc;
  String maLop;
  String uidChuLop;
  TrangThaiDiemDanh trangThai;
  DateTime thoiGianDiemDanh;
  String? ghiChu;

  DiemDanh({
    required this.maHocVien,
    required this.maBuoiHoc,
    required this.maLop,
    required this.uidChuLop,
    required this.trangThai,
    required this.thoiGianDiemDanh,
    this.ghiChu,
  });

  Map<String, dynamic> toMap() {
    return {
      'maHocVien': maHocVien,
      'maBuoiHoc': maBuoiHoc,
      'maLop': maLop,
      'uidChuLop': uidChuLop,
      'trangThai': trangThai.tenTiengViet,
      'thoiGianDiemDanh': Timestamp.fromDate(thoiGianDiemDanh),
      'ghiChu': ghiChu,
    };
  }

  factory DiemDanh.fromMap(Map<String, dynamic> map) {
    return DiemDanh(
      maHocVien: map['maHocVien'] ?? '',
      maBuoiHoc: map['maBuoiHoc'] ?? '',
      maLop: map['maLop'] ?? '',
      uidChuLop: map['uidChuLop'] ?? '',
      trangThai: map['trangThai'] != null 
          ? TrangThaiExtension.parse(map['trangThai']) 
          : TrangThaiDiemDanh.vang,
      thoiGianDiemDanh: (map['thoiGianDiemDanh'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ghiChu: map['ghiChu'],
    );
  }
}
