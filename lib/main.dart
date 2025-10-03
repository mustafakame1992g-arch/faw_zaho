import 'dart:developer' as developer;
import 'package:al_faw_zakho/core/localization/app_localizations.dart';
import 'package:al_faw_zakho/data/models/candidate_model.dart';
import 'package:al_faw_zakho/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Core Providers
import '/core/providers/app_provider.dart';
import '/core/providers/connectivity_provider.dart';
import '/core/providers/theme_provider.dart';
import '/core/providers/language_provider.dart';

// Core Services
import '/data/local/local_database.dart';
import '/core/services/analytics_service.dart';
import '/core/network/api_client.dart';
import '/data/mock/mock_data_service.dart' as mock_service;
// Presentation
import '/presentation/widgets/loading_screen.dart';
import '/presentation/widgets/error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة متوازية لجميع الخدمات الأساسية
  await _initializeCoreServices();

  runApp(const FoundationApp());
}

 Future<void> _initializeRealDataSystem() async {
  try {
    // تسجيل adapter للمرشحين الجدد
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CandidateModelAdapter());
    }
    
    developer.log('[MAIN] Real data system initialized ✅', name: 'BOOT');
  } catch (e) {
    developer.log('[MAIN] Real data system init failed: $e', 
        name: 'ERROR', error: e);
  }
}

// ✅ دالة تهيئة متوازية ومحسنة
Future<void> _initializeCoreServices() async {
  final stopwatch = Stopwatch()..start();


  developer.log('[MAIN] Starting parallel service initialization...',
      name: 'BOOT');

  try {
    // ✅ تهيئة متوازية للخدمات الأساسية
    await Future.wait([
      _initializeHiveWithRetry(),
      _initializeAnalytics(),
    ], eagerError: true);

    developer.log(
        '[MAIN] All core services initialized ✅ in ${stopwatch.elapsedMilliseconds}ms',
        name: 'BOOT');
  } catch (e) {
    developer.log('[MAIN] Core services initialization failed: $e',
        name: 'ERROR', error: e);
    rethrow;
  } finally {
    stopwatch.stop();
  }
}

// ✅ تهيئة Hive مع إعادة المحاولة
Future<void> _initializeHiveWithRetry() async {
  for (int attempt = 1; attempt <= 3; attempt++) {
    try {
      await Hive.initFlutter();
      await LocalDatabase.init();

      developer.log(
          '[MAIN] Hive & LocalDatabase initialized ✅ (attempt $attempt)',
          name: 'BOOT');
      return;
    } catch (e) {
      if (attempt == 3) rethrow;
      developer.log('[MAIN] Hive init failed, retrying... (attempt $attempt)',
          name: 'WARNING');
      await Future.delayed(Duration(seconds: attempt));
    }
  }
}

// ✅ تهيئة Analytics
Future<void> _initializeAnalytics() async {
  AnalyticsService.initialize();
  developer.log('[MAIN] Analytics initialized ✅', name: 'BOOT');
}

class FoundationApp extends StatelessWidget {
  const FoundationApp({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('[FoundationApp] Building root MultiProvider', name: 'BOOT');

    return MultiProvider(
      providers: [
        // ✅ إضافة MockDataService ك Provider
        Provider<mock_service.AdvancedMockService>(
            create: (_) => mock_service.AdvancedMockService()),
        //Provider<MockDataService>(create: (_) => MockDataService()),
        Provider<ApiClient>(create: (_) => ApiClient()),

        ChangeNotifierProvider(create: (_) {
          developer.log('[Provider] ConnectivityProvider created',
              name: 'PROVIDER');
          return ConnectivityProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          developer.log('[Provider] ThemeProvider created', name: 'PROVIDER');
          return ThemeProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          developer.log('[Provider] LanguageProvider created',
              name: 'PROVIDER');
          return LanguageProvider();
        }),

        ChangeNotifierProxyProvider<ApiClient, AppProvider>(
          create: (context) => AppProvider(),
          update: (context, apiClient, appProvider) {
            return appProvider!..setApiClient(apiClient);
          },
        ),
      ],
      child: const _AppRoot(),
    );
  }
}

class MockDataService {}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late AppProvider _appProvider;
  bool _isInitializing = true;
  String? _errorMessage;
  double _initializationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    developer.log('[_AppRoot] initState()', name: 'LIFECYCLE');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  // ✅ دالة التهيئة المحسنة مع تتبع التقدم
  Future<void> _initializeApp() async {
    if (!mounted) return;

    final stopwatch = Stopwatch()..start();
    developer.log('[_AppRoot] Starting comprehensive app initialization...',
        name: 'INIT');

    try {
      _appProvider = Provider.of<AppProvider>(context, listen: false);

      // ✅ التهيئة مع تتبع التقدم
      await _executeInitializationPhases();

      stopwatch.stop();

      developer.log(
        '[_AppRoot] App initialization completed ✅ in ${stopwatch.elapsedMilliseconds}ms',
        name: 'INIT',
      );

      AnalyticsService.trackEvent('app_initialization_completed', parameters: {
        'duration_ms': stopwatch.elapsedMilliseconds,
        'phase_count': '5',
        'success': 'true'
      });

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initializationProgress = 1.0;
        });
      }
    } catch (e) {
      developer.log('[_AppRoot] Initialization error: $e',
          name: 'ERROR', error: e);

      AnalyticsService.trackEvent('app_initialization_failed', parameters: {
        'error': e.toString(),
        'phase': _getCurrentPhase(),
      });

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // ✅ تنفيذ مراحل التهيئة مع Mock Data
  Future<void> _executeInitializationPhases() async {
    const totalPhases = 5;

    // المرحلة 1: تهيئة الأساسيات
    _updateProgress(1, totalPhases, 'Initializing core providers...');
    await _appProvider.initializeApp(
      initializeConnectivity: () =>
          Provider.of<ConnectivityProvider>(context, listen: false).init(),
      initializeTheme: () =>
          Provider.of<ThemeProvider>(context, listen: false).init(),
      initializeLanguage: () =>
          Provider.of<LanguageProvider>(context, listen: false).init(),
    );

    // المرحلة 2: التحقق من اتصال الشبكة
    _updateProgress(2, totalPhases, 'Checking network connectivity...');
    final hasConnection = await _checkNetworkConnectivity();

    // المرحلة 3: إدارة Mock Data الذكية
    _updateProgress(3, totalPhases, 'Managing application data...');
    await _initializeAppData(hasConnection);

    // المرحلة 4: تحميل البيانات الأولية
    _updateProgress(4, totalPhases, 'Loading initial data...');
    await _loadInitialData(hasConnection);

    // المرحلة 5: التهيئة النهائية
    _updateProgress(5, totalPhases, 'Finalizing setup...');
    await _finalizeInitialization();
  }

  // ✅ التحقق من الاتصال بالشبكة
  Future<bool> _checkNetworkConnectivity() async {
    try {
      final connectivityProvider =
          Provider.of<ConnectivityProvider>(context, listen: false);
      return await connectivityProvider.checkConnection();
    } catch (e) {
      developer.log('[_AppRoot] Connectivity check failed: $e',
          name: 'WARNING');
      return false;
    }
  }

  // ✅ إدارة بيانات التطبيق الذكية (الميزة الرئيسية)
  Future<void> _initializeAppData(bool hasConnection) async {
    developer.log(
        '[_AppRoot] Initializing app data (hasConnection: $hasConnection)',
        name: 'DATA');

    try {
      final shouldGenerateMockData = await _shouldGenerateMockData();

      if (shouldGenerateMockData) {
        developer.log('[_AppRoot] Generating mock data...', name: 'DATA');

        await _appProvider.generateMockData(
          forceRefresh: !hasConnection, // ✅ إجبار التوليد إذا لا يوجد اتصال
          demoMode: !hasConnection, // ✅ وضع التجربة إذا لا يوجد اتصال
        );

        AnalyticsService.trackEvent('mock_data_generated', parameters: {
          'reason': hasConnection ? 'first_launch' : 'offline_mode',
          'data_type': 'all'
        });
      } else {
        developer.log(
            '[_AppRoot] Existing data found, skipping mock generation',
            name: 'DATA');
      }

      // ✅ التحقق من جودة البيانات الموجودة
      await _validateExistingDataQuality();
    } catch (e) {
      developer.log('[_AppRoot] Mock data initialization failed: $e',
          name: 'ERROR', error: e);
      // لا نعيد الخطأ هنا لأن التطبيق يمكن أن يعمل بدون Mock Data
    }
  }

  // ✅ التحقق إذا كان需要 توليد Mock Data
  Future<bool> _shouldGenerateMockData() async {
    try {
      // التحقق من وجود بيانات مرشحين
      final existingCandidates = LocalDatabase.getCandidates();
      final hasCandidates = existingCandidates.isNotEmpty;

      // التحقق من وجود بيانات الأسئلة
      final existingFAQs = LocalDatabase.getFAQs();
      final hasFAQs = existingFAQs.isNotEmpty;

      // التحقق من تاريخ آخر تحديث
      final lastUpdate = _getLastUpdateTimestamp();

      //final lastUpdate = LocalDatabase.getAppData('last_mock_update');
      final needsRefresh = lastUpdate == null ||
          //DateTime.now().difference(DateTime.parse(lastUpdate)).inDays > 7;
          DateTime.now().difference(lastUpdate).inDays > 7;

      developer.log(
          '[_AppRoot] Data check - Candidates: $hasCandidates, FAQs: $hasFAQs, NeedsRefresh: $needsRefresh',
          name: 'DATA');

      return !hasCandidates || !hasFAQs || needsRefresh;
    } catch (e) {
      developer.log('[_AppRoot] Data check failed, generating mock data: $e',
          name: 'WARNING');
      return true; // ✅ توليد بيانات إذا فشل التحقق
    }
  }

// ✅ دالة بديلة إذا لم تكن getAppData موجودة
  DateTime? _getLastUpdateTimestamp() {
    try {
      // محاولة الحصول من التفضيلات المحلية
      return null; // قيمة افتراضية
    } catch (e) {
      return null;
    }
  }

  // ✅ تحميل البيانات الأولية
  Future<void> _loadInitialData(bool hasConnection) async {
    if (hasConnection) {
      try {
        developer.log('[_AppRoot] Loading fresh data from API...',
            name: 'DATA');
        await _appProvider.loadFreshData();
      } catch (e) {
        developer.log('[_AppRoot] API data load failed, using cached data: $e',
            name: 'WARNING');
      }
    } else {
      developer.log('[_AppRoot] Offline mode - using cached data',
          name: 'DATA');
    }
  }

  // ✅ التحقق من جودة البيانات الموجودة
  Future<void> _validateExistingDataQuality() async {
    try {
      final candidates = LocalDatabase.getCandidates();
      final faqs = LocalDatabase.getFAQs();

      developer.log(
          '[_AppRoot] Data quality - Candidates: ${candidates.length}, FAQs: ${faqs.length}',
          name: 'DATA');

      if (candidates.isEmpty || faqs.isEmpty) {
        developer.log('[_AppRoot] Low data quality, generating mock data...',
            name: 'DATA');
        await _appProvider.generateMockData(forceRefresh: true);
      }
    } catch (e) {
      developer.log('[_AppRoot] Data quality check failed: $e',
          name: 'WARNING');
    }
  }

  // ✅ التهيئة النهائية
  Future<void> _finalizeInitialization() async {
    // أي عمليات نهائية قبل تشغيل التطبيق
    await Future.delayed(
        const Duration(milliseconds: 300)); // تأخير بسيط للanimations
  }

  // ✅ تحديث تقدم التهيئة
  void _updateProgress(int currentPhase, int totalPhases, String message) {
    if (mounted) {
      setState(() {
        _initializationProgress = currentPhase / totalPhases;
      });
    }
    developer.log('[_AppRoot] Phase $currentPhase/$totalPhases: $message',
        name: 'PROGRESS');
  }

  // ✅ الحصول على المرحلة الحالية للأخطاء
  String _getCurrentPhase() {
    final progress = _initializationProgress;
    if (progress < 0.2) return 'core_providers';
    if (progress < 0.4) return 'network_check';
    if (progress < 0.6) return 'data_management';
    if (progress < 0.8) return 'data_loading';
    return 'finalization';
  }

  @override
  Widget build(BuildContext context) {
    developer.log('[_AppRoot] build() - Initializing: $_isInitializing',
        name: 'UI');

    if (_isInitializing) {
      return MaterialApp(
        home: LoadingScreen(
          progress: _initializationProgress,
          //currentPhase: _getCurrentPhase(),
        ),
      );
    }

    if (_errorMessage != null) {
      return MaterialApp(
        home: ErrorScreen(
          error: _errorMessage!,
          onRetry: _retryInitialization,

        ),
      );
    }

    return _buildMainApp();
  }

  // ✅ إعادة محاولة التهيئة
  void _retryInitialization() {
    developer.log('[_AppRoot] Retrying initialization...', name: 'STATE');
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _initializationProgress = 0.0;
    });
    _initializeApp();
  }

Widget _buildMainApp() {
  return Consumer3<ThemeProvider, LanguageProvider, AppProvider>(
    builder: (context, themeProvider, languageProvider, appProvider, _) {

// ✅ التصحيح الصحيح:
debugPrint('🎯 بناء MaterialApp - اللغة المختارة: ${
 languageProvider.languageCode}، الفعلية: ${languageProvider.locale.languageCode}');
     

      return MaterialApp(
        title: 'تطبيق تجمع الفاو زاخو',
        debugShowCheckedModeBanner: false,
        
        // ✅ الإصلاح الحاسم: استخدام اللغات المدعومة فعلياً فقط
        locale: languageProvider.locale,
        
         supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        
        localeResolutionCallback: (deviceLocale, supportedLocales) {
          return languageProvider.locale; // ✅ استخدام اللغة المحسوبة مسبقاً
        },
        
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        
        themeMode: themeProvider.themeMode,
        theme: ThemeData.light().copyWith(
          textTheme: ThemeData.light().textTheme.apply(
            fontFamily: _getFontFamily(languageProvider.locale.languageCode),
          ),
        ),
        darkTheme: ThemeData.dark().copyWith(
          textTheme: ThemeData.dark().textTheme.apply(
            fontFamily: _getFontFamily(languageProvider.locale.languageCode),
          ),
        ),
        
        home: const HomeScreen(),
      );
    },
  );
}


String _getFontFamily(String languageCode) {
  return 'Tajawal';
}

}
