// lib/presentation/screens/candidates/candidate_details_screen.dart
import 'package:al_faw_zakho/core/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/localization/app_localizations.dart';
import '/core/services/analytics_service.dart';
import '/data/models/candidate_model.dart';

class CandidateDetailsScreen extends StatelessWidget {
  final CandidateModel candidate;

  const CandidateDetailsScreen({
    super.key,
    required this.candidate,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.languageCode;

    AnalyticsService.trackEvent('candidate_details_opened', parameters: {
      'candidate_id': candidate.id,
      'candidate_name': candidate.nameAr,
      'province': candidate.province,
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('candidate_details')),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // صورة المرشح
            _buildCandidateImage(),
            const SizedBox(height: 24),
            
            // الاسم الثلاثي
            _buildCandidateName(currentLanguage),
            const SizedBox(height: 12),
            
            // اللقب
            _buildCandidateNickname(currentLanguage),
            const SizedBox(height: 24),
            
            // السيرة الذاتية
            _buildCandidateBio(currentLanguage),
            const SizedBox(height: 24),
            
            // رقم الموبايل
            _buildCandidatePhone(),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateImage() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade100,
        border: Border.all(
          color: Colors.blue.shade300,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.
            //withOpacity(0.3),
            withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.person,
        size: 60,
        color: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildCandidateName(String languageCode) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            languageCode == 'en' ? candidate.nameEn : candidate.nameAr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'الاسم الثلاثي',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateNickname(String languageCode) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Text(
            candidate.getNickname(languageCode),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'اللقب',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateBio(String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description,
              color: Colors.orange.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'السيرة الذاتية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            languageCode == 'en' ? candidate.bioEn : candidate.bioAr,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
      ],
    );
  }

  Widget _buildCandidatePhone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.phone,
              color: Colors.red.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'رقم الموبايل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.phone_android,
                color: Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  candidate.phoneNumber,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.phone_forwarded,
                  color: Colors.red.shade700,
                  size: 28,
                ),
                onPressed: () {
                  AnalyticsService.trackEvent('candidate_phone_clicked', parameters: {
                    'candidate_id': candidate.id,
                    'phone_number': candidate.phoneNumber,
                  });
                  // يمكن إضافة وظيفة الاتصال هنا لاحقاً
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
