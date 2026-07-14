import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chu_lop_model.dart';
import '../models/lop_hoc_model.dart';
import '../models/hoc_vien_model.dart';
import '../models/buoi_hoc_model.dart';
import '../models/diem_danh_model.dart';

class MockUserCredential implements UserCredential {
  @override
  final User? user;
  MockUserCredential(String email) : user = MockUser(email);
  @override
  AuthCredential? get credential => null;
  @override
  AdditionalUserInfo? get additionalUserInfo => null;
}

class MockUser implements User {
  @override
  final String? email;
  @override
  final String uid = 'mock-uid';
  @override
  final String displayName = 'Chủ Lớp Thử Nghiệm';
  MockUser(this.email);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static bool useMock = false;

  String? get currentUid => useMock ? 'mock-uid' : _auth.currentUser?.uid;

  // ==================== MOCK DATA & CONTROLLERS ====================
  static final List<LopHoc> _mockLopHoc = [
    LopHoc(
        maLop: 'TOAN8_01', 
        tenLop: 'Toán lớp 8', 
        monHoc: 'Toán', 
        moTa: 'Ôn tập',
        uidChuLop: 'mock-uid', 
        siSoToiDa: 20, 
        hocPhi: 500000, 
        donViHocPhi: 'tháng', 
        ngayBatDau: DateTime.now().subtract(const Duration(days: 30)), 
        trangThai: 'Đang hoạt động', 
        ngayTao: DateTime.now()),
  ];

  static final List<HocVien> _mockHocVien = [
    HocVien(maHocVien: 'HV001', hoTen: 'Nguyễn Văn A', maLop: 'TOAN8_01', uidChuLop: 'mock-uid', ngayThamGia: DateTime.now(), trangThai: 'Đang học'),
    HocVien(maHocVien: 'HV002', hoTen: 'Trần Thị B', maLop: 'TOAN8_01', uidChuLop: 'mock-uid', ngayThamGia: DateTime.now(), trangThai: 'Đang học'),
  ];

  static final List<BuoiHoc> _mockBuoiHoc = [
    BuoiHoc(
      maBuoiHoc: 'buoi1', maLop: 'TOAN8_01', uidChuLop: 'mock-uid', ngayHoc: DateTime.now().subtract(const Duration(days: 7)),
      gioBatDau: '18:00', gioKetThuc: '20:00', diaDiem: 'Phòng 101', trangThai: 'Đã hoàn thành',
    ),
    BuoiHoc(
      maBuoiHoc: 'buoi2', maLop: 'TOAN8_01', uidChuLop: 'mock-uid', ngayHoc: DateTime.now(),
      gioBatDau: '18:00', gioKetThuc: '20:00', diaDiem: 'Phòng 101', trangThai: 'Sắp diễn ra',
    ),
  ];

  static final List<DiemDanh> _mockDiemDanh = [
    DiemDanh(maHocVien: 'HV001', maBuoiHoc: 'buoi1', maLop: 'TOAN8_01', uidChuLop: 'mock-uid', trangThai: TrangThaiDiemDanh.coMat, thoiGianDiemDanh: DateTime.now().subtract(const Duration(days: 7))),
    DiemDanh(maHocVien: 'HV002', maBuoiHoc: 'buoi1', maLop: 'TOAN8_01', uidChuLop: 'mock-uid', trangThai: TrangThaiDiemDanh.vang, thoiGianDiemDanh: DateTime.now().subtract(const Duration(days: 7))),
  ];

  static final StreamController<List<LopHoc>> _lopHocController = StreamController<List<LopHoc>>.broadcast();
  static final StreamController<List<HocVien>> _hocVienController = StreamController<List<HocVien>>.broadcast();
  static final StreamController<List<BuoiHoc>> _buoiHocController = StreamController<List<BuoiHoc>>.broadcast();

  // ==================== 1. XÁC THỰC (AUTH) ====================
  
  Future<UserCredential> dangNhap(String email, String password) async {
    if (useMock) return MockUserCredential(email);
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> dangXuat() async {
    if (useMock) return;
    await _auth.signOut();
  }

  Future<ChuLop?> layThongTinChuLop(String uid) async {
    if (useMock) {
      return ChuLop(
        uid: 'mock-uid',
        maChuLop: 'CL001',
        hoTen: 'Chủ Lớp Thử Nghiệm',
        email: uid.contains('@') ? uid : 'chulop@gmail.com',
        ngayTao: DateTime.now(),
      );
    }
    DocumentSnapshot doc = await _db.collection('chulop').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return ChuLop.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // ==================== 2. QUẢN LÝ LỚP HỌC (CRUD LOPHOC) ====================

  Future<void> themLopHoc(LopHoc lop) async {
    if (useMock) {
      if (_mockLopHoc.any((l) => l.maLop == lop.maLop)) throw Exception('Mã lớp học đã tồn tại.');
      lop.uidChuLop = currentUid ?? '';
      _mockLopHoc.add(lop);
      _lopHocController.add(List.from(_mockLopHoc));
      return;
    }
    lop.uidChuLop = currentUid ?? '';
    await _db.collection('lophoc').doc(lop.maLop).set(lop.toMap());
  }

  Stream<List<LopHoc>> layDanhSachLopHoc() {
    String? uid = currentUid;
    debugPrint('[SERVICE] layDanhSachLopHoc called with uid=$uid');
    if (useMock) {
      final controller = StreamController<List<LopHoc>>();
      controller.add(_mockLopHoc.where((l) => l.uidChuLop == uid).toList());
      final subscription = _lopHocController.stream.listen((updatedList) {
        if (!controller.isClosed) controller.add(updatedList.where((l) => l.uidChuLop == uid).toList());
      });
      controller.onCancel = () {
        subscription.cancel();
        controller.close();
      };
      return controller.stream;
    }
    return _db.collection('lophoc').where('uidChuLop', isEqualTo: uid).snapshots().map((snapshot) {
      debugPrint('[SERVICE] layDanhSachLopHoc result=${snapshot.docs.length}');
      return snapshot.docs.map((doc) => LopHoc.fromMap(doc.data())).toList();
    });
  }

  Future<void> capNhatLopHoc(LopHoc lop) async {
    if (useMock) {
      final idx = _mockLopHoc.indexWhere((l) => l.maLop == lop.maLop && l.uidChuLop == currentUid);
      if (idx != -1) {
        _mockLopHoc[idx] = lop;
        _lopHocController.add(List.from(_mockLopHoc));
      }
      return;
    }
    await _db.collection('lophoc').doc(lop.maLop).update(lop.toMap());
  }

  Future<void> xoaLopHoc(String maLop) async {
    if (useMock) {
      _mockLopHoc.removeWhere((l) => l.maLop == maLop && l.uidChuLop == currentUid);
      _lopHocController.add(List.from(_mockLopHoc));
      
      _mockHocVien.removeWhere((hv) => hv.maLop == maLop);
      _hocVienController.add(List.from(_mockHocVien));
      
      final sessionIds = _mockBuoiHoc.where((bh) => bh.maLop == maLop).map((bh) => bh.maBuoiHoc).toList();
      _mockBuoiHoc.removeWhere((bh) => bh.maLop == maLop);
      _buoiHocController.add(List.from(_mockBuoiHoc));
      
      _mockDiemDanh.removeWhere((dd) => sessionIds.contains(dd.maBuoiHoc));
      return;
    }
    await _db.collection('lophoc').doc(maLop).delete();
  }

  // ==================== 3. QUẢN LÝ HỌC VIÊN ====================

  Future<void> themHocVien(HocVien hv) async {
    if (useMock) {
      if (_mockHocVien.any((s) => s.maHocVien == hv.maHocVien)) throw Exception('Mã học viên đã tồn tại.');
      hv.uidChuLop = currentUid ?? '';
      _mockHocVien.add(hv);
      _hocVienController.add(List.from(_mockHocVien));
      return;
    }
    hv.uidChuLop = currentUid ?? '';
    await _db.collection('hocvien').doc(hv.maHocVien).set(hv.toMap());
  }

  Stream<List<HocVien>> layDanhSachHocVien(String maLop) {
    String? uid = currentUid;
    debugPrint('[SERVICE] layDanhSachHocVien called with uid=$uid, maLop=$maLop');
    if (useMock) {
      final controller = StreamController<List<HocVien>>();
      controller.add(_mockHocVien.where((hv) => hv.maLop == maLop && hv.uidChuLop == uid).toList());
      
      final subscription = _hocVienController.stream.listen((updatedList) {
        if (!controller.isClosed) {
          controller.add(updatedList.where((hv) => hv.maLop == maLop && hv.uidChuLop == uid).toList());
        }
      });
      controller.onCancel = () {
        subscription.cancel();
        controller.close();
      };
      return controller.stream;
    }
    return _db.collection('hocvien')
        .where('maLop', isEqualTo: maLop)
        .where('uidChuLop', isEqualTo: uid)
        .snapshots().map((snapshot) {
      debugPrint('[SERVICE] layDanhSachHocVien result=${snapshot.docs.length}');
      return snapshot.docs.map((doc) => HocVien.fromMap(doc.data())).toList();
    });
  }

  Future<void> capNhatHocVien(HocVien hv) async {
    if (useMock) {
      final idx = _mockHocVien.indexWhere((s) => s.maHocVien == hv.maHocVien && s.uidChuLop == currentUid);
      if (idx != -1) {
        _mockHocVien[idx] = hv;
        _hocVienController.add(List.from(_mockHocVien));
      }
      return;
    }
    await _db.collection('hocvien').doc(hv.maHocVien).update(hv.toMap());
  }

  Future<void> xoaHocVien(String maHocVien) async {
    if (useMock) {
      _mockHocVien.removeWhere((s) => s.maHocVien == maHocVien && s.uidChuLop == currentUid);
      _hocVienController.add(List.from(_mockHocVien));
      _mockDiemDanh.removeWhere((dd) => dd.maHocVien == maHocVien);
      return;
    }
    await _db.collection('hocvien').doc(maHocVien).delete();
  }

  // ==================== 4. QUẢN LÝ BUỔI HỌC ====================

  Future<void> themBuoiHoc(BuoiHoc buoi) async {
    if (useMock) {
      if (_mockBuoiHoc.any((bh) => bh.maBuoiHoc == buoi.maBuoiHoc)) throw Exception('Mã buổi học đã tồn tại.');
      buoi.uidChuLop = currentUid ?? '';
      _mockBuoiHoc.add(buoi);
      _buoiHocController.add(List.from(_mockBuoiHoc));
      return;
    }
    buoi.uidChuLop = currentUid ?? '';
    await _db.collection('buoihoc').doc(buoi.maBuoiHoc).set(buoi.toMap());
  }

  Future<void> themNhieuBuoiHoc(List<BuoiHoc> danhSachBuoi) async {
    if (useMock) {
      for (var buoi in danhSachBuoi) {
        buoi.uidChuLop = currentUid ?? '';
        if (!_mockBuoiHoc.any((bh) => bh.maBuoiHoc == buoi.maBuoiHoc)) {
          _mockBuoiHoc.add(buoi);
        }
      }
      _buoiHocController.add(List.from(_mockBuoiHoc));
      return;
    }
    
    WriteBatch batch = _db.batch();
    for (var buoi in danhSachBuoi) {
      buoi.uidChuLop = currentUid ?? '';
      DocumentReference docRef = _db.collection('buoihoc').doc(buoi.maBuoiHoc);
      batch.set(docRef, buoi.toMap());
    }
    await batch.commit();
  }

  Stream<List<BuoiHoc>> layDanhSachBuoiHoc(String maLop) {
    String? uid = currentUid;
    if (useMock) {
      final controller = StreamController<List<BuoiHoc>>();
      controller.add(_mockBuoiHoc.where((bh) => bh.maLop == maLop && bh.uidChuLop == uid).toList());
      
      final subscription = _buoiHocController.stream.listen((updatedList) {
        if (!controller.isClosed) {
          controller.add(updatedList.where((bh) => bh.maLop == maLop && bh.uidChuLop == uid).toList());
        }
      });
      controller.onCancel = () {
        subscription.cancel();
        controller.close();
      };
      return controller.stream;
    }
    return _db.collection('buoihoc')
        .where('uidChuLop', isEqualTo: uid)
        .where('maLop', isEqualTo: maLop)
        .snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BuoiHoc.fromMap(doc.data())).toList();
    });
  }

  Future<void> capNhatBuoiHoc(BuoiHoc buoi) async {
    if (useMock) {
      final idx = _mockBuoiHoc.indexWhere((bh) => bh.maBuoiHoc == buoi.maBuoiHoc && bh.uidChuLop == currentUid);
      if (idx != -1) {
        _mockBuoiHoc[idx] = buoi;
        _buoiHocController.add(List.from(_mockBuoiHoc));
      }
      return;
    }
    await _db.collection('buoihoc').doc(buoi.maBuoiHoc).update(buoi.toMap());
  }

  Future<void> xoaBuoiHoc(String maBuoiHoc) async {
    if (useMock) {
      _mockBuoiHoc.removeWhere((bh) => bh.maBuoiHoc == maBuoiHoc && bh.uidChuLop == currentUid);
      _buoiHocController.add(List.from(_mockBuoiHoc));
      _mockDiemDanh.removeWhere((dd) => dd.maBuoiHoc == maBuoiHoc);
      return;
    }
    await _db.collection('buoihoc').doc(maBuoiHoc).delete();
    var query = await _db.collection('diemdanh')
      .where('maBuoiHoc', isEqualTo: maBuoiHoc)
      .where('uidChuLop', isEqualTo: currentUid)
      .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // ==================== 5. QUẢN LÝ ĐIỂM DANH ====================

  Future<void> luuDiemDanh(List<DiemDanh> danhSachDiemDanh) async {
    if (useMock) {
      for (var dd in danhSachDiemDanh) {
        dd.uidChuLop = currentUid ?? '';
        final idx = _mockDiemDanh.indexWhere((d) => d.maBuoiHoc == dd.maBuoiHoc && d.maHocVien == dd.maHocVien);
        if (idx != -1) _mockDiemDanh[idx] = dd;
        else _mockDiemDanh.add(dd);
      }
      return;
    }
    WriteBatch batch = _db.batch();
    for (var dd in danhSachDiemDanh) {
      dd.uidChuLop = currentUid ?? '';
      String docId = '${dd.maBuoiHoc}_${dd.maHocVien}';
      DocumentReference docRef = _db.collection('diemdanh').doc(docId);
      batch.set(docRef, dd.toMap());
    }
    await batch.commit();
  }

  Future<List<DiemDanh>> layKetQuaDiemDanh(String maBuoiHoc) async {
    String? uid = currentUid;
    if (useMock) {
      return _mockDiemDanh.where((dd) => dd.maBuoiHoc == maBuoiHoc && dd.uidChuLop == uid).toList();
    }
    QuerySnapshot snapshot = await _db.collection('diemdanh')
        .where('uidChuLop', isEqualTo: uid)
        .where('maBuoiHoc', isEqualTo: maBuoiHoc)
        .get();
    return snapshot.docs.map((doc) => DiemDanh.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  // ==================== 6. THỐNG KÊ ====================

  Future<Map<String, dynamic>> thongKeLopHoc(String maLop, {String? maBuoiHoc}) async {
    String? uid = currentUid;
    
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      List<String> dsMaBuoi = _mockBuoiHoc.where((bh) => bh.maLop == maLop && bh.uidChuLop == uid).map((bh) => bh.maBuoiHoc).toList();
      if (maBuoiHoc != null) {
        dsMaBuoi.removeWhere((id) => id != maBuoiHoc);
      }
      int tongSoBuoi = dsMaBuoi.length;
      int coMat = 0, diTre = 0, vang = 0, coPhep = 0;
      
      final svTrongLop = _mockHocVien.where((sv) => sv.maLop == maLop && sv.uidChuLop == uid).toList();
      int tongSoHocVien = svTrongLop.length;
      List<Map<String, dynamic>> studentRates = [];

      if (dsMaBuoi.isNotEmpty) {
        final filteredDiemDanh = _mockDiemDanh.where((dd) => dsMaBuoi.contains(dd.maBuoiHoc)).toList();
        for (var dd in filteredDiemDanh) {
          if (dd.trangThai == TrangThaiDiemDanh.coMat) coMat++;
          else if (dd.trangThai == TrangThaiDiemDanh.diTre) diTre++;
          else if (dd.trangThai == TrangThaiDiemDanh.vang) vang++;
          else if (dd.trangThai == TrangThaiDiemDanh.coPhep) coPhep++;
        }
        
        for (var sv in svTrongLop) {
          int svCoMat = filteredDiemDanh.where((dd) => dd.maHocVien == sv.maHocVien && 
              (dd.trangThai == TrangThaiDiemDanh.coMat || dd.trangThai == TrangThaiDiemDanh.diTre)).length;
          studentRates.add({
             'name': sv.hoTen,
             'rate': tongSoBuoi > 0 ? (svCoMat / tongSoBuoi) : 0.0,
          });
        }
      } else {
        for (var sv in svTrongLop) {
          studentRates.add({'name': sv.hoTen, 'rate': 0.0});
        }
      }

      return {
        'tongSoBuoi': tongSoBuoi,
        'tongSoSinhVien': tongSoHocVien, // using same map key for UI compatibility temporarily
        'coMat': coMat,
        'diTre': diTre,
        'vang': vang,
        'coPhep': coPhep,
        'studentRates': studentRates,
      };
    }
    
    QuerySnapshot buoiSnap = await _db.collection('buoihoc')
        .where('uidChuLop', isEqualTo: uid)
        .where('maLop', isEqualTo: maLop).get();
    List<String> dsMaBuoi = buoiSnap.docs.map((doc) => doc.id).toList();
    if (maBuoiHoc != null) {
      dsMaBuoi.removeWhere((id) => id != maBuoiHoc);
    }

    int tongSoBuoi = dsMaBuoi.length;
    int coMat = 0, diTre = 0, vang = 0, coPhep = 0;
    
    QuerySnapshot svSnap = await _db.collection('hocvien')
        .where('uidChuLop', isEqualTo: uid)
        .where('maLop', isEqualTo: maLop).get();
    int tongSoHocVien = svSnap.docs.length;
    List<Map<String, dynamic>> studentRates = [];

    if (dsMaBuoi.isNotEmpty) {
      QuerySnapshot diemDanhSnap = await _db.collection('diemdanh').where('uidChuLop', isEqualTo: uid).get();
      var allDiemDanh = diemDanhSnap.docs.where((doc) {
        String maBH = doc.get('maBuoiHoc') ?? '';
        return dsMaBuoi.contains(maBH);
      }).toList();
      
      for (var doc in allDiemDanh) {
        String trangThai = doc.get('trangThai') ?? '';
        if (trangThai == TrangThaiDiemDanh.coMat.tenTiengViet) coMat++;
        else if (trangThai == TrangThaiDiemDanh.diTre.tenTiengViet) diTre++;
        else if (trangThai == TrangThaiDiemDanh.vang.tenTiengViet) vang++;
        else if (trangThai == TrangThaiDiemDanh.coPhep.tenTiengViet) coPhep++;
      }
      
      for (var sv in svSnap.docs) {
        String maHV = sv.id;
        String hoTen = sv.get('hoTen') ?? '';
        int svCoMat = allDiemDanh.where((doc) {
           String docMaHV = doc.get('maHocVien') ?? '';
           String trangThai = doc.get('trangThai') ?? '';
           return docMaHV == maHV && (trangThai == TrangThaiDiemDanh.coMat.tenTiengViet || trangThai == TrangThaiDiemDanh.diTre.tenTiengViet);
        }).length;
        
        studentRates.add({
           'name': hoTen,
           'rate': tongSoBuoi > 0 ? (svCoMat / tongSoBuoi) : 0.0,
        });
      }
    } else {
      for (var sv in svSnap.docs) {
        String hoTen = sv.get('hoTen') ?? '';
        studentRates.add({'name': hoTen, 'rate': 0.0});
      }
    }

    return {
      'tongSoBuoi': tongSoBuoi,
      'tongSoSinhVien': tongSoHocVien, // maintain key backward compatibility
      'coMat': coMat,
      'diTre': diTre,
      'vang': vang,
      'coPhep': coPhep,
      'studentRates': studentRates,
    };
  }

  // ==================== 7. MIGRATION ====================

  Future<Map<String, int>> migrateDataToNewDomain() async {
    if (useMock) return {};
    
    int successCount = 0;
    int errorCount = 0;
    
    try {
      // 1. Migrate GiangVien -> ChuLop
      var gvSnap = await _db.collection('giangvien').get();
      for (var doc in gvSnap.docs) {
        try {
          var data = doc.data();
          var cl = ChuLop(
            uid: doc.id,
            maChuLop: data['maGiangVien'] ?? '',
            hoTen: data['hoTen'] ?? '',
            email: data['email'] ?? '',
            ngayTao: DateTime.now(),
          );
          await _db.collection('chulop').doc(cl.uid).set(cl.toMap());
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      // 2. Migrate SinhVien -> HocVien
      var svSnap = await _db.collection('sinhvien').get();
      for (var doc in svSnap.docs) {
        try {
          var data = doc.data();
          var hv = HocVien(
            maHocVien: data['mssv'] ?? doc.id,
            hoTen: data['hoTen'] ?? '',
            email: data['email'],
            maLop: data['maLop'] ?? '',
            uidChuLop: currentUid ?? '',
            ngayThamGia: DateTime.now(),
            trangThai: 'Đang học',
          );
          await _db.collection('hocvien').doc(hv.maHocVien).set(hv.toMap());
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }
    } catch (e) {
      print('Migration error: $e');
    }
    
    return {'success': successCount, 'error': errorCount};
  }
}
