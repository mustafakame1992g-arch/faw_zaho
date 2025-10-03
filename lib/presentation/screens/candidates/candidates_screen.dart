
// lib/presentation/screens/candidates/candidates_screen.dart
import 'package:al_faw_zakho/presentation/widgets/error_screen.dart';
import 'package:al_faw_zakho/presentation/widgets/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/services/analytics_service.dart';
import '/data/local/local_database.dart';
import '/data/mock/mock_data_service.dart' as mock_service;
import '/core/providers/connectivity_provider.dart';
import '/presentation/screens/candidates/widgets/candidate_card.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key});

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  List<dynamic> _candidates = [];
  bool _isLoading = true;
  String? _error;
  bool _usingMockData = false;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
    AnalyticsService.trackEvent('candidates_screen_opened');
  }

  Future<void> _loadCandidates() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _usingMockData = false;
      });

      final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
      
      // محاولة تحميل البيانات المحلية أولاً
      final localCandidates = LocalDatabase.getCandidates();
      
      if (localCandidates.isNotEmpty) {
        setState(() {
          _candidates = localCandidates;
          _isLoading = false;
        });
        return;
      }

      // إذا لا يوجد بيانات محلية، استخدام Mock Data
      if (!connectivity.isOnline) {
        await _loadMockData();
        return;
      }

      // محاكاة تحميل من API (سيتم استبدالها لاحقاً)
      await Future.delayed(const Duration(seconds: 2));
      
      // إذا فشل التحميل، استخدام Mock Data كحل بديل
      await _loadMockData();

    } catch (e) {
      AnalyticsService.trackError('load_candidates', e, StackTrace.current);
      setState(() {
        _error = 'فشل تحميل البيانات: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMockData() async {
    try {
      final mockData = await mock_service.AdvancedMockService.generateAndSaveMockData(
        candidatesCount: 15,
        saveToDatabase: true,
      );
      
      setState(() {
        _candidates = mockData['candidates'] ?? [];
        _isLoading = false;
        _usingMockData = true;
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
        title: const Text('المرشحين'),
        actions: [
          if (_usingMockData) 
            const Tooltip(
              message: 'بيانات تجريبية',
              child: Icon(Icons.science, color: Colors.orange),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCandidates,
            tooltip: 'إعادة التحميل',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingScreen(progress: 0.5);
    }

    if (_error != null) {
      return ErrorScreen(
        error: _error!,
        onRetry: _loadCandidates,
      );
    }

    if (_candidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('لا يوجد مرشحين متاحين حالياً'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadMockData,
              child: const Text('تحميل بيانات تجريبية'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // شريط المعلومات
        if (_usingMockData)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange[50],
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                SizedBox(width: 4),
                Text('عرض بيانات تجريبية', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        
        // قائمة المرشحين
        Expanded(
          child: ListView.builder(
            itemCount: _candidates.length,
            itemBuilder: (context, index) {
              final candidate = _candidates[index];
              return CandidateCard(
                candidate: candidate,
                onTap: () => _showCandidateDetails(candidate),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCandidateDetails(dynamic candidate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(candidate.nameAr ?? 'مرشح'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (candidate.imageUrl != null && candidate.imageUrl!.isNotEmpty)
                Image.asset(
                  candidate.imageUrl!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 100),
                ),
              const SizedBox(height: 10),
              Text('المنصب: ${candidate.positionAr ?? 'غير محدد'}'),
              Text('المحافظة: ${candidate.province ?? 'غير محدد'}'),
              if (candidate.phoneNumber != null) 
                Text('الهاتف: ${candidate.phoneNumber}'),
              const SizedBox(height: 10),
              Text('السيرة الذاتية: ${candidate.bioAr ?? 'غير متوفرة'}'),
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


