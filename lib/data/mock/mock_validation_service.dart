import '/data/models/faq_model.dart';
import '/data/models/news_model.dart';

/// 🎯 MockDataFactory
/// - يولد بيانات وهمية (FAQs, News)
/// - ثنائي اللغة (ar/en فقط)
/// - مخصص للاختبار والعرض
class MockDataFactory {
  /// ❓ توليد أسئلة شائعة (FAQs)
  List<FAQModel> generateFAQs(int count) {
    return List.generate(count, (index) {
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
    });
  }

  /// 📰 توليد أخبار (News)
  List<NewsModel> generateNews(int count) {
    const authors = ['الإدارة', 'فريق التحرير', 'Team Alpha', 'System Bot'];
    const categories = ['سياسة', 'عام', 'انتخابات'];

    return List.generate(count, (index) {
      return NewsModel(
        id         : 'news_${index + 1}',
        titleAr    : 'خبر ${index + 1}',
        titleEn    : 'News ${index + 1}',
        contentAr  : 'محتوى الخبر رقم ${index + 1}',
        contentEn  : 'News content #${index + 1}',
        imagePath  : 'assets/news/news_${(index % 5) + 1}.jpg',
        publishDate: DateTime.now().subtract(Duration(days: index)),
        author     : authors[index % authors.length],
        category   : categories[index % categories.length],
        isBreaking : index < 3,
        viewCount  : index * 10,
      );
    });
  }
}
