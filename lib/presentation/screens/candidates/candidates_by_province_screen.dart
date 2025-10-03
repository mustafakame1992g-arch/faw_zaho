// lib/presentation/screens/candidates/candidates_by_province_screen.dart
import 'package:al_faw_zakho/core/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/services/analytics_service.dart';
import '/data/local/local_database.dart';
import '/data/models/candidate_model.dart';
import '/presentation/screens/candidates/candidate_details_screen.dart';

class CandidatesByProvinceScreen extends StatefulWidget {
  final String province;

  const CandidatesByProvinceScreen({
    super.key,
    required this.province,
  });

  @override
  State<CandidatesByProvinceScreen> createState() => _CandidatesByProvinceScreenState();
}

class _CandidatesByProvinceScreenState extends State<CandidatesByProvinceScreen> {
  List<CandidateModel> _candidates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
    AnalyticsService.trackEvent('candidates_by_province_opened', parameters: {
      'province': widget.province,
    });
  }

  Future<void> _loadCandidates() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // محاولة جلب المرشحين من قاعدة البيانات المحلية
      final allCandidates = LocalDatabase.getCandidates();
      
      // تصفية المرشحين حسب المحافظة
      final provinceCandidates = allCandidates.where((candidate) {
        return candidate.province == widget.province;
      }).toList();

      // إذا لم يكن هناك مرشحين، نستخدم بيانات وهمية
      if (provinceCandidates.isEmpty) {
        _candidates = _generateMockCandidates();
      } else {
        // نأخذ أول 5 مرشحين فقط
        _candidates = provinceCandidates.take(5).cast<CandidateModel>().toList();
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      AnalyticsService.trackError('load_candidates_by_province', e, StackTrace.current);
      setState(() {
        _isLoading = false;
        _error = 'فشل تحميل مرشحي المحافظة';
        _candidates = _generateMockCandidates(); // استخدام بيانات وهمية كبديل
      });
    }
  }

  List<CandidateModel> _generateMockCandidates() {
    // توليد 5 مرشحين وهميين للمحافظة
    return List.generate(5, (index) {
      final candidateNumber = index + 1;
      return CandidateModel(
        id: 'mock_${widget.province}_$candidateNumber',
        nameAr: ' $candidateNumber ${widget.province}',
        nameEn: 'Candidate $candidateNumber/ المرشح ${widget.province}',
        nicknameAr: 'لقب $candidateNumber',
        nicknameEn: 'Nickname $candidateNumber',
        positionAr: 'مرشح عن ${widget.province}',
        positionEn: 'Candidate for ${widget.province}',
        bioAr: 'سيرة ذاتية مفصلة للمرشح $candidateNumber من محافظة ${widget.province}. '
              'يتمتع بخبرة واسعة في المجال السياسي والخدمة المجتمعية ويحمل شهادات متقدمة في إدارة الأعمال.',
        bioEn: 'Detailed biography for candidate $candidateNumber from ${widget.province} province. '
              'Extensive experience in political and community service with advanced degrees in business administration.',
        imagePath: 'assets/images/candidates/default.jpg',
        phoneNumber: '0780${1000000 + candidateNumber}',
        province: widget.province,
        createdAt: DateTime.now().subtract(Duration(days: candidateNumber * 30)),
        updatedAt: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تجمع الفاو زاخو',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.province,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.3),
                //withOpacity(0.9),
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _candidates.isEmpty
                  ? _buildEmptyState()
                  : _buildCandidatesList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCandidates,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'لا يوجد مرشحين في ${widget.province}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _candidates.length,
      itemBuilder: (context, index) {
        final candidate = _candidates[index];
        return _CandidateCard(
          candidate: candidate,
          index: index,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CandidateDetailsScreen(candidate: candidate),
              ),
            );
          },
        );
      },
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final CandidateModel candidate;
  final int index;
  final VoidCallback onTap;

  const _CandidateCard({
    required this.candidate,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.languageCode;

    return Card(
      margin: EdgeInsets.only(
        bottom: index == 4 ? 0 : 12, // لا توجد مسافة أسفل آخر عنصر
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: _buildCandidateAvatar(),
        title: Text(
          candidate.getName(currentLanguage),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(candidate.getNickname(currentLanguage)),
            const SizedBox(height: 4),
            Text(
              candidate.getPosition(currentLanguage),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCandidateAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.blue.shade300,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.person,
        color: Colors.blue.shade700,
        size: 24,
      ),
    );
  }
}
