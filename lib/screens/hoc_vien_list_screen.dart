import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:excel/excel.dart';

import '../models/hoc_vien_model.dart';
import '../services/firebase_service.dart';

class HocVienListScreen extends StatefulWidget {
  final String maLop;
  const HocVienListScreen({super.key, required this.maLop});

  @override
  State<HocVienListScreen> createState() => _HocVienListScreenState();
}

class _HocVienListScreenState extends State<HocVienListScreen> {
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

  List<HocVien> _filter(List<HocVien> list) {
    List<HocVien> result;
    if (_query.isEmpty) {
      result = List.from(list);
    } else {
      result = list.where((hv) {
        return hv.maHocVien.toLowerCase().contains(_query) ||
            hv.hoTen.toLowerCase().contains(_query);
      }).toList();
    }

    // Sắp xếp theo tên (từ cuối cùng trong họ tên)
    result.sort((a, b) {
      String tenA = a.hoTen.trim().split(' ').last.toLowerCase();
      String tenB = b.hoTen.trim().split(' ').last.toLowerCase();
      return tenA.compareTo(tenB);
    });

    return result;
  }

  void _showHocVienFormDialog({HocVien? hocVien}) {
    final isEdit = hocVien != null;
    final maHVController = TextEditingController(text: hocVien?.maHocVien ?? '');
    final nameController = TextEditingController(text: hocVien?.hoTen ?? '');
    final emailController = TextEditingController(text: hocVien?.email ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        const dialogWidth = 320.0;
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
                      isEdit ? 'Chỉnh sửa học viên' : 'Thêm học viên mới',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: maHVController,
                      enabled: !isEdit,
                      decoration: const InputDecoration(labelText: 'Mã HV'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Họ và tên'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(100, 40),
                          ),
                          onPressed: () async {
                            if (maHVController.text.isEmpty ||
                                nameController.text.isEmpty ||
                                emailController.text.isEmpty) {
                              return;
                            }
                            final hv = HocVien(
                              maHocVien: maHVController.text.trim(),
                              hoTen: nameController.text.trim(),
                              email: emailController.text.trim(),
                              maLop: widget.maLop,
                              uidChuLop: _firebase.currentUid ?? '',
                              ngayThamGia: hocVien?.ngayThamGia ?? DateTime.now(),
                              trangThai: hocVien?.trangThai ?? 'Đang học',
                            );
                            try {
                              if (isEdit) {
                                await _firebase.capNhatHocVien(hv);
                              } else {
                                await _firebase.themHocVien(hv);
                              }
                              if (dialogContext.mounted) Navigator.pop(dialogContext);
                            } catch (e) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi lưu học viên: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(isEdit ? 'Cập nhật' : 'Thêm mới'),
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
  }

  void _confirmDeleteHocVien(HocVien hv) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa học viên ${hv.hoTen} (${hv.maHocVien}) khỏi lớp?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(100, 40),
              ),
              onPressed: () async {
                try {
                  await _firebase.xoaHocVien(hv.maHocVien);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi xóa học viên: $e'),
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

  Future<void> _importFromExcel() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Excel files',
        extensions: <String>['xlsx'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

      if (file != null) {
        var bytes = await file.readAsBytes();
        var excel = Excel.decodeBytes(bytes);
        
        int count = 0;
        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet == null) continue;
          
          bool isFirstRow = true;
          for (var row in sheet.rows) {
            if (isFirstRow) {
              isFirstRow = false; // Bỏ qua dòng tiêu đề
              continue;
            }
            
            if (row.length >= 3 && row[0] != null && row[1] != null && row[2] != null) {
              String maHV = row[0]!.value?.toString().trim() ?? '';
              String hoTen = row[1]!.value?.toString().trim() ?? '';
              String email = row[2]!.value?.toString().trim() ?? '';
              
              if (maHV.isNotEmpty && hoTen.isNotEmpty && email.isNotEmpty) {
                final hv = HocVien(
                  maHocVien: maHV,
                  hoTen: hoTen,
                  email: email,
                  maLop: widget.maLop,
                  uidChuLop: _firebase.currentUid ?? '',
                  ngayThamGia: DateTime.now(),
                  trangThai: 'Đang học',
                );
                try {
                  await _firebase.themHocVien(hv);
                  count++;
                } catch (e) {
                  // Bỏ qua nếu học viên đã tồn tại
                }
              }
            }
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã nhập thành công $count học viên!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đọc file Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.maLop,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Nhập từ Excel',
            onPressed: _importFromExcel,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => _showHocVienFormDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm học viên...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 40,
                  child: Text(
                    'STT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Mã HV',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Họ và tên',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Thao tác',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<HocVien>>(
              stream: _firebase.layDanhSachHocVien(widget.maLop),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                final filtered = _filter(snapshot.data ?? []);
                if (filtered.isEmpty) {
                  return const Center(child: Text('Không tìm thấy học viên.'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE9ECEF)),
                  itemBuilder: (context, index) {
                    final hv = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              hv.maHocVien,
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              hv.hoTen,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF212529),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      _showHocVienFormDialog(hocVien: hv),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  onPressed: () => _confirmDeleteHocVien(hv),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ],
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
