import 'package:hive/hive.dart';

part 'faq_model.g.dart';

/// ❓ FAQModel (ar/en only)
@HiveType(typeId: 3)
class FAQModel {
  @HiveField(0)  final String id;
  @HiveField(1)  final String questionAr;
  @HiveField(2)  final String questionEn;
  @HiveField(3)  final String answerAr;
  @HiveField(4)  final String answerEn;

  @HiveField(5)  final String category;   // مثال: عام/تقني/إجرائي
  @HiveField(6)  final int importance;    // 1..5
  @HiveField(7)  final List<String> tags;

  @HiveField(8)  final DateTime createdAt;
  @HiveField(9)  final int viewCount;

  const FAQModel({
    required this.id,
    required this.questionAr,
    required this.questionEn,
    required this.answerAr,
    required this.answerEn,
    required this.category,
    required this.importance,
    required this.tags,
    required this.createdAt,
    required this.viewCount,
  });

  // JSON
  factory FAQModel.fromJson(Map<String, dynamic> j) => FAQModel(
        id: (j['id'] ?? '').toString(),
        questionAr: (j['question_ar'] ?? '').toString(),
        questionEn: (j['question_en'] ?? '').toString(),
        answerAr: (j['answer_ar'] ?? '').toString(),
        answerEn: (j['answer_en'] ?? '').toString(),
        category: (j['category'] ?? 'عام').toString(),
        importance: (j['importance'] as int?) ?? 1,
        tags: List<String>.from(j['tags'] as List? ?? const []),
        createdAt: DateTime.parse((j['created_at'] ?? DateTime.now().toIso8601String()).toString()),
        viewCount: (j['view_count'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'question_ar': questionAr,
        'question_en': questionEn,
        'answer_ar': answerAr,
        'answer_en': answerEn,
        'category': category,
        'importance': importance,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'view_count': viewCount,
      };

  // Helpers
  String getQuestion(String code) => code == 'en' ? questionEn : questionAr;
  String getAnswer(String code) => code == 'en' ? answerEn : answerAr;

  FAQModel copyWith({
    String? id,
    String? questionAr,
    String? questionEn,
    String? answerAr,
    String? answerEn,
    String? category,
    int? importance,
    List<String>? tags,
    DateTime? createdAt,
    int? viewCount,
  }) {
    return FAQModel(
      id: id ?? this.id,
      questionAr: questionAr ?? this.questionAr,
      questionEn: questionEn ?? this.questionEn,
      answerAr: answerAr ?? this.answerAr,
      answerEn: answerEn ?? this.answerEn,
      category: category ?? this.category,
      importance: importance ?? this.importance,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  @override
  bool operator ==(Object o) => identical(this, o) || (o is FAQModel && o.id == id);
  @override
  int get hashCode => id.hashCode;
}
