import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chu_lop_model.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebase = FirebaseService();
  ChuLop? _chuLop;
  int _soLop = 0;
  int _soBuoiHoc = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _debugFirebaseData();
    _loadHomeData();
  }

  Future<void> _debugFirebaseData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      debugPrint('==================================================');
      debugPrint('1. XÁC MINH FIREBASE PROJECT RUNTIME');
      debugPrint('Firebase projectId: ${Firebase.app().options.projectId}');
      debugPrint('Firebase appId: ${Firebase.app().options.appId}');
      debugPrint('Current UID: $uid');

      final db = FirebaseFirestore.instance;
      
      debugPrint('==================================================');
      debugPrint('2. ĐỌC TRỰC TIẾP KHÔNG FILTER');
      for (final collectionName in ['chulop', 'lophoc', 'hocvien', 'buoihoc', 'diemdanh']) {
        try {
          final snapshot = await db.collection(collectionName).get();
          debugPrint('[DEBUG FIRESTORE] $collectionName count = ${snapshot.docs.length}');
          for (final doc in snapshot.docs.take(3)) {
            debugPrint('[DEBUG FIRESTORE] $collectionName/${doc.id} fields = ${doc.data().keys.toList()}');
          }
        } catch (e, stackTrace) {
          debugPrint('[DEBUG FIRESTORE ERROR] $collectionName: $e');
        }
      }

      if (uid != null) {
        debugPrint('==================================================');
        debugPrint('3. SO SÁNH QUERY FILTER');
        for (final collectionName in ['lophoc', 'hocvien', 'buoihoc', 'diemdanh']) {
          try {
            final snapshot = await db.collection(collectionName).where('uidChuLop', isEqualTo: uid).get();
            debugPrint('[DEBUG FILTER] $collectionName by uid count = ${snapshot.docs.length}');
          } catch (e) {
            debugPrint('[DEBUG FILTER ERROR] $collectionName: $e');
          }
        }

        debugPrint('==================================================');
        debugPrint('4. KIỂM TRA DOCUMENT CHỦ LỚP');
        final ownerDoc = await db.collection('chulop').doc(uid).get();
        debugPrint('[DEBUG OWNER] exists = ${ownerDoc.exists}');
        debugPrint('[DEBUG OWNER] id = ${ownerDoc.id}');
        debugPrint('[DEBUG OWNER] fields = ${ownerDoc.data()?.keys.toList()}');
      }
      debugPrint('==================================================');
    } catch (e) {
      debugPrint('DEBUG ERROR: $e');
    }
  }

  Future<void> _loadHomeData() async {
    try {
      ChuLop? cl;
      String? currentUid;
      if (FirebaseService.useMock) {
        currentUid = 'mock-uid';
        cl = await _firebase.layThongTinChuLop(currentUid);
      } else {
        currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid != null) {
          cl = await _firebase.layThongTinChuLop(currentUid);
        }
      }
      final lopList = await _firebase.layDanhSachLopHoc().first;
      
      int soBuoi = 0;
      if (currentUid != null) {
        final buoiHocSnap = await FirebaseFirestore.instance
            .collection('buoihoc')
            .where('uidChuLop', isEqualTo: currentUid)
            .get();
            
        final now = DateTime.now();
        soBuoi = buoiHocSnap.docs.where((doc) {
          final data = doc.data();
          if (data['ngayHoc'] != null) {
            final ngayHoc = (data['ngayHoc'] as Timestamp).toDate();
            return ngayHoc.year == now.year &&
                   ngayHoc.month == now.month &&
                   ngayHoc.day == now.day;
          }
          return false;
        }).length;
      }
      
      if (!mounted) return;
      setState(() {
        _chuLop = cl;
        _soLop = lopList.length;
        _soBuoiHoc = soBuoi;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Firestore query failed in _loadHomeData: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _dangXuat() async {
    await _firebase.dangXuat();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final tenHienThi = _chuLop?.hoTen ??
        (FirebaseService.useMock ? 'Chủ lớp (Thử nghiệm)' : FirebaseAuth.instance.currentUser?.email ?? 'Chủ lớp');

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
          'Trang chủ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _dangXuat,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.blue[50],
                            child: const Icon(
                              Icons.person,
                              size: 36,
                              color: Color(0xFF1E60D5),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Xin chào, $tenHienThi',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B2E3C),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _chuLop?.email ?? (FirebaseService.useMock ? "minhanh.tutor@example.com" : FirebaseAuth.instance.currentUser?.email ?? ""),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tổng quan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2E3C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.school_outlined,
                            label: 'Lớp học',
                            value: '$_soLop',
                            color: Colors.blue[50]!,
                            iconColor: const Color(0xFF1E60D5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.calendar_today_outlined,
                            label: 'Buổi hôm nay',
                            value: '$_soBuoiHoc',
                            color: Colors.green[50]!,
                            iconColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Hướng dẫn nhanh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2E3C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFunctionTile(
                      icon: Icons.list_alt,
                      title: 'Quản lý lớp ở tab Lớp học (đồng bộ Firestore)',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuickGuideScreen(
                              title: 'Quản lý lớp',
                              content: 'Ở tab "Lớp học", bạn có thể xem toàn bộ danh sách lớp của mình. Nhấn nút "+" để thêm lớp mới. Khi bạn thao tác, dữ liệu sẽ tự động đồng bộ lưu trữ trên đám mây an toàn qua Firestore.',
                            ),
                          ),
                        );
                      },
                    ),
                    _buildFunctionTile(
                      icon: Icons.people,
                      title: 'Thêm học viên trong từng lớp',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuickGuideScreen(
                              title: 'Thêm học viên',
                              content: 'Trong giao diện chi tiết của mỗi lớp học, hãy chuyển sang tab "Học viên" và nhấn "Thêm học viên". Việc này giúp bạn dễ dàng theo dõi số lượng và thông tin học viên của lớp.',
                            ),
                          ),
                        );
                      },
                    ),
                    _buildFunctionTile(
                      icon: Icons.check_box_outlined,
                      title: 'Điểm danh học viên, lưu tự động',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuickGuideScreen(
                              title: 'Điểm danh',
                              content: 'Chuyển sang tab "Điểm danh" ở thanh menu dưới cùng. Chọn Lớp và Buổi học tương ứng, danh sách học viên sẽ hiện ra. Đánh dấu tình trạng điểm danh (Có mặt, Vắng, Đi trễ) và dữ liệu sẽ tự động được lưu.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2E3C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1E60D5), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF495057),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }
}

class QuickGuideScreen extends StatelessWidget {
  final String title;
  final String content;

  const QuickGuideScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hướng dẫn',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2E3C),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF495057),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E60D5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Đã hiểu', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
