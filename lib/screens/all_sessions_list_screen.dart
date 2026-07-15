import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/buoi_hoc_model.dart';
import '../models/lop_hoc_model.dart';
import '../services/firebase_service.dart';
import 'attendance_screen.dart';

class AllSessionsListScreen extends StatefulWidget {
  const AllSessionsListScreen({super.key});

  @override
  State<AllSessionsListScreen> createState() => _AllSessionsListScreenState();
}

class _AllSessionsListScreenState extends State<AllSessionsListScreen> {
  final FirebaseService _firebase = FirebaseService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid ?? (FirebaseService.useMock ? 'mock-uid' : null);

  String _selectedClassId = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: const Text(
          'Tất cả lịch học',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<LopHoc>>(
        stream: _firebase.layDanhSachLopHoc(),
        builder: (context, classSnapshot) {
          if (classSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnapshot.hasError) {
            return Center(child: Text('Lỗi tải lớp học: ${classSnapshot.error}'));
          }

          final classes = classSnapshot.data ?? [];
          final classMap = {for (var c in classes) c.maLop: c};

          // Defensive check in case selected class is not in the list (e.g. account switch or deletion)
          final activeSelectedClass = classes.any((lop) => lop.maLop == _selectedClassId)
              ? _selectedClassId
              : '';

          return Column(
            children: [
              // Thanh lọc và tìm kiếm hiện đại
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm buổi học...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: activeSelectedClass.isEmpty ? '' : activeSelectedClass,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.school_outlined, color: Colors.grey),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('Tất cả các lớp'),
                              ),
                              ...classes.map((lop) {
                                return DropdownMenuItem<String>(
                                  value: lop.maLop,
                                  child: Text(
                                    '${lop.tenLop} (${lop.maLop})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedClassId = value ?? '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.calendar_month_outlined, color: Colors.grey),
                                suffixIcon: _selectedDate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                        onPressed: () {
                                          setState(() {
                                            _selectedDate = null;
                                          });
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              child: Text(
                                _selectedDate == null
                                    ? 'Chọn ngày học'
                                    : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                                style: TextStyle(
                                  color: _selectedDate == null ? Colors.grey[600] : Colors.black,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Danh sách buổi học
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('buoihoc')
                      .where('uidChuLop', isEqualTo: _uid)
                      .snapshots(),
                  builder: (context, sessionSnapshot) {
                    if (sessionSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (sessionSnapshot.hasError) {
                      return Center(child: Text('Lỗi: ${sessionSnapshot.error}'));
                    }
                    final docs = sessionSnapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('Chưa có lịch học nào.'));
                    }

                    final sessions = docs
                        .map((d) => BuoiHoc.fromMap(d.data() as Map<String, dynamic>))
                        .toList();

                    // Sort ascending by date and then by time
                    sessions.sort((a, b) {
                      int dateCompare = a.ngayHoc.compareTo(b.ngayHoc);
                      if (dateCompare != 0) return dateCompare;
                      return a.gioBatDau.compareTo(b.gioBatDau);
                    });

                    // Lọc theo lớp học, ngày học và tìm kiếm trong Dart
                    final filteredSessions = sessions.where((session) {
                      // 1. Lọc theo lớp học được chọn
                      if (activeSelectedClass.isNotEmpty && session.maLop != activeSelectedClass) {
                        return false;
                      }

                      // 2. Lọc theo ngày được chọn
                      if (_selectedDate != null) {
                        final sameDay = session.ngayHoc.year == _selectedDate!.year &&
                            session.ngayHoc.month == _selectedDate!.month &&
                            session.ngayHoc.day == _selectedDate!.day;
                        if (!sameDay) return false;
                      }

                      // 3. Lọc theo chuỗi tìm kiếm
                      if (_searchQuery.isNotEmpty) {
                        final query = _searchQuery.toLowerCase().trim();
                        final className = classMap[session.maLop]?.tenLop.toLowerCase() ?? '';
                        final classId = session.maLop.toLowerCase();
                        final diaDiem = session.diaDiem.toLowerCase();
                        final content = session.noiDungBuoiHoc?.toLowerCase() ?? '';
                        final ngayFormat =
                            '${session.ngayHoc.day.toString().padLeft(2, '0')}/${session.ngayHoc.month.toString().padLeft(2, '0')}/${session.ngayHoc.year}';

                        return className.contains(query) ||
                            classId.contains(query) ||
                            diaDiem.contains(query) ||
                            content.contains(query) ||
                            ngayFormat.contains(query);
                      }
                      return true;
                    }).toList();

                    if (filteredSessions.isEmpty) {
                      return const Center(child: Text('Không tìm thấy buổi học nào.'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
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
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.fact_check_outlined,
                                color: Colors.green,
                                size: 26,
                              ),
                            ),
                            title: Text(
                              classMap[session.maLop] != null
                                  ? '${classMap[session.maLop]!.tenLop} (${session.maLop})'
                                  : 'Lớp ${session.maLop}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B2E3C),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month,
                                        size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(ngayFormat,
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey[600])),
                                    const SizedBox(width: 12),
                                    Icon(Icons.access_time,
                                        size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text('${session.gioBatDau} - ${session.gioKetThuc}',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey[600])),
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
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
