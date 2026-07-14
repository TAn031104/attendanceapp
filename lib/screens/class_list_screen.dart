import 'package:flutter/material.dart';

import '../models/lop_hoc_model.dart';
import '../services/firebase_service.dart';
import 'session_list_screen.dart';
import 'hoc_vien_list_screen.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final FirebaseService _firebase = FirebaseService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LopHoc> _filter(List<LopHoc> list) {
    if (_query.isEmpty) return list;
    return list.where((lop) {
      return lop.maLop.toLowerCase().contains(_query) ||
          lop.tenLop.toLowerCase().contains(_query);
    }).toList();
  }

  void _showClassFormDialog({LopHoc? lopHoc}) {
    final isEdit = lopHoc != null;
    final maLopController = TextEditingController(text: lopHoc?.maLop ?? '');
    final tenLopController = TextEditingController(text: lopHoc?.tenLop ?? '');
    final monHocController = TextEditingController(text: lopHoc?.monHoc ?? '');
    final hocPhiController = TextEditingController(text: lopHoc?.hocPhi.toString() ?? '0');
    final siSoController = TextEditingController(text: lopHoc?.siSoToiDa.toString() ?? '20');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final dialogWidth = screenWidth > 450 ? 400.0 : screenWidth * 0.9;
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                width: dialogWidth,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isEdit ? 'Chỉnh sửa thông tin lớp' : 'Thêm lớp học mới',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: maLopController,
                          enabled: !isEdit && !isSaving,
                          decoration: const InputDecoration(labelText: 'Mã lớp'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: tenLopController,
                          enabled: !isSaving,
                          decoration: const InputDecoration(labelText: 'Tên lớp'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: monHocController,
                          enabled: !isSaving,
                          decoration: const InputDecoration(labelText: 'Môn học'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: hocPhiController,
                          enabled: !isSaving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Học phí (VND)'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: siSoController,
                          enabled: !isSaving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Sĩ số tối đa'),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (maLopController.text.isEmpty ||
                                          tenLopController.text.isEmpty ||
                                          monHocController.text.isEmpty) {
                                        return;
                                      }
                                      setStateDialog(() => isSaving = true);
                                      final lop = LopHoc(
                                        maLop: maLopController.text.trim(),
                                        tenLop: tenLopController.text.trim(),
                                        monHoc: monHocController.text.trim(),
                                        uidChuLop: _firebase.currentUid ?? '',
                                        hocPhi: double.tryParse(hocPhiController.text) ?? 0,
                                        siSoToiDa: int.tryParse(siSoController.text) ?? 20,
                                        donViHocPhi: 'tháng',
                                        ngayBatDau: lopHoc?.ngayBatDau ?? DateTime.now(),
                                        trangThai: lopHoc?.trangThai ?? 'Đang hoạt động',
                                        ngayTao: lopHoc?.ngayTao ?? DateTime.now(),
                                      );
                                      try {
                                        if (isEdit) {
                                          await _firebase.capNhatLopHoc(lop);
                                        } else {
                                          await _firebase.themLopHoc(lop);
                                        }
                                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                                      } catch (e) {
                                        setStateDialog(() => isSaving = false);
                                        if (dialogContext.mounted) {
                                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                                            SnackBar(
                                              content: Text('Lỗi lưu lớp: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(isEdit ? 'Cập nhật' : 'Thêm mới'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteClass(LopHoc lopHoc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa lớp ${lopHoc.maLop} - ${lopHoc.tenLop}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await _firebase.xoaLopHoc(lopHoc.maLop);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi xóa lớp: $e'),
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
        title: const Text(
          'Danh sách lớp',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showClassFormDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm lớp học...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LopHoc>>(
              stream: _firebase.layDanhSachLopHoc(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Không tải được lớp học.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final filtered = _filter(snapshot.data ?? []);
                if (filtered.isEmpty) {
                  return const Center(child: Text('Không tìm thấy lớp học.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final lop = filtered[index];
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.folder_shared_outlined,
                            color: Color(0xFF1E60D5),
                            size: 26,
                          ),
                        ),
                        title: Text(
                          lop.maLop,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E3C),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              lop.tenLop,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lop.monHoc,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'edit') {
                              _showClassFormDialog(lopHoc: lop);
                            } else if (action == 'delete') {
                              _confirmDeleteClass(lop);
                            } else if (action == 'students') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      HocVienListScreen(maLop: lop.maLop),
                                ),
                              );
                            } else if (action == 'sessions') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SessionListScreen(maLop: lop.maLop),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'students',
                              child: Row(
                                children: [
                                  Icon(Icons.people_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text('Danh sách Học viên'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'sessions',
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 20),
                                  SizedBox(width: 8),
                                  Text('Buổi học'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Chỉnh sửa'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Xóa lớp',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HocVienListScreen(maLop: lop.maLop),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
