import 'package:cloud_firestore/cloud_firestore.dart';
import 'vi_tri_model.dart';

class BuoiHoc {
  String maBuoiHoc;
  String maLop;
  String uidChuLop;
  DateTime ngayHoc;
  String gioBatDau;
  String gioKetThuc;
  String diaDiem;
  ViTri? viTriLop;
  String? noiDungBuoiHoc;
  String trangThai;

  BuoiHoc({
    required this.maBuoiHoc,
    required this.maLop,
    required this.uidChuLop,
    required this.ngayHoc,
    required this.gioBatDau,
    required this.gioKetThuc,
    required this.diaDiem,
    this.viTriLop,
    this.noiDungBuoiHoc,
    required this.trangThai,
  });

  Map<String, dynamic> toMap() {
    return {
      'maBuoiHoc': maBuoiHoc,
      'maLop': maLop,
      'uidChuLop': uidChuLop,
      'ngayHoc': Timestamp.fromDate(ngayHoc),
      'gioBatDau': gioBatDau,
      'gioKetThuc': gioKetThuc,
      'diaDiem': diaDiem,
      'viTriLop': viTriLop?.toMap(),
      'noiDungBuoiHoc': noiDungBuoiHoc,
      'trangThai': trangThai,
    };
  }

  factory BuoiHoc.fromMap(Map<String, dynamic> map) {
    return BuoiHoc(
      maBuoiHoc: map['maBuoiHoc'] ?? '',
      maLop: map['maLop'] ?? '',
      uidChuLop: map['uidChuLop'] ?? '',
      ngayHoc: (map['ngayHoc'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gioBatDau: map['gioBatDau'] ?? '',
      gioKetThuc: map['gioKetThuc'] ?? '',
      diaDiem: map['diaDiem'] ?? '',
      viTriLop: map['viTriLop'] != null ? ViTri.fromMap(map['viTriLop']) : null,
      noiDungBuoiHoc: map['noiDungBuoiHoc'],
      trangThai: map['trangThai'] ?? 'Sắp diễn ra',
    );
  }
}
