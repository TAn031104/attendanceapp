import 'package:cloud_firestore/cloud_firestore.dart';

class HocVien {
  String maHocVien;
  String hoTen;
  String? email;
  String? soDienThoai;
  DateTime? ngaySinh;
  String maLop;
  String uidChuLop;
  String? tenPhuHuynh;
  String? soDienThoaiPhuHuynh;
  String? ghiChu;
  DateTime ngayThamGia;
  String trangThai;

  HocVien({
    required this.maHocVien,
    required this.hoTen,
    this.email,
    this.soDienThoai,
    this.ngaySinh,
    required this.maLop,
    required this.uidChuLop,
    this.tenPhuHuynh,
    this.soDienThoaiPhuHuynh,
    this.ghiChu,
    required this.ngayThamGia,
    required this.trangThai,
  });

  Map<String, dynamic> toMap() {
    return {
      'maHocVien': maHocVien,
      'hoTen': hoTen,
      'email': email,
      'soDienThoai': soDienThoai,
      'ngaySinh': ngaySinh != null ? Timestamp.fromDate(ngaySinh!) : null,
      'maLop': maLop,
      'uidChuLop': uidChuLop,
      'tenPhuHuynh': tenPhuHuynh,
      'soDienThoaiPhuHuynh': soDienThoaiPhuHuynh,
      'ghiChu': ghiChu,
      'ngayThamGia': Timestamp.fromDate(ngayThamGia),
      'trangThai': trangThai,
    };
  }

  factory HocVien.fromMap(Map<String, dynamic> map) {
    return HocVien(
      maHocVien: map['maHocVien'] ?? '',
      hoTen: map['hoTen'] ?? '',
      email: map['email'],
      soDienThoai: map['soDienThoai'],
      ngaySinh: (map['ngaySinh'] as Timestamp?)?.toDate(),
      maLop: map['maLop'] ?? '',
      uidChuLop: map['uidChuLop'] ?? '',
      tenPhuHuynh: map['tenPhuHuynh'],
      soDienThoaiPhuHuynh: map['soDienThoaiPhuHuynh'],
      ghiChu: map['ghiChu'],
      ngayThamGia: (map['ngayThamGia'] as Timestamp?)?.toDate() ?? DateTime.now(),
      trangThai: map['trangThai'] ?? 'Đang học',
    );
  }
}
