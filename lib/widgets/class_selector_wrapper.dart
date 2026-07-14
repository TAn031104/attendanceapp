import 'package:flutter/material.dart';
import '../models/lop_hoc_model.dart';
import '../models/buoi_hoc_model.dart';
import '../services/firebase_service.dart';

class ClassSelectorWrapper extends StatefulWidget {
  final Widget Function(String maLop, String? maBuoiHoc) builder;
  final bool requireSession;
  final bool allowAllSessions;
  final String title;

  const ClassSelectorWrapper({
    super.key,
    required this.builder,
    this.requireSession = false,
    this.allowAllSessions = false,
    required this.title,
  });

  @override
  State<ClassSelectorWrapper> createState() => _ClassSelectorWrapperState();
}

class _ClassSelectorWrapperState extends State<ClassSelectorWrapper> {
  final FirebaseService _firebase = FirebaseService();
  String? _selectedLop;
  String? _selectedBuoi;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StreamBuilder<List<LopHoc>>(
                  stream: _firebase.layDanhSachLopHoc(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final classes = snapshot.data ?? [];
                    if (classes.isEmpty) {
                      return const Text('Bạn chưa có lớp học nào.', style: TextStyle(color: Colors.red));
                    }
                    
                    if (_selectedLop == null && classes.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedLop = classes.first.maLop);
                      });
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedLop,
                      decoration: const InputDecoration(
                        labelText: 'Chọn lớp học',
                        border: OutlineInputBorder(),
                      ),
                      items: classes.map((lop) {
                        return DropdownMenuItem(
                          value: lop.maLop,
                          child: Text('${lop.tenLop} (${lop.maLop})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedLop = val;
                          _selectedBuoi = null;
                        });
                      },
                    );
                  },
                ),
                if (widget.requireSession && _selectedLop != null) ...[
                  const SizedBox(height: 16),
                  StreamBuilder<List<BuoiHoc>>(
                    stream: _firebase.layDanhSachBuoiHoc(_selectedLop!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final sessions = snapshot.data ?? [];
                      if (sessions.isEmpty) {
                        return const Text('Lớp này chưa có buổi học nào.', style: TextStyle(color: Colors.red));
                      }
                      
                      if (_selectedBuoi == null) {
                        if (widget.allowAllSessions) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _selectedBuoi = 'ALL_SESSIONS');
                          });
                        } else if (sessions.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _selectedBuoi = sessions.first.maBuoiHoc);
                          });
                        }
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedBuoi,
                        decoration: const InputDecoration(
                          labelText: 'Chọn buổi học',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          if (widget.allowAllSessions)
                            const DropdownMenuItem(
                              value: 'ALL_SESSIONS',
                              child: Text('Tất cả buổi học'),
                            ),
                          ...sessions.map((buoi) {
                            return DropdownMenuItem(
                              value: buoi.maBuoiHoc,
                              child: Text(buoi.maBuoiHoc),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedBuoi = val);
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: (_selectedLop == null || (widget.requireSession && _selectedBuoi == null))
                ? const Center(child: Text('Vui lòng chọn đầy đủ thông tin bên trên.'))
                : widget.builder(_selectedLop!, _selectedBuoi == 'ALL_SESSIONS' ? null : _selectedBuoi),
          ),
        ],
      ),
    );
  }
}
