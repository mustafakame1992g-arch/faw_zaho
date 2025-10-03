/*// إنشاء ملف اختبار أساسي
// test/widgets/candidate_card_test.dart
import 'package:al_faw_zakho/data/models/candidate_model.dart';
import 'package:al_faw_zakho/presentation/screens/candidates/widgets/candidate_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  testWidgets('CandidateCard displays candidate info', (WidgetTester tester) async {
    final candidate = CandidateModel(
      id: '1',
      nameAr: 'مرشح تجريبي',
       nameKu: '', nameTm: '', 
       positionAr: '', positionKu: '',
        positionTm: '', bioAr: '', bioKu: '', 
        bioTm: '', imageUrl: '', 
        phoneNumber: '', province: '',
         createdAt: DateTime(2023),
          updatedAt:  DateTime(2023),
      // ... باقي الحقول
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CandidateCard(candidate: candidate),
        ),
      ),
    );

    expect(find.text('مرشح تجريبي'), findsOneWidget);
  });
}*/



// test/widgets/candidate_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:al_faw_zakho/data/models/candidate_model.dart';
import 'package:al_faw_zakho/presentation/screens/candidates/widgets/candidate_card.dart';

void main() {
  testWidgets('CandidateCard displays candidate info', (WidgetTester tester) async {
    // إنشاء مرشح تجريبي بدون صورة لتجنب الخطأ
    // تحديث إنشاء CandidateModel ليتوافق مع التعريف الجديد
final CandidateModel candidate = CandidateModel(
  id: '1',
  nameAr: 'مرشح 1',
  nicknameAr: '',
  nicknameEn:'',
  nameEn: 'Candidate 1',
  positionAr: 'منصب 1',
  positionEn: 'Position 1',
  bioAr: 'سيرة المرشح 1',
  bioEn: 'Biography 1',
imagePath: 'assets/image1.jpg',  phoneNumber: '+964123456789', // إضافة phoneNumber
  province: 'دهوك',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CandidateCard(candidate: candidate),
        ),
      ),
    );

    expect(find.text('مرشح تجريبي'), findsOneWidget);
    expect(find.text('منصب تجريبي'), findsOneWidget);
  });
}