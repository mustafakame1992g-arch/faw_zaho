import 'dart:math';
import 'package:flutter/foundation.dart';

import '/data/local/local_database.dart';
import '/data/models/candidate_model.dart';
import '/data/models/office_model.dart';
import '/data/models/faq_model.dart';
import '/data/models/news_model.dart';
import '/data/mock/mock_content_provider.dart';

/// 🚀 AdvancedMockService (نسخة احترافية ثنائية اللغة ar/en)
/// - كل البيانات تولَّد بواسطة Factories لتقليل التكرار.
/// - متوافقة مع النماذج المبسّطة (ar/en فقط).
/// - تحفظ تلقائياً في LocalDatabase عند الطلب.
class AdvancedMockService {
  static final Random _random = Random();
  static final MockContentProvider _contentProvider = MockContentProvider();

  /// 📦 نقطة دخول رئيسية لتوليد بيانات وهمية وحفظها اختيارياً
  static Future<Map<String, dynamic>> generateAndSaveMockData({
    int candidatesCount = 50,
    int officesCount    = 20,
    int faqsCount       = 30,
    int newsCount       = 25,
    bool saveToDatabase = true,
  }) async {
    final sw = Stopwatch()..start();

    try {
      final mockData = {
        'candidates': List.generate(candidatesCount, (i) => _buildCandidate(i)),
        'offices'   : List.generate(officesCount, (i) => _buildOffice(i)),
        'faqs'      : List.generate(faqsCount, (i) => _buildFAQ(i)),
        'news'      : List.generate(newsCount, (i) => _buildNews(i)),
        'metadata'  : {
          'generated_at': DateTime.now().toIso8601String(),
          'version'     : '1.0.0',
          'total_items' : candidatesCount + officesCount + faqsCount + newsCount,
        },
      };

      if (saveToDatabase) {
        await _saveMockDataToDatabase(mockData);
      }

      if (kDebugMode) {
        sw.stop();
        debugPrint('✅ Mock data generated in ${sw.elapsedMilliseconds}ms');
      }
      return mockData;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error generating mock data: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 👥 المرشحون
  // ---------------------------------------------------------------------------
 // في lib/data/mock/mock_data_service.dart
static CandidateModel _buildCandidate(int index) {
   final provinceData = _contentProvider.getRandomProvince();
  final d = _contentProvider.getCandidateData(index);
  return CandidateModel(
    id        : 'candidate_${index + 1}',
    nameAr    : d['name_ar']    ?? 'مرشّح ${index + 1}',
    nameEn    : d['name_en']    ?? 'Candidate ${index + 1}',
    nicknameAr: d['nickname_ar'] ?? 'لقب ${index + 1}',
    nicknameEn: d['nickname_en'] ?? 'Nickname ${index + 1}',

    positionAr: d['position_ar']?? 'منصب ${index + 1}',
    positionEn: d['position_en']?? 'Position ${index + 1}',
    bioAr     : d['bio_ar']     ?? 'سيرة المرشّح رقم ${index + 1}...',
    bioEn     : d['bio_en']     ?? 'Biography for candidate ${index + 1}...',
    imagePath  : 'assets/mock/candidate_${(index % 10) + 1}.jpg',
    phoneNumber: d['phone_number'] ?? '+964XXXXXXXXX', // تأكد من وجود قيمة افتراضية
    province  : d['province']   ?? _contentProvider.getRandomProvince(),
    createdAt : DateTime.now().subtract(Duration(days: _random.nextInt(365))),
    updatedAt : DateTime.now(),
  );
}

  // ---------------------------------------------------------------------------
  // 🏢 المكاتب
  // ---------------------------------------------------------------------------
  static OfficeModel _buildOffice(int index) {
    final province  = _contentProvider.getRandomProvince();
    final d         = _contentProvider.getOfficeData(province, index);

    return OfficeModel(
      id           : 'office_${index + 1}',
      nameAr       : d['name_ar']     ?? 'مكتب $province ${index + 1}',
      nameEn       : d['name_en']     ?? '$province Office ${index + 1}',
      addressAr    : d['address_ar']  ?? 'عنوان $province ${index + 1}',
      addressEn    : d['address_en']  ?? '$province Address ${index + 1}',
      phoneNumber  : _generateOfficePhone(province),
      email        : 'office${index + 1}@alfawzakho.com',
      managerNameAr: d['manager_ar']  ?? 'مدير ${index + 1}',
      managerNameEn: d['manager_en']  ?? 'Manager ${index + 1}',
      latitude     : 36.85 + (_random.nextDouble() * 0.1 - 0.05),
      longitude    : 42.99 + (_random.nextDouble() * 0.1 - 0.05),
      province     : province,
      district     : d['district']    ?? 'منطقة ${index + 1}',
      workingHours : '08:00 - 16:00',
      isActive     : true,
      capacity     : 50 + _random.nextInt(50),
      services     : const ['استقبال', 'استعلامات', 'تسجيل'],
      createdAt    : DateTime.now().subtract(Duration(days: _random.nextInt(200))),
      updatedAt    : DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // ❓ الأسئلة الشائعة
  // ---------------------------------------------------------------------------
  static FAQModel _buildFAQ(int index) {
    return FAQModel(
      id        : 'faq_${index + 1}',
      questionAr: 'سؤال ${index + 1}؟',
      questionEn: 'Question ${index + 1}?',
      answerAr  : 'إجابة ${index + 1}',
      answerEn  : 'Answer ${index + 1}',
      category  : 'عام',
      importance: 1,
      tags      : const [],
      createdAt : DateTime.now(),
      viewCount : 0,
    );
  }

  // ---------------------------------------------------------------------------
  // 📰 الأخبار
  // ---------------------------------------------------------------------------
  static NewsModel _buildNews(int index) {
    return NewsModel(
      id         : 'news_${index + 1}',
      titleAr    : 'خبر ${index + 1}',
      titleEn    : 'News ${index + 1}',
      contentAr  : 'محتوى الخبر رقم ${index + 1}',
      contentEn  : 'News content #${index + 1}',
      imagePath   : 'assets/news/news_${(index % 5) + 1}.jpg',
      publishDate: DateTime.now().subtract(Duration(days: index)),
      author     : _randomAuthor(),
      category   : 'عام',
      isBreaking : index < 3,
      viewCount  : index * 10,
    );
  }

  // ---------------------------------------------------------------------------
  // 💾 الحفظ في قاعدة البيانات
  // ---------------------------------------------------------------------------
  static Future<void> _saveMockDataToDatabase(Map<String, dynamic> mockData) async {
    try {
      await LocalDatabase.saveCandidates(mockData['candidates']);
      await LocalDatabase.saveOffices(mockData['offices']);
      await LocalDatabase.saveFAQs(mockData['faqs']);
      await LocalDatabase.saveNews(mockData['news']);
      if (kDebugMode) debugPrint('💾 Mock data saved to database successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Could not save mock data to database: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ☎️ مولدات مساعدة
  // ---------------------------------------------------------------------------
  static String _generateOfficePhone(String province) {
    const areaCodes = {'دهوك': '62', 'أربيل': '66', 'السليمانية': '53'};
    final areaCode = areaCodes[province] ?? '62';
    final number   = (1000000 + _random.nextInt(9000000)).toString().substring(1);
    return '+964$areaCode$number';
  }

  static String _randomAuthor() {
    const authors = ['الإدارة', 'Team Alpha', 'Editorial Board', 'System Bot'];
    return authors[_random.nextInt(authors.length)];
  }
}
