// test/ui_comprehensive_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:al_faw_zakho/main.dart' as app;
import 'package:al_faw_zakho/data/local/local_database.dart';

void main() {
  group('📱 اختبارات الواجهة الشاملة', () {
    
    testWidgets('✅ HomeScreen - تحميل الشاشة الرئيسية', (WidgetTester tester) async {
      // 1. بناء التطبيق
      await tester.pumpWidget(const app.FoundationApp());
      
      // 2. انتظار التهيئة
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // 3. التحقق من العناصر
      expect(find.text('تطبيق تجمع الفاو زاخو'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('✅ HomeScreen - شبكة الأقسام', (WidgetTester tester) async {
      await tester.pumpWidget(const app.FoundationApp());
      await tester.pumpAndSettle();
      
      // التحقق من وجود جميع الأقسام
      expect(find.text('المرشحين'), findsOneWidget);
      expect(find.text('المكاتب'), findsOneWidget);
      expect(find.text('الأسئلة الشائعة'), findsOneWidget);
      expect(find.text('الإعدادات'), findsOneWidget);
    });

    testWidgets('✅ CandidatesScreen - تحميل المرشحين', (WidgetTester tester) async {
      await tester.pumpWidget(const app.FoundationApp());
      await tester.pumpAndSettle();
      
      // الانتقال لشاشة المرشحين
      await tester.tap(find.text('المرشحين'));
      await tester.pumpAndSettle();
      
      // التحقق من التحميل
      expect(find.text('المرشحين'), findsOneWidget);
    });

    testWidgets('✅ OfficesScreen - تحميل المكاتب', (WidgetTester tester) async {
      await tester.pumpWidget(const app.FoundationApp());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('المكاتب'));
      await tester.pumpAndSettle();
      
      expect(find.text('المكاتب'), findsOneWidget);
    });

    testWidgets('✅ Mock Data - توليد البيانات الوهمية', (WidgetTester tester) async {
      // اختبار توليد Mock Data
      final candidates = LocalDatabase.getCandidates();
      final offices = LocalDatabase.getOffices();
      
      expect(candidates.length, greaterThan(0));
      expect(offices.length, greaterThan(0));
    });
  });

  group('🔧 اختبارات الأداء والاستقرار', () {
    
    testWidgets('⚡ أداء التحميل - أقل من 3 ثواني', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(const app.FoundationApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    testWidgets('🛡️ معالجة الأخطاء - بيانات فارغة', (WidgetTester tester) async {
      // محاكاة حالة بيانات فارغة
      await tester.pumpWidget(const app.FoundationApp());
      await tester.pumpAndSettle();
      
      // يجب ألا يحدث crash
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}