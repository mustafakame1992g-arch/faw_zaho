
import 'package:al_faw_zakho/core/services/analytics_service.dart';
import 'package:al_faw_zakho/data/local/local_database.dart';
import 'package:al_faw_zakho/presentation/widgets/error_screen.dart';
import 'package:al_faw_zakho/presentation/widgets/loading_screen.dart';
import 'package:flutter/material.dart';
import '/data/mock/mock_data_service.dart' as mock_service;

class OfficesScreen extends StatefulWidget {
  const OfficesScreen({super.key});

  @override
  State<OfficesScreen> createState() => _OfficesScreenState();
}

class _OfficesScreenState extends State<OfficesScreen> {
  List<dynamic> _offices = [];
  bool _isLoading = true;
  String? _error;
  //bool _usingMockData = false;

  @override
  void initState() {
    super.initState();
    _loadOffices();
    AnalyticsService.trackEvent('offices_screen_opened');
  }

  Future<void> _loadOffices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final localOffices = LocalDatabase.getOffices();
      
      if (localOffices.isNotEmpty) {
        setState(() {
          _offices = localOffices;
          _isLoading = false;
        });
        return;
      }

      await _loadMockData();

    } catch (e) {
      setState(() {
        _error = 'فشل تحميل المكاتب: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMockData() async {
    try {
      final mockData = await mock_service.AdvancedMockService.generateAndSaveMockData(
        officesCount: 8,
        saveToDatabase: true,
      );
      
      setState(() {
        _offices = mockData['offices'] ?? [];
        _isLoading = false;
        //_usingMockData = true;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل البيانات التجريبية';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المكاتب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOffices,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }



  Widget _buildBody() {
    if (_isLoading) return const LoadingScreen();
    if (_error != null) return ErrorScreen(error: _error!, onRetry: _loadOffices);
    if (_offices.isEmpty) return _buildEmptyState();

    return ListView.builder(
      itemCount: _offices.length,
      itemBuilder: (context, index) => _buildOfficeCard(_offices[index]),
    );
  }

  Widget _buildOfficeCard(dynamic office) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: const Icon(Icons.business, size: 40),
        title: Text(office.nameAr ?? 'مكتب'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(office.addressAr ?? 'عنوان غير محدد'),
            Text('المدير: ${office.managerNameAr ?? 'غير محدد'}'),
            Text('الهاتف: ${office.phoneNumber ?? 'غير متوفر'}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showOfficeDetails(office),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('لا توجد مكاتب متاحة'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadMockData,
            child: const Text('تحميل بيانات تجريبية'),
          ),
        ],
      ),
    );
  }

  void _showOfficeDetails(dynamic office) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(office.nameAr ?? 'مكتب'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('العنوان: ${office.addressAr ?? 'غير محدد'}'),
              Text('المدير: ${office.managerNameAr ?? 'غير محدد'}'),
              Text('الهاتف: ${office.phoneNumber ?? 'غير متوفر'}'),
              Text('البريد: ${office.email ?? 'غير متوفر'}'),
              Text('أوقات العمل: ${office.workingHours ?? 'غير محددة'}'),
              Text('المحافظة: ${office.province ?? 'غير محددة'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
