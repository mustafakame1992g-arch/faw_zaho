// lib/data/local/local_database.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '/core/services/analytics_service.dart';
import '/core/services/performance_tracker.dart';
import '/core/cache/prefs_manager.dart';

// النماذج + الـ Adapters
import '/data/models/office_model.dart';
import '/data/models/candidate_model.dart';
import '/data/models/faq_model.dart';
import '/data/models/news_model.dart';

// خدمة البيانات الوهمية الاحترافية (تضمن phoneNumber)
import '/data/mock/mock_data_service.dart';

class LocalDatabase {
  // الصناديق
  static late Box _appBox;
  static late Box _candidatesBox;
  static late Box _faqBox;
  static late Box _newsBox;
  static late Box _officesBox;

  static bool _isInitialized = false;
  static Completer<void>? _initCompleter;

  // مفاتيح التخزين داخل الصناديق
  static const String _candidatesKey = 'all_candidates';
  static const String _officesKey   = 'all_offices';
  static const String _newsKey      = 'all_news';
  static const String _faqsKey      = 'all_faqs';

  // Fallback (SharedPreferences) flags
  static bool _useFallbackStorage = false;
  static bool _fallbackInitialized = false;
  static const int _maxFallbackSize = 1024 * 1024; // 1MB per key

  // إدارة النسخة (Schema) – عند رفعها، نعمل حذف قاسٍ للصناديق القديمة
  static const int _schemaVersion = 3;

  // Getters
  static Box get appBox        => _appBox;
  static Box get candidatesBox => _candidatesBox;
  static Box get faqBox        => _faqBox;
  static Box get newsBox       => _newsBox;
  static Box get officesBox    => _officesBox;
  static bool get useFallbackStorage => _useFallbackStorage;

  static dynamic getAppData(String key) {
    if (!_isInitialized) return null;
    return _appBox.get(key);
  }

  // ============================
  //      Public API
  // ============================
  static Future<void> init() async {
    final sw = Stopwatch()..start();

    if (_isInitialized) {
      PerformanceTracker.track('LocalDatabase_Init_Cached', sw.elapsed);
      return;
    }

    _initCompleter ??= Completer<void>();
    if (_initCompleter!.isCompleted) {
      return _initCompleter!.future;
    }

    try {
      // ضروري قبل أي استخدام للـ PrefsManager
      await PrefsManager.init();

      // ترقية السكيمة: حذف الصناديق القديمة إذا تغيرت النسخة
      final localVersion = PrefsManager.getInt('db_schema_version') ?? 0;
      if (localVersion < _schemaVersion) {
        await hardReset(); // حذف الصناديق من القرص
        await PrefsManager.saveInt('db_schema_version', _schemaVersion);
      }

      await _initializeHiveWithImprovements(); // يفتح الصناديق
      await _initializeFallbackSystem();       // يجهّز الـ SharedPrefs كـ Fallback

      // لو الصناديق فاضية أول تشغيل، إملها من AdvancedMockService
      await _seedIfEmpty();

      _initCompleter!.complete();

      AnalyticsService.trackEvent('LocalDatabase_Initialized_Parallel', parameters: {
        'box_count': 5,
        'method': 'parallel',
        'fallback_enabled': _fallbackInitialized,
      });

      developer.log('✅ LocalDatabase initialized: 5 boxes, fallback=$_fallbackInitialized',
          name: 'CACHE');
    } catch (e) {
      AnalyticsService.trackEvent('LocalDatabase_Init_Failed',
          parameters: {'error': e.toString(), 'method': 'parallel'});

      // محاولة طوارئ لاستخدام fallback فقط
      await _emergencyFallbackInitialization(e);
      _initCompleter!.completeError(e);
      rethrow;
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Init', sw.elapsed);
    }

    return _initCompleter!.future;
  }

  /// حذف قاسٍ لكل الصناديق (للاستخدام عند تغيير السكيمة)
  static Future<void> hardReset() async {
    final names = ['app_data', 'candidates', 'offices', 'faqs', 'news'];
    for (final n in names) {
      if (Hive.isBoxOpen(n)) await Hive.box(n).close();
      await Hive.deleteBoxFromDisk(n);
    }
    developer.log('🧨 Hard reset: boxes deleted from disk', name: 'CACHE');
  }

  static Future<void> clearAll() async {
    final sw = Stopwatch()..start();
    try {
      if (_isInitialized && !_useFallbackStorage) {
        await _appBox.clear();
        await _candidatesBox.clear();
        await _faqBox.clear();
        await _newsBox.clear();
        await _officesBox.clear();
      }
      if (_fallbackInitialized) {
        final keys = [
          _candidatesKey, _faqsKey, _newsKey, _officesKey,
          'mock_data_generated', 'mock_data_timestamp'
        ];
        for (final k in keys) {
          await PrefsManager.remove(k);
        }
      }
      AnalyticsService.trackEvent('Cache_Cleared_All');
      developer.log('🗑️ All cache data cleared', name: 'CACHE');
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Clear_All', sw.elapsed);
    }
  }

  static Future<void> close() async {
    final sw = Stopwatch()..start();
    try {
      if (_isInitialized) {
        await Hive.close();
        _isInitialized = false;
        _initCompleter = null;
        _useFallbackStorage = false;
        AnalyticsService.trackEvent('Database_Closed');
        developer.log('🔒 Database closed', name: 'CACHE');
      }
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Close', sw.elapsed);
    }
  }

  // واجهة موحّدة للحفظ/الجلب مع fallback
  static Future<void> saveCandidates(List<dynamic> v) async => _saveList(_candidatesBox, _candidatesKey, v, 'Candidates');
  static List<dynamic>  getCandidates() => _getList(_candidatesBox, _candidatesKey, 'Candidates');

  static Future<void> saveFAQs(List<dynamic> v) async => _saveList(_faqBox, _faqsKey, v, 'FAQs');
  static List<dynamic>  getFAQs() => _getList(_faqBox, _faqsKey, 'FAQs');

  static Future<void> saveNews(List<dynamic> v) async => _saveList(_newsBox, _newsKey, v, 'News');
  static List<dynamic>  getNews() => _getList(_newsBox, _newsKey, 'News');

  static Future<void> saveOffices(List<dynamic> v) async => _saveList(_officesBox, _officesKey, v, 'Offices');
  static List<dynamic>  getOffices() => _getList(_officesBox, _officesKey, 'Offices');

  /// تُستخدم إذا احتجت توليد الوهمي يدويًا
  static Future<void> generateMockData({
    int candidatesCount = 50,
    int officesCount    = 20,
    int faqsCount       = 30,
    int newsCount       = 25,
  }) async {
    await AdvancedMockService.generateAndSaveMockData(
      saveToDatabase: true,
      candidatesCount: candidatesCount,
      officesCount: officesCount,
      faqsCount: faqsCount,
      newsCount: newsCount,
    );
  }

  // ============================
  //     Internal helpers
  // ============================
  static Future<void> _seedIfEmpty() async {
    final needCandidates = _candidatesBox.get(_candidatesKey) == null;
    final needOffices    = _officesBox.get(_officesKey)   == null;
    final needFaqs       = _faqBox.get(_faqsKey)          == null;
    final needNews       = _newsBox.get(_newsKey)         == null;

    if (needCandidates || needOffices || needFaqs || needNews) {
      await AdvancedMockService.generateAndSaveMockData(
        saveToDatabase: true,
        candidatesCount: 50,
        officesCount: 20,
        faqsCount: 30,
        newsCount: 25,
      );
      developer.log('💾 Mock data seeded (first run)', name: 'CACHE');
    }
  }

  static Future<void> _initializeHiveWithImprovements() async {
    final sw = Stopwatch()..start();
    try {
      final dir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(dir.path);

      // تسجيل Adapters
      Hive.registerAdapter(OfficeModelAdapter());
      Hive.registerAdapter(CandidateModelAdapter());
      Hive.registerAdapter(NewsModelAdapter());
      Hive.registerAdapter(FAQModelAdapter());

      final boxes = await _openBoxesWithTimeout();

      _appBox        = boxes[0];
      _candidatesBox = boxes[1];
      _faqBox        = boxes[2];
      _newsBox       = boxes[3];
      _officesBox    = boxes[4];

      _isInitialized = true;
      _useFallbackStorage = false;

      AnalyticsService.trackEvent('Hive_Initialization_Success',
          parameters: {'duration_ms': sw.elapsedMilliseconds});
      developer.log('✅ Hive initialized', name: 'CACHE');
    } catch (e) {
      AnalyticsService.trackEvent('Hive_Initialization_Failed', parameters: {'error': e.toString()});
      await _handleInitializationFallback(e is Exception ? e : Exception(e.toString()));
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Hive_Init', sw.elapsed);
    }
  }

  static Future<List<Box>> _openBoxesWithTimeout() async {
    final sw = Stopwatch()..start();
    try {
      final results = await Future.wait([
        _openBoxWithRetry('app_data',   maxRetries: 2),
        _openBoxWithRetry('candidates', maxRetries: 2),
        _openBoxWithRetry('faqs',       maxRetries: 2),
        _openBoxWithRetry('news',       maxRetries: 2),
        _openBoxWithRetry('offices',    maxRetries: 2),
      ]).timeout(const Duration(seconds: 10));

      AnalyticsService.trackEvent('Boxes_Opened_Parallel', parameters: {
        'box_count': results.length,
        'duration_ms': sw.elapsedMilliseconds
      });

      return results;
    } on TimeoutException {
      AnalyticsService.trackEvent('Boxes_Open_Timeout', parameters: {'fallback_method': 'sequential'});
      developer.log('⚠️ Parallel open timed out. Fallback to sequential.', name: 'CACHE');
      return _fallbackSequentialInit();
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Boxes_Open', sw.elapsed);
    }
  }

  static Future<List<Box>> _fallbackSequentialInit() async {
    final sw = Stopwatch()..start();
    try {
      final appBox        = await _openBoxWithRetry('app_data',   maxRetries: 1);
      final candidatesBox = await _openBoxWithRetry('candidates', maxRetries: 1);
      final faqBox        = await _openBoxWithRetry('faqs',       maxRetries: 1);
      final newsBox       = await _openBoxWithRetry('news',       maxRetries: 1);
      final officesBox    = await _openBoxWithRetry('offices',    maxRetries: 1);

      AnalyticsService.trackEvent('Boxes_Opened_Sequential',
          parameters: {'box_count': 5, 'duration_ms': sw.elapsedMilliseconds});

      return [appBox, candidatesBox, faqBox, newsBox, officesBox];
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Sequential_Fallback', sw.elapsed);
    }
  }

  static Future<Box> _openBoxWithRetry(String name, {int maxRetries = 2}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final box = await Hive.openBox(name);
        AnalyticsService.trackEvent('Box_Open_Success', parameters: {
          'box_name': name,
          'attempt': attempt + 1,
        });
        return box;
      } catch (e) {
        if (attempt == maxRetries) {
          AnalyticsService.trackEvent('Box_Open_Failed', parameters: {
            'box_name': name,
            'attempts': maxRetries + 1,
            'error': e.toString(),
          });
          rethrow;
        }
        AnalyticsService.trackEvent('Box_Open_Retry',
            parameters: {'box_name': name, 'attempt': attempt + 1});
        await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
      }
    }
    throw Exception('Failed to open box: $name');
  }

  static Future<void> _initializeFallbackSystem() async {
    final sw = Stopwatch()..start();
    try {
      // PrefsManager.init() تم استدعاؤها مسبقًا في init()
      _fallbackInitialized = true;

      // اختبار بسيط
      final probe = {'t': DateTime.now().millisecondsSinceEpoch};
      await PrefsManager.saveString('fallback_test', json.encode(probe));
      final ok = PrefsManager.getString('fallback_test');
      _fallbackInitialized = ok != null;

      if (_fallbackInitialized) {
        AnalyticsService.trackEvent('Fallback_System_Initialized');
        developer.log('✅ Fallback system ready', name: 'FALLBACK');
      } else {
        AnalyticsService.trackEvent('Fallback_System_Failed', parameters: {'error': 'probe_failed'});
      }
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Fallback_Init', sw.elapsed);
    }
  }

  static Future<void> _initializeFallbackStorage() async {
    final sw = Stopwatch()..start();
    try {
      await _initializeFallbackSystem();
      if (_fallbackInitialized) {
        _useFallbackStorage = true;
        developer.log('📦 Fallback storage activated', name: 'FALLBACK');
      }
      AnalyticsService.trackEvent('Fallback_Storage_Init');
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Fallback_Storage', sw.elapsed);
    }
  }

  static Future<void> _handleInitializationFallback(Exception error) async {
    developer.log('🔥 Hive init failed: $error', name: 'CACHE');
    AnalyticsService.trackEvent('Initialization_Fallback_Triggered',
        parameters: {'error': error.toString()});
    try {
      await _initializeFallbackStorage();
      _isInitialized = true;
      AnalyticsService.trackEvent('Fallback_Storage_Success');
      developer.log('✅ Fallback storage initialized', name: 'CACHE');
    } catch (fallbackError) {
      AnalyticsService.trackEvent('Fallback_Storage_Failed',
          parameters: {'error': fallbackError.toString()});
      await _cleanAndRetry();
    }
  }

  /// ✅ (NEW) دالة الطوارئ التي كانت ناقصة
  static Future<void> _emergencyFallbackInitialization(dynamic error) async {
    final sw = Stopwatch()..start();
    try {
      developer.log('🚨 Emergency Fallback Init', name: 'FALLBACK');
      await _initializeFallbackSystem();
      if (_fallbackInitialized) {
        _useFallbackStorage = true;
        _isInitialized = true;
        AnalyticsService.trackEvent('Emergency_Fallback_Activated',
            parameters: {'error': error.toString()});
        developer.log('✅ Emergency fallback activated', name: 'FALLBACK');
      }
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Emergency_Fallback', sw.elapsed);
    }
  }

  // ============================
  //   Generic save/get + fallback
  // ============================
  static Future<void> _saveList(Box box, String key, List<dynamic> data, String label) async {
    final sw = Stopwatch()..start();
    try {
      await _ensureInitialized();
      if (!_useFallbackStorage) {
        try {
          await box.put(key, data);
          await _saveToSharedPrefsFallback(key, data);
        } catch (_) {
          await _saveToSharedPrefsFallback(key, data);
          _useFallbackStorage = true;
        }
      } else {
        await _saveToSharedPrefsFallback(key, data);
      }
      AnalyticsService.trackEvent('${label}_Saved', parameters: {
        'count': data.length,
        'storage_type': _useFallbackStorage ? 'fallback' : 'hive',
      });
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Save_$label', sw.elapsed);
    }
  }

  static List<dynamic> _getList(Box box, String key, String label) {
    final sw = Stopwatch()..start();
    try {
      if (!_isInitialized) return [];
      dynamic out;
      if (!_useFallbackStorage) {
        try {
          out = box.get(key, defaultValue: []);
        } catch (_) {
          out = _getFromSharedPrefsFallback(key) ?? [];
          _useFallbackStorage = true;
        }
      } else {
        out = _getFromSharedPrefsFallback(key) ?? [];
      }
      AnalyticsService.trackEvent('${label}_Retrieved', parameters: {
        'count': (out as List).length,
        'storage_type': _useFallbackStorage ? 'fallback' : 'hive',
      });
      return out;
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Get_$label', sw.elapsed);
    }
  }

  // ============================
  //   SharedPrefs Fallback I/O
  // ============================
  static Future<void> _saveToSharedPrefsFallback(String key, dynamic data) async {
    final sw = Stopwatch()..start();
    try {
      if (!_fallbackInitialized) throw Exception('Fallback not initialized');
      final s = json.encode(data);
      if (s.length > _maxFallbackSize) {
        AnalyticsService.trackEvent('Fallback_Data_Too_Large',
            parameters: {'key': key, 'size': s.length});
        throw Exception('Data too large for fallback');
      }
      await PrefsManager.saveString(key, s);
      AnalyticsService.trackEvent('Fallback_Save_Success',
          parameters: {'key': key, 'data_size': s.length});
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Fallback_Save', sw.elapsed);
    }
  }

  static dynamic _getFromSharedPrefsFallback(String key) {
    final sw = Stopwatch()..start();
    try {
      if (!_fallbackInitialized) return null;
      final s = PrefsManager.getString(key);
      if (s == null) return null;
      return json.decode(s);
    } finally {
      sw.stop();
      PerformanceTracker.track('LocalDatabase_Fallback_Get', sw.elapsed);
    }
  }

  // ============================
  //     Utilities
  // ============================
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  static Future<void> _cleanAndRetry() async {
    try {
      await Hive.close();
      await hardReset();
    } catch (_) {}
    _isInitialized = false;
    _initCompleter = null;
    await init();
  }

  static Map<String, dynamic> getStorageStatus() {
    return {
      'hive_initialized': _isInitialized,
      'fallback_initialized': _fallbackInitialized,
      'using_fallback': _useFallbackStorage,
      'boxes_ready': _isInitialized && !_useFallbackStorage,
      'storage_type': _useFallbackStorage ? 'shared_preferences' : 'hive',
    };
  }
}
