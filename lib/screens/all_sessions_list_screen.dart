import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/buoi_hoc_model.dart';
import '../services/firebase_service.dart';
import 'attendance_screen.dart';

class AllSessionsListScreen extends StatefulWidget {
  const AllSessionsListScreen({super.key});

  @override
  State<AllSessionsListScreen> createState() => _AllSessionsListScreenState();
}

class _AllSessionsListScreenState extends State<AllSessionsListScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid ?? (FirebaseService.useMock ? 'mock-uid' : null);

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('buoihoc')
            .where('uidChuLop', isEqualTo: _uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Note: If orderBy('ngayHoc') requires an index and it's missing, it will throw an error.
            // In that case, we can fallback to fetching and sorting in Dart, but let's assume it works or we don't order in DB.
            // Actually, to be safe from missing index, let's remove orderBy in DB and sort in Dart.
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có lịch học nào.'));
          }

          final sessions = docs.map((d) => BuoiHoc.fromMap(d.data() as Map<String, dynamic>)).toList();
          
          // Sort ascending by date and then by time
          sessions.sort((a, b) {
            int dateCompare = a.ngayHoc.compareTo(b.ngayHoc);
            if (dateCompare != 0) return dateCompare;
            return a.gioBatDau.compareTo(b.gioBatDau);
          });

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
                    'Lớp ${session.maLop}',
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
    );
  }
}
