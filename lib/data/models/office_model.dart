
import 'dart:math' show cos, sin, sqrt, atan2, pi;
import 'package:hive/hive.dart';

part 'office_model.g.dart';

/// 🏢 OfficeModel (ar/en only)
@HiveType(typeId: 2)
class OfficeModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String nameAr;
  @HiveField(2)
  final String nameEn;

  @HiveField(3)
  final String addressAr;
  @HiveField(4)
  final String addressEn;

  @HiveField(5)
  final String phoneNumber;
  @HiveField(6)
  final String? secondaryPhone;
  @HiveField(7)
  final String email;

  @HiveField(8)
  final String managerNameAr;
  @HiveField(9)
  final String managerNameEn;

  @HiveField(10)
  final double latitude;
  @HiveField(11)
  final double longitude;

  @HiveField(12)
  final String province;
  @HiveField(13)
  final String district;
  @HiveField(14)
  final String workingHours;
  @HiveField(15)
  final String? workingDays;

  @HiveField(16)
  final bool isActive;
  @HiveField(17)
  final int capacity;
  @HiveField(18)
  final List<String> services;

  @HiveField(19)
  final DateTime createdAt;
  @HiveField(20)
  final DateTime updatedAt;
  @HiveField(21)
  final String? notes;

  OfficeModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.addressAr,
    required this.addressEn,
    required this.phoneNumber,
    this.secondaryPhone,
    required this.email,
    required this.managerNameAr,
    required this.managerNameEn,
    required this.latitude,
    required this.longitude,
    required this.province,
    required this.district,
    required this.workingHours,
    this.workingDays,
    this.isActive = true,
    this.capacity = 50,
    this.services = const [],
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  }) : assert(_isValidCoordinate(latitude, longitude));

  // JSON
  factory OfficeModel.fromJson(Map<String, dynamic> j) {
    final lat = _parseDouble(j['latitude']);
    final lng = _parseDouble(j['longitude']);
    if (!_isValidCoordinate(lat, lng)) {
      throw FormatException('Invalid coordinates: $lat,$lng');
    }
    return OfficeModel(
      id: (j['id'] ?? '').toString(),
      nameAr: (j['name_ar'] ?? '').toString(),
      nameEn: (j['name_en'] ?? '').toString(),
      addressAr: (j['address_ar'] ?? '').toString(),
      addressEn: (j['address_en'] ?? '').toString(),
      phoneNumber: (j['phone_number'] ?? '').toString(),
      secondaryPhone: j['secondary_phone']?.toString(),
      email: (j['email'] ?? '').toString(),
      managerNameAr: (j['manager_name_ar'] ?? '').toString(),
      managerNameEn: (j['manager_name_en'] ?? '').toString(),
      latitude: lat,
      longitude: lng,
      province: (j['province'] ?? '').toString(),
      district: (j['district'] ?? '').toString(),
      workingHours: (j['working_hours'] ?? '').toString(),
      workingDays: j['working_days']?.toString(),
      isActive: j['is_active'] as bool? ?? true,
      capacity: (j['capacity'] as int?) ?? 50,
      services: List<String>.from(j['services'] as List? ?? const []),
      createdAt: DateTime.parse(
          (j['created_at'] ?? DateTime.now().toIso8601String()).toString()),
      updatedAt: DateTime.parse(
          (j['updated_at'] ?? DateTime.now().toIso8601String()).toString()),
      notes: j['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_ar': nameAr,
        'name_en': nameEn,
        'address_ar': addressAr,
        'address_en': addressEn,
        'phone_number': phoneNumber,
        'secondary_phone': secondaryPhone,
        'email': email,
        'manager_name_ar': managerNameAr,
        'manager_name_en': managerNameEn,
        'latitude': latitude,
        'longitude': longitude,
        'province': province,
        'district': district,
        'working_hours': workingHours,
        'working_days': workingDays,
        'is_active': isActive,
        'capacity': capacity,
        'services': services,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'notes': notes,
      };

  // Helpers
  String getName(String code) => code == 'en' ? nameEn : nameAr;
  String getAddress(String code) => code == 'en' ? addressEn : addressAr;

  bool get hasValidCoordinates => _isValidCoordinate(latitude, longitude);
  bool get canContact => isActive && phoneNumber.isNotEmpty;

  // مسافة هافرسين (كم)
  double distanceTo(double targetLat, double targetLng) {
    const r = 6371.0;
    final dLat = _toRad(targetLat - latitude);
    final dLng = _toRad(targetLng - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(latitude)) *
            cos(_toRad(targetLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * pi / 180.0;
  static bool _isValidCoordinate(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  static double _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.parse(v.toString());
  }

  OfficeModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? addressAr,
    String? addressEn,
    String? phoneNumber,
    String? secondaryPhone,
    String? email,
    String? managerNameAr,
    String? managerNameEn,
    double? latitude,
    double? longitude,
    String? province,
    String? district,
    String? workingHours,
    String? workingDays,
    bool? isActive,
    int? capacity,
    List<String>? services,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return OfficeModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      addressAr: addressAr ?? this.addressAr,
      addressEn: addressEn ?? this.addressEn,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      managerNameAr: managerNameAr ?? this.managerNameAr,
      managerNameEn: managerNameEn ?? this.managerNameEn,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      province: province ?? this.province,
      district: district ?? this.district,
      workingHours: workingHours ?? this.workingHours,
      workingDays: workingDays ?? this.workingDays,
      isActive: isActive ?? this.isActive,
      capacity: capacity ?? this.capacity,
      services: services ?? this.services,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object o) =>
      identical(this, o) || (o is OfficeModel && o.id == id);
  @override
  int get hashCode => id.hashCode;
  @override
  String toString() => 'OfficeModel($id, $nameAr/$nameEn, $province)';
}

/// خدمة بيانات وهمية (مبسطة) لاختبار المكاتب فقط.
class MockDataService {
  static List<OfficeModel> getMockOffices() {
    return [
  OfficeModel(
    id: '1',
    nameAr: 'مكتب المثنى',
    nameEn: 'Muthanna Office',
    addressAr: 'السماوة - شارع المحافظة',
    addressEn: 'Samawah - Governorate Street',
    phoneNumber: '07800000001',
    secondaryPhone: '07800000002',
    email: 'muthanna.office@example.com',
    managerNameAr: 'علي عبد',
    managerNameEn: 'Ali Abd',
    latitude: 31.3141,
    longitude: 45.2806,
    province: 'المثنى',
    district: 'السماوة',
    workingHours: '08:00 - 16:00',
    workingDays: 'الأحد - الخميس',
    isActive: true,
    capacity: 100,
    services: ['تحديث بيانات', 'استفسارات', 'إصدار بطاقات'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    notes: 'فرع رئيسي في المحافظة',
  ),
  OfficeModel(
    id: '2',
    nameAr: 'مكتب بغداد',
    nameEn: 'Baghdad Office',
    addressAr: 'بغداد - الكرادة',
    addressEn: 'Baghdad - Karrada',
    phoneNumber: '07800000011',
    secondaryPhone: '07800000012',
    email: 'baghdad.office@example.com',
    managerNameAr: 'حسن كريم',
    managerNameEn: 'Hassan Kareem',
    latitude: 33.3152,
    longitude: 44.3661,
    province: 'بغداد',
    district: 'الكرادة',
    workingHours: '08:00 - 17:00',
    workingDays: 'الأحد - الخميس',
    isActive: true,
    capacity: 200,
    services: ['تحديث بيانات', 'شكاوى', 'إصدار بطاقات'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    notes: 'الفرع المركزي في بغداد',
  ),
];

  }
}
