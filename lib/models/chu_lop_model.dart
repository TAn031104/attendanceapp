import 'package:cloud_firestore/cloud_firestore.dart';

class ChuLop {
  String uid;
  String maChuLop;
  String hoTen;
  String email;
  String? soDienThoai;
  String? tenCoSo;
  DateTime ngayTao;

  ChuLop({
    required this.uid,
    required this.maChuLop,
    required this.hoTen,
    required this.email,
    this.soDienThoai,
    this.tenCoSo,
    required this.ngayTao,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'maChuLop': maChuLop,
      'hoTen': hoTen,
      'email': email,
      'soDienThoai': soDienThoai,
      'tenCoSo': tenCoSo,
      'ngayTao': Timestamp.fromDate(ngayTao),
    };
  }

  factory ChuLop.fromMap(Map<String, dynamic> map) {
    return ChuLop(
      uid: map['uid'] ?? '',
      maChuLop: map['maChuLop'] ?? '',
      hoTen: map['hoTen'] ?? '',
      email: map['email'] ?? '',
      soDienThoai: map['soDienThoai'],
      tenCoSo: map['tenCoSo'],
      ngayTao: (map['ngayTao'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
