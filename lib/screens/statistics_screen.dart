import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';

class StatisticsScreen extends StatefulWidget {
  final String maLop;
  final String? maBuoiHoc;
  const StatisticsScreen({super.key, required this.maLop, this.maBuoiHoc});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirebaseService _firebase = FirebaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _thongKe;

  String _selectedSession = 'Tất cả buổi';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _firebase.thongKeLopHoc(widget.maLop, maBuoiHoc: widget.maBuoiHoc);
      if (!mounted) return;
      setState(() {
        _thongKe = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải thống kê: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int tongSoBuoi = _thongKe?['tongSoBuoi'] ?? 0;
    int coMat = _thongKe?['coMat'] ?? 0;
    int diTre = _thongKe?['diTre'] ?? 0;
    int coPhep = _thongKe?['coPhep'] ?? 0;
    int vang = _thongKe?['vang'] ?? 0;
    int tongDiemDanh = coMat + diTre + vang + coPhep;

    double percentCoMat = tongDiemDanh > 0 ? (coMat / tongDiemDanh) * 100 : 0;
    double percentVang = tongDiemDanh > 0 ? (vang / tongDiemDanh) * 100 : 0;
    double percentDiTre = tongDiemDanh > 0 ? (diTre / tongDiemDanh) * 100 : 0;
    double percentCoPhep = tongDiemDanh > 0 ? (coPhep / tongDiemDanh) * 100 : 0;

    List<Map<String, dynamic>> studentRates = _thongKe?['studentRates'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Thống kê - ${widget.maLop}${widget.maBuoiHoc == null ? '' : ' - ${widget.maBuoiHoc}'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [


                    // 2. Grid các hộp số liệu tổng quan
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                      children: [
                        _buildSummaryCard(
                          title: 'Có mặt',
                          value: '$coMat',
                          subtext: '(${percentCoMat.toStringAsFixed(0)}%)',
                          borderColor: Colors.green[300]!,
                          bgColor: Colors.green[50]!,
                          textColor: Colors.green[800]!,
                        ),
                        _buildSummaryCard(
                          title: 'Đi trễ',
                          value: '$diTre',
                          subtext: '(${percentDiTre.toStringAsFixed(0)}%)',
                          borderColor: Colors.orange[300]!,
                          bgColor: Colors.orange[50]!,
                          textColor: Colors.orange[800]!,
                        ),
                        _buildSummaryCard(
                          title: 'Có phép',
                          value: '$coPhep',
                          subtext: '(${percentCoPhep.toStringAsFixed(0)}%)',
                          borderColor: Colors.blue[300]!,
                          bgColor: Colors.blue[50]!,
                          textColor: Colors.blue[800]!,
                        ),
                        _buildSummaryCard(
                          title: 'Vắng',
                          value: '$vang',
                          subtext: '(${percentVang.toStringAsFixed(0)}%)',
                          borderColor: Colors.red[300]!,
                          bgColor: Colors.red[50]!,
                          textColor: Colors.red[800]!,
                        ),
                        _buildSummaryCard(
                          title: 'Tổng buổi học',
                          value: '$tongSoBuoi',
                          subtext: '',
                          borderColor: Colors.grey[300]!,
                          bgColor: Colors.grey[50]!,
                          textColor: Colors.grey[800]!,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 3. Phần tỷ lệ tổng quan (Pie Chart)
                    const Text(
                      'Tỷ lệ tổng quan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2E3C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: SizedBox(
                              height: 140,
                              child: tongDiemDanh == 0
                                  ? const Center(
                                      child: Text('Chưa có\ndữ liệu',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)))
                                  : PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 35,
                                        sections: [
                                          if (percentCoMat > 0)
                                            PieChartSectionData(
                                              color: Colors.green,
                                              value: percentCoMat,
                                              title:
                                                  '${percentCoMat.toStringAsFixed(0)}%',
                                              radius: 40,
                                              titleStyle: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                          if (percentVang > 0)
                                            PieChartSectionData(
                                              color: Colors.red,
                                              value: percentVang,
                                              title:
                                                  '${percentVang.toStringAsFixed(0)}%',
                                              radius: 40,
                                              titleStyle: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                          if (percentDiTre > 0)
                                            PieChartSectionData(
                                              color: Colors.orange,
                                              value: percentDiTre,
                                              title:
                                                  '${percentDiTre.toStringAsFixed(0)}%',
                                              radius: 40,
                                              titleStyle: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                          if (percentCoPhep > 0)
                                            PieChartSectionData(
                                              color: Colors.blue,
                                              value: percentCoPhep,
                                              title:
                                                  '${percentCoPhep.toStringAsFixed(0)}%',
                                              radius: 40,
                                              titleStyle: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendRow(
                                    'Có mặt (${percentCoMat.toStringAsFixed(0)}%)',
                                    Colors.green),
                                const SizedBox(height: 8),
                                _buildLegendRow(
                                    'Đi trễ (${percentDiTre.toStringAsFixed(0)}%)',
                                    Colors.orange),
                                const SizedBox(height: 8),
                                _buildLegendRow(
                                    'Có phép (${percentCoPhep.toStringAsFixed(0)}%)',
                                    Colors.blue),
                                const SizedBox(height: 8),
                                _buildLegendRow(
                                    'Vắng (${percentVang.toStringAsFixed(0)}%)',
                                    Colors.red),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 4. Phần tỷ lệ chuyên cần theo học viên
                    const Text(
                      'Tỷ lệ chuyên cần theo học viên',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2E3C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: studentRates.isEmpty
                          ? const Center(
                              child: Text('Chưa có dữ liệu học viên',
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: studentRates.length,
                              itemBuilder: (context, index) {
                                final sv = studentRates[index];
                                double value = sv['rate'];
                                String phanTram =
                                    '${(value * 100).toInt()}%';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            sv['name'],
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF495057)),
                                          ),
                                          Text(
                                            phanTram,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: value,
                                          minHeight: 10,
                                          backgroundColor: Colors.grey[200],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            value >= 0.90
                                                ? Colors.green
                                                : (value >= 0.80
                                                    ? Colors.blue
                                                    : Colors.orange),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtext,
    required Color borderColor,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (subtext.isNotEmpty) const SizedBox(width: 4),
              if (subtext.isNotEmpty)
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF495057),
          ),
        ),
      ],
    );
  }
}
