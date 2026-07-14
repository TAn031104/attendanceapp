import 'package:cloud_firestore/cloud_firestore.dart';

class LopHoc {
  String maLop;
  String tenLop;
  String monHoc;
  String? moTa;
  String uidChuLop;
  int siSoToiDa;
  double hocPhi;
  String donViHocPhi;
  DateTime ngayBatDau;
  DateTime? ngayKetThuc;
  String trangThai;
  DateTime ngayTao;

  LopHoc({
    required this.maLop,
    required this.tenLop,
    required this.monHoc,
    this.moTa,
    required this.uidChuLop,
    required this.siSoToiDa,
    required this.hocPhi,
    required this.donViHocPhi,
    required this.ngayBatDau,
    this.ngayKetThuc,
    required this.trangThai,
    required this.ngayTao,
  });

  Map<String, dynamic> toMap() {
    return {
      'maLop': maLop,
      'tenLop': tenLop,
      'monHoc': monHoc,
      'moTa': moTa,
      'uidChuLop': uidChuLop,
      'siSoToiDa': siSoToiDa,
      'hocPhi': hocPhi,
      'donViHocPhi': donViHocPhi,
      'ngayBatDau': Timestamp.fromDate(ngayBatDau),
      'ngayKetThuc': ngayKetThuc != null ? Timestamp.fromDate(ngayKetThuc!) : null,
      'trangThai': trangThai,
      'ngayTao': Timestamp.fromDate(ngayTao),
    };
  }

  factory LopHoc.fromMap(Map<String, dynamic> map) {
    return LopHoc(
      maLop: map['maLop'] ?? '',
      tenLop: map['tenLop'] ?? '',
      monHoc: map['monHoc'] ?? '',
      moTa: map['moTa'],
      uidChuLop: map['uidChuLop'] ?? '',
      siSoToiDa: map['siSoToiDa'] ?? 0,
      hocPhi: (map['hocPhi'] ?? 0).toDouble(),
      donViHocPhi: map['donViHocPhi'] ?? 'tháng',
      ngayBatDau: (map['ngayBatDau'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ngayKetThuc: (map['ngayKetThuc'] as Timestamp?)?.toDate(),
      trangThai: map['trangThai'] ?? 'Đang hoạt động',
      ngayTao: (map['ngayTao'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
