
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '/core/network/api_client.dart';
import '/data/mock/mock_data_service.dart' as mock_service;

class AppProvider extends ChangeNotifier {
  ApiClient? _apiClient;
  mock_service.AdvancedMockService? _mockService;
  bool _isAppInitialized = false;
  String? _initializationError;
  String _dataState = 'initial';

  bool get isAppInitialized => _isAppInitialized;
  String? get initializationError => _initializationError;
  String get dataState => _dataState;

  void setApiClient(ApiClient apiClient) {
    _apiClient = apiClient;
  }

  void setMockDataService(mock_service.AdvancedMockService service) {
    _mockService = service;
    developer.log('[AppProvider] MockDataService set successfully', name: 'PROVIDER');
  }

  Future<void> generateMockData({bool forceRefresh = false, bool demoMode = false}) async {
    try {
      developer.log('[AppProvider] Generating mock data...', name: 'DATA');
      _dataState = 'generating';
      notifyListeners();


      await mock_service.AdvancedMockService.generateAndSaveMockData(
        saveToDatabase: true,
      );

        _dataState = 'mock_data_loaded';
        developer.log('[AppProvider] Mock data generated successfully', name: 'DATA');
      notifyListeners();

    } catch (e) {
      _dataState = 'error';
      developer.log('[AppProvider] Error generating mock data: $e', name: 'ERROR', error: e);
      rethrow;
    }
  }

  Future<void> loadFreshData() async {
    try {
      developer.log('[AppProvider] Loading fresh data from API...', name: 'DATA');
      _dataState = 'loading';
      notifyListeners();

      // ✅ محاكاة تحميل البيانات من API
      await Future.delayed(const Duration(seconds: 2));
      
      // هنا سيتم استدعاء API Client عندما يكون جاهزاً
      if (_apiClient != null) {
        // await _apiClient!.get('/candidates');
        developer.log('[AppProvider] API data loaded successfully', name: 'DATA');
      }
      
      _dataState = 'fresh_data_loaded';
      notifyListeners();
    } catch (e) {
      _dataState = 'error';
      developer.log('[AppProvider] Error loading fresh data: $e', name: 'ERROR', error: e);
      rethrow;
    }
  }

  Future<void> initializeApp({
    required Future<void> Function() initializeConnectivity,
    required Future<void> Function() initializeTheme,
    required Future<void> Function() initializeLanguage,
  }) async {
    try {
      developer.log('[AppProvider] Starting app initialization...', name: 'INIT');
      
      await initializeConnectivity();
      await initializeTheme();
      await initializeLanguage();

      if (_apiClient != null) {
        developer.log('[AppProvider] API Client is available', name: 'API');
      }

      if (_mockService != null) {
        developer.log('[AppProvider] MockDataService is available', name: 'MOCK');
      }

      _isAppInitialized = true;
      _dataState = 'app_initialized';
      notifyListeners();
      
      developer.log('[AppProvider] App initialization completed ✅', name: 'INIT');
    } catch (e) {
      _initializationError = e.toString();
      _dataState = 'initialization_error';
      notifyListeners();
      developer.log('[AppProvider] Initialization error: $e', name: 'ERROR', error: e);
      rethrow;
    }
  }

  void resetInitialization() {
    _isAppInitialized = false;
    _initializationError = null;
    _dataState = 'initial';
    notifyListeners();
  }
}
