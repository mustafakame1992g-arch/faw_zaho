import 'dart:math';

/// 🏗 MockContentProvider
/// ✅ مزوّد بيانات وهمية (ar/en فقط)
/// ✅ يُستخدم من AdvancedMockService لتوليد بيانات تجريبية
/// ✅ يوفر بيانات للمرشحين والمكاتب والمحافظات
class MockContentProvider {
  final Random _random = Random();

  /// 👥 بيانات مرشح واحد (ar/en)
  Map<String, String> getCandidateData(int index) {
    return {
      'name_ar'     : 'مرشح ${index + 1}',
      'name_en'     : 'Candidate ${index + 1}',
      'position_ar' : 'منصب ${index + 1}',
      'position_en' : 'Position ${index + 1}',
      'bio_ar'      : 'سيرة المرشح رقم ${index + 1}',
      'bio_en'      : 'Biography of candidate ${index + 1}',
      'province'    : getRandomProvince(),
    };
  }

  /// 🌍 إرجاع محافظة عشوائية من قائمة
  String getRandomProvince() {
    const provinces = ['دهوك', 'أربيل', 'السليمانية'];
    return provinces[_random.nextInt(provinces.length)];
  }

  /// 🏢 بيانات مكتب انتخابي (ar/en)
  Map<String, String> getOfficeData(String province, int index) {
    return {
      'name_ar'     : 'مكتب $province ${index + 1}',
      'name_en'     : '$province Office ${index + 1}',
      'address_ar'  : 'عنوان $province ${index + 1}',
      'address_en'  : '$province Address ${index + 1}',
      'manager_ar'  : 'مدير ${index + 1}',
      'manager_en'  : 'Manager ${index + 1}',
      'district'    : 'منطقة ${index + 1}',
    };
  }
}
