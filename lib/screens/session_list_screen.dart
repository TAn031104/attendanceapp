import 'package:flutter/material.dart';

import '../models/buoi_hoc_model.dart';
import '../models/vi_tri_model.dart';
import '../services/firebase_service.dart';
import 'attendance_screen.dart';

class SessionListScreen extends StatefulWidget {
  final String maLop;
  const SessionListScreen({super.key, required this.maLop});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  final FirebaseService _firebase = FirebaseService();
  static final ViTri _defaultLocation =
      ViTri(latitude: 10.7725, longitude: 106.6578);

  void _showScheduleFormDialog() {
    final diaDiemController = TextEditingController(text: 'Phòng A101');
    final gioBatDauController = TextEditingController(text: '18:00');
    final gioKetThucController = TextEditingController(text: '20:00');
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    final Map<int, bool> selectedDays = {
      DateTime.monday: false,
      DateTime.tuesday: false,
      DateTime.wednesday: false,
      DateTime.thursday: false,
      DateTime.friday: false,
      DateTime.saturday: false,
      DateTime.sunday: false,
    };

    final dayNames = {
      DateTime.monday: 'Thứ 2',
      DateTime.tuesday: 'Thứ 3',
      DateTime.wednesday: 'Thứ 4',
      DateTime.thursday: 'Thứ 5',
      DateTime.friday: 'Thứ 6',
      DateTime.saturday: 'Thứ 7',
      DateTime.sunday: 'Chủ Nhật',
    };

    showDialog(
      context: context,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final dialogWidth = screenWidth > 450 ? 400.0 : screenWidth * 0.9;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Tạo lịch học tự động'),
              content: SizedBox(
                width: dialogWidth,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: gioBatDauController,
                        decoration: const InputDecoration(labelText: 'Giờ bắt đầu'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: gioKetThucController,
                        decoration: const InputDecoration(labelText: 'Giờ kết thúc'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: diaDiemController,
                        decoration: const InputDecoration(labelText: 'Địa điểm (áp dụng chung)'),
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Thời gian áp dụng:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Từ: '),
                          TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: dialogContext,
                                initialDate: startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) setDialogState(() => startDate = date);
                            },
                            child: Text('${startDate.day}/${startDate.month}/${startDate.year}'),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Đến: '),
                          TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: dialogContext,
                                initialDate: endDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) setDialogState(() => endDate = date);
                            },
                            child: Text('${endDate.day}/${endDate.month}/${endDate.year}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Lặp lại vào các ngày:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: selectedDays.keys.map((day) {
                          return FilterChip(
                            label: Text(dayNames[day]!, style: const TextStyle(fontSize: 12)),
                            selected: selectedDays[day]!,
                            onSelected: (bool selected) {
                              setDialogState(() {
                                selectedDays[day] = selected;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!selectedDays.values.any((e) => e)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ngày trong tuần!')),
                      );
                      return;
                    }
                    if (startDate.isAfter(endDate)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu!')),
                      );
                      return;
                    }

                    List<BuoiHoc> dsBuoi = [];
                    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
                    DateTime end = DateTime(endDate.year, endDate.month, endDate.day);
                    
                    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
                      if (selectedDays[current.weekday] == true) {
                        final buoi = BuoiHoc(
                          maBuoiHoc: '${widget.maLop}_B${current.millisecondsSinceEpoch}',
                          maLop: widget.maLop,
                          uidChuLop: _firebase.currentUid ?? '',
                          ngayHoc: current,
                          gioBatDau: gioBatDauController.text.trim(),
                          gioKetThuc: gioKetThucController.text.trim(),
                          diaDiem: diaDiemController.text.trim(),
                          viTriLop: _defaultLocation,
                          trangThai: 'Sắp diễn ra',
                        );
                        dsBuoi.add(buoi);
                      }
                      current = current.add(const Duration(days: 1));
                    }

                    if (dsBuoi.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Không có ngày nào thỏa mãn.')),
                      );
                      return;
                    }

                    try {
                      await _firebase.themNhieuBuoiHoc(dsBuoi);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Đã tạo ${dsBuoi.length} buổi học!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Lỗi tạo lịch: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Tạo lịch'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSessionFormDialog({BuoiHoc? session}) {
    final isEdit = session != null;
    final maBuoiController = TextEditingController(
      text: session?.maBuoiHoc ?? '${widget.maLop}_B${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
    final diaDiemController =
        TextEditingController(text: session?.diaDiem ?? 'Phòng A101');
    final gioBatDauController =
        TextEditingController(text: session?.gioBatDau ?? '18:00');
    final gioKetThucController =
        TextEditingController(text: session?.gioKetThuc ?? '20:00');
    DateTime selectedDate = session?.ngayHoc ?? DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final dialogWidth = screenWidth > 450 ? 400.0 : screenWidth * 0.9;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Chỉnh sửa buổi học' : 'Tạo buổi học mới'),
              content: SizedBox(
                width: dialogWidth,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: maBuoiController,
                        enabled: !isEdit,
                        decoration: const InputDecoration(labelText: 'Mã buổi học'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: gioBatDauController,
                        decoration: const InputDecoration(labelText: 'Giờ bắt đầu'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: gioKetThucController,
                        decoration: const InputDecoration(labelText: 'Giờ kết thúc'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: diaDiemController,
                        decoration: const InputDecoration(labelText: 'Địa điểm'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ngày: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setDialogState(() => selectedDate = date);
                              }
                            },
                            child: const Text('Chọn ngày'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final buoi = BuoiHoc(
                      maBuoiHoc: maBuoiController.text.trim(),
                      maLop: widget.maLop,
                      uidChuLop: _firebase.currentUid ?? '',
                      ngayHoc: selectedDate,
                      gioBatDau: gioBatDauController.text.trim(),
                      gioKetThuc: gioKetThucController.text.trim(),
                      diaDiem: diaDiemController.text.trim(),
                      viTriLop: session?.viTriLop ?? _defaultLocation,
                      trangThai: session?.trangThai ?? 'Sắp diễn ra',
                    );
                    try {
                      if (isEdit) {
                        await _firebase.capNhatBuoiHoc(buoi);
                      } else {
                        await _firebase.themBuoiHoc(buoi);
                      }
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi lưu buổi học: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isEdit ? 'Cập nhật' : 'Tạo mới'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSession(BuoiHoc session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có muốn xóa ${session.maBuoiHoc.toUpperCase()}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await _firebase.xoaBuoiHoc(session.maBuoiHoc);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi xóa buổi học: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Buổi học - ${widget.maLop}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Tạo lịch tự động',
            onPressed: () => _showScheduleFormDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<BuoiHoc>>(
        stream: _firebase.layDanhSachBuoiHoc(widget.maLop),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const Center(child: Text('Chưa có buổi học.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final ngayFormat =
                  '${session.ngayHoc.day.toString().padLeft(2, '0')}/${session.ngayHoc.month.toString().padLeft(2, '0')}/${session.ngayHoc.year}';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF1E60D5),
                      size: 26,
                    ),
                  ),
                  title: Text(
                    'Buổi #${session.maBuoiHoc.split('_').last}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2E3C),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lớp ${session.maLop}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(ngayFormat, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(width: 12),
                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text('${session.gioBatDau} - ${session.gioKetThuc}', 
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]), 
                                  overflow: TextOverflow.ellipsis
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.room, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(session.diaDiem,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                        onPressed: () => _showSessionFormDialog(session: session),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => _confirmDeleteSession(session),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceScreen(
                          maBuoiHoc: session.maBuoiHoc,
                          maLop: session.maLop,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
