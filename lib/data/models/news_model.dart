import 'package:hive/hive.dart';

part 'news_model.g.dart';

/// 📰 NewsModel (ar/en only)
@HiveType(typeId: 4)
class NewsModel {
  @HiveField(0)  final String id;
  @HiveField(1)  final String titleAr;
  @HiveField(2)  final String titleEn;
  @HiveField(3)  final String contentAr;
  @HiveField(4)  final String contentEn;

  @HiveField(5)  final String imagePath;
  @HiveField(6)  final DateTime publishDate;
  @HiveField(7)  final String author;
  @HiveField(8)  final String category;
  @HiveField(9)  final bool isBreaking;
  @HiveField(10) final int viewCount;

  const NewsModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.contentAr,
    required this.contentEn,
    required this.imagePath,
    required this.publishDate,
    required this.author,
    required this.category,
    required this.isBreaking,
    required this.viewCount,
  });

  // JSON
  factory NewsModel.fromJson(Map<String, dynamic> j) => NewsModel(
        id: (j['id'] ?? '').toString(),
        titleAr: (j['title_ar'] ?? '').toString(),
        titleEn: (j['title_en'] ?? '').toString(),
        contentAr: (j['content_ar'] ?? '').toString(),
        contentEn: (j['content_en'] ?? '').toString(),
        imagePath: (j['image_url'] ?? '').toString(),
        publishDate: DateTime.parse((j['publish_date'] ?? DateTime.now().toIso8601String()).toString()),
        author: (j['author'] ?? '').toString(),
        category: (j['category'] ?? 'عام').toString(),
        isBreaking: j['is_breaking'] as bool? ?? false,
        viewCount: j['view_count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title_ar': titleAr,
        'title_en': titleEn,
        'content_ar': contentAr,
        'content_en': contentEn,
        'image_url': imagePath,
        'publish_date': publishDate.toIso8601String(),
        'author': author,
        'category': category,
        'is_breaking': isBreaking,
        'view_count': viewCount,
      };

  // Helpers
  String getTitle(String code) => code == 'en' ? titleEn : titleAr;
  String getContent(String code) => code == 'en' ? contentEn : contentAr;

  NewsModel copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    String? contentAr,
    String? contentEn,
    String? imageUrl,
    DateTime? publishDate,
    String? author,
    String? category,
    bool? isBreaking,
    int? viewCount,
  }) {
    return NewsModel(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      contentAr: contentAr ?? this.contentAr,
      contentEn: contentEn ?? this.contentEn,
      imagePath: imageUrl ?? this.imagePath,
      publishDate: publishDate ?? this.publishDate,
      author: author ?? this.author,
      category: category ?? this.category,
      isBreaking: isBreaking ?? this.isBreaking,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  @override
  bool operator ==(Object o) => identical(this, o) || (o is NewsModel && o.id == id);
  @override
  int get hashCode => id.hashCode;
}
