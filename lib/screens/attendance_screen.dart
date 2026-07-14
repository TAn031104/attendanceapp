import 'dart:async';
import 'package:flutter/material.dart';

import '../models/diem_danh_model.dart';
import '../models/hoc_vien_model.dart';
import '../models/vi_tri_model.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String maBuoiHoc;
  final String maLop;

  const AttendanceScreen({
    super.key,
    required this.maBuoiHoc,
    this.maLop = 'CNTT01',
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final LocationService _locationService = LocationService();
  final FirebaseService _firebase = FirebaseService();

  final ViTri _viTriLop = ViTri(latitude: 10.7725, longitude: 106.6578);

  ViTri? _viTriHienTai;
  double _khoangCachMet = 0.0;
  bool _gpsHopLe = false;
  bool _isLoadingGps = true;
  bool _isLoadingStudents = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _studentAttendanceData = [];

  @override
  void initState() {
    super.initState();
    _xacThucViTriGPS();
    _loadStudentsAndAttendance();
  }

  StreamSubscription? _studentSub;

  @override
  void dispose() {
    _studentSub?.cancel();
    super.dispose();
  }

  Future<void> _loadStudentsAndAttendance() async {
    setState(() => _isLoadingStudents = true);
    
    Map<String, TrangThaiDiemDanh> statusByMaHocVien = {};
    try {
      final existing = await _firebase.layKetQuaDiemDanh(widget.maBuoiHoc);
      for (final dd in existing) {
        statusByMaHocVien[dd.maHocVien] = dd.trangThai;
      }
    } catch (e) {
      debugPrint('Lỗi lấy kết quả điểm danh cũ: $e');
    }

    _studentSub = _firebase.layDanhSachHocVien(widget.maLop).listen(
      (students) {
        if (!mounted) return;
        setState(() {
          _studentAttendanceData
            ..clear()
            ..addAll(
              students.map(
                (HocVien sv) => {
                  'maHocVien': sv.maHocVien,
                  'name': sv.hoTen,
                  'status': statusByMaHocVien[sv.maHocVien] ?? TrangThaiDiemDanh.coMat,
                },
              ),
            );
          _isLoadingStudents = false;
        });
      },
      onError: (e) {
        debugPrint('Lỗi tải học viên: $e');
        if (mounted) setState(() => _isLoadingStudents = false);
      },
    );
  }

  Future<void> _xacThucViTriGPS({ViTri? customLocation}) async {
    setState(() => _isLoadingGps = true);
    try {
      _viTriHienTai =
          customLocation ?? await _locationService.layViTriHienTai();
      _khoangCachMet =
          _locationService.tinhKhoangCach(_viTriLop, _viTriHienTai!);
      _gpsHopLe = _locationService.kiemTraHopLe(
        _viTriLop,
        _viTriHienTai!,
        gioiHanMet: 100.0,
      );
    } catch (e) {
      debugPrint('Lỗi GPS: $e');
      _gpsHopLe = false;
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (!_gpsHopLe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cảnh báo: Vị trí của bạn nằm ngoài phạm vi lớp học (>100m). Tuy nhiên vẫn cho phép lưu để thử nghiệm.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }

    if (_studentAttendanceData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có học viên để điểm danh.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final danhSach = _studentAttendanceData.map((sv) {
        return DiemDanh(
          maHocVien: sv['maHocVien'] as String,
          maBuoiHoc: widget.maBuoiHoc,
          maLop: widget.maLop,
          uidChuLop: _firebase.currentUid ?? '',
          trangThai: sv['status'] as TrangThaiDiemDanh,
          thoiGianDiemDanh: now,
        );
      }).toList();

      await _firebase.luuDiemDanh(danhSach);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu điểm danh lên Firestore'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi lưu điểm danh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final soBuoiText = widget.maBuoiHoc.split('_').last;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Điểm danh - Buổi #$soBuoiText',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildGpsIndicator(),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Lớp: ${widget.maLop}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Buổi: ${widget.maBuoiHoc}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    'Mã HV',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Họ và tên',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Trạng thái',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : _studentAttendanceData.isEmpty
                    ? const Center(
                        child: Text('Chưa có học viên trong lớp này.'),
                      )
                    : ListView.separated(
                        itemCount: _studentAttendanceData.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFF1F3F5),
                        ),
                        itemBuilder: (context, index) {
                          final sv = _studentAttendanceData[index];
                          final status = sv['status'] as TrangThaiDiemDanh;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    sv['maHocVien'] as String,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    sv['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<TrangThaiDiemDanh>(
                                      value: status,
                                      onChanged: (newStatus) {
                                        if (newStatus != null) {
                                          setState(
                                            () => sv['status'] = newStatus,
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 16,
                                      ),
                                      selectedItemBuilder: (context) {
                                        return TrangThaiDiemDanh.values
                                            .map((_) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              _getStatusIcon(status),
                                              const SizedBox(width: 4),
                                              Text(
                                                status.tenTiengViet,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusColor(status),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList();
                                      },
                                      items: TrangThaiDiemDanh.values
                                          .map((val) {
                                        return DropdownMenuItem(
                                          value: val,
                                          child: Row(
                                            children: [
                                              _getStatusIcon(val),
                                              const SizedBox(width: 8),
                                              Text(
                                                val.tenTiengViet,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: _getStatusColor(val),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !_isSaving ? _saveAttendance : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E60D5),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'LƯU ĐIỂM DANH',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsIndicator() {
    return Container(
      width: double.infinity,
      color: _isLoadingGps
          ? Colors.blue[50]
          : (_gpsHopLe ? Colors.green[50] : Colors.red[50]),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _isLoadingGps
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _gpsHopLe ? Icons.location_on : Icons.location_off,
                  color: _gpsHopLe ? Colors.green : Colors.red,
                  size: 20,
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoadingGps
                      ? 'Đang kiểm tra vị trí GPS của chủ lớp...'
                      : (_gpsHopLe
                          ? 'Đã xác minh vị trí: Hợp lệ'
                          : 'Lỗi vị trí: Khoảng cách quá xa (${_khoangCachMet.toStringAsFixed(1)}m)'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _isLoadingGps
                        ? Colors.blue[800]
                        : (_gpsHopLe ? Colors.green[800] : Colors.red[800]),
                  ),
                ),
                if (!_isLoadingGps)
                  Text(
                    'GPS hiện tại: ${_viTriHienTai?.latitude.toStringAsFixed(4)}, ${_viTriHienTai?.longitude.toStringAsFixed(4)} (Giới hạn < 100m)',
                    style: TextStyle(
                      fontSize: 11,
                      color: _gpsHopLe ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              if (_gpsHopLe) {
                _xacThucViTriGPS(
                  customLocation:
                      ViTri(latitude: 10.7800, longitude: 106.6500),
                );
              } else {
                _xacThucViTriGPS(
                  customLocation:
                      ViTri(latitude: 10.7725, longitude: 106.6578),
                );
              }
            },
            child: Text(
              _gpsHopLe ? 'Simulate Far' : 'Simulate Close',
              style: TextStyle(
                fontSize: 11,
                color: _gpsHopLe ? Colors.red[800] : Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TrangThaiDiemDanh status) {
    switch (status) {
      case TrangThaiDiemDanh.coMat:
        return Colors.green;
      case TrangThaiDiemDanh.diTre:
        return Colors.orange;
      case TrangThaiDiemDanh.vang:
        return Colors.red;
      case TrangThaiDiemDanh.coPhep:
        return Colors.blue;
    }
  }

  Widget _getStatusIcon(TrangThaiDiemDanh status) {
    switch (status) {
      case TrangThaiDiemDanh.coMat:
        return const Icon(Icons.check_circle, color: Colors.green, size: 16);
      case TrangThaiDiemDanh.diTre:
        return const Icon(Icons.alarm_on, color: Colors.orange, size: 16);
      case TrangThaiDiemDanh.vang:
        return const Icon(Icons.cancel, color: Colors.red, size: 16);
      case TrangThaiDiemDanh.coPhep:
        return const Icon(Icons.info, color: Colors.blue, size: 16);
    }
  }
}
