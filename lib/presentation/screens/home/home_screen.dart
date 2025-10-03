import 'dart:async';
import 'dart:developer' as developer;
import 'package:al_faw_zakho/core/localization/app_localizations.dart';
import 'package:al_faw_zakho/presentation/screens/provinces/provinces_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/providers/connectivity_provider.dart';
import '/core/providers/language_provider.dart';
import '/core/providers/app_provider.dart';
import '/core/services/analytics_service.dart';
import '/data/local/local_database.dart';
import '/presentation/screens/offices/offices_screen.dart';
import '/presentation/screens/faq/faq_screen.dart';
import '/presentation/screens/settings/settings_screen.dart';
import '/presentation/screens/home/widgets/news_ticker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPreloadingData = false;
  double _preloadProgress = 0.0;
  late AppProvider _appProvider;

  @override
  void initState() {
    super.initState();
    _appProvider = Provider.of<AppProvider>(context, listen: false);
    _preloadData();
  }

  Future<void> _preloadData() async {
    if (_isPreloadingData) return;
    
    setState(() {
      _isPreloadingData = true;
      _preloadProgress = 0.0;
    });

    try {
      await _executeParallelPreloading();
    } catch (e) {
      developer.log('Preloading error: $e', name: 'ERROR');
    } finally {
      if (mounted) {
        setState(() {
          _isPreloadingData = false;
          _preloadProgress = 1.0;
        });
      }
    }
  }

  Future<void> _executeParallelPreloading() async {
    const totalSteps = 4;
    int completedSteps = 0;

    final preloadTasks = [
      _preloadCandidates().then((_) => _updateProgress(++completedSteps, totalSteps)),
      _preloadOffices().then((_) => _updateProgress(++completedSteps, totalSteps)),
      _preloadFAQs().then((_) => _updateProgress(++completedSteps, totalSteps)),
      _preloadNews().then((_) => _updateProgress(++completedSteps, totalSteps)),
    ];

    await Future.wait(preloadTasks.map((task) => task.catchError((e) {
      developer.log('Preload task error: $e', name: 'WARNING');
      return null;
    })), eagerError: false);
  }

  void _updateProgress(int current, int total) {
    if (!mounted) return;
    
    setState(() {
      _preloadProgress = current / total;
    });
  }

  Future<void> _preloadCandidates() async {
    try {
      final candidates = LocalDatabase.getCandidates();
      if (candidates.isEmpty) {
        developer.log('Generating mock candidates...', name: 'DATA');
     // ✅ أضف هذا السطر لاستخدام _appProvider
      await _appProvider.generateMockData();
      }
    } catch (e) {
      developer.log('Candidate preload failed: $e', name: 'ERROR');
    }
  }

  Future<void> _preloadOffices() async {
    try {
      final offices = LocalDatabase.getOffices();
      if (offices.isEmpty) {
        developer.log('Generating mock offices...', name: 'DATA');
      }
    } catch (e) {
      developer.log('Offices preload failed: $e', name: 'ERROR');
    }
  }

  Future<void> _preloadFAQs() async {
    try {
      final faqs = LocalDatabase.getFAQs();
      if (faqs.isEmpty) {
        developer.log('Generating mock FAQs...', name: 'DATA');
      }
    } catch (e) {
      developer.log('FAQs preload failed: $e', name: 'ERROR');
    }
  }

  Future<void> _preloadNews() async {
    try {
      final news = LocalDatabase.getNews();
      if (news.isEmpty) {
        developer.log('Generating mock news...', name: 'DATA');
      }
    } catch (e) {
      developer.log('News preload failed: $e', name: 'ERROR');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreloadingData) {
      return _buildLoadingScreen(context);
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWelcomeMessage(context),
            const SizedBox(height: 30),
            CircularProgressIndicator(
              value: _preloadProgress,
              strokeWidth: 6,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              _getLoadingText(context),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              '${(_preloadProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

// ✅ تعديل دالة البناء لاستخدام اللغة المختارة
Widget _buildWelcomeMessage(BuildContext context) {
  return Consumer<LanguageProvider>(
    builder: (context, languageProvider, child) {
      // ✅ استخدام languageCode (المختارة) بدلاً من locale.languageCode (الفعلية)
      final welcomeText = _getWelcomeText(languageProvider.languageCode);
      return Text(
        welcomeText,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      );
    },
  );
}

  String _getLoadingText(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(
      context, listen: false);
    //final languageCode = languageProvider.locale.languageCode;
  final languageCode = languageProvider.languageCode; // ✅ اللغة المختارة

    switch (languageCode) {
      case 'ar': return 'جاري تحميل البيانات...';
      case 'en': return 'Loading data...';
      default: return 'جاري تحميل البيانات...';
    }
  }

  String _getWelcomeText(String languageCode) {
    switch (languageCode) {
      case 'ar': return 'مرحباً بكم في تجمع الفاو زاخو';
      case 'en': return 'Welcome to Faw Zakhо Gathering';
      default: return 'مرحباً بكم في تجمع الفاو زاخو';
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
    title: Text(context.appTitle),
      centerTitle: true,
      actions: [
        _buildConnectionIndicator(context),
        _buildSettingsButton(context),
      ],
    );
  }

  Widget _buildConnectionIndicator(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
         // أخفِ الأيقونة نهائياً عند الاتصال
      //if (connectivity.isOnline) return const SizedBox.shrink();
        return Icon(
          connectivity.isOnline ? Icons.wifi : Icons.signal_wifi_off,
          color: connectivity.isOnline ? Colors.green : Colors.orange,
        );
      },
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        Navigator.push(context, 
          MaterialPageRoute(builder: (_) => const SettingsScreen())); // ✅ تم التصحيح
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
             // _buildConnectionStatus(connectivity.isOnline, context),
             // const SizedBox(height: 16),
              
              if (connectivity.isOnline) ...[
                _buildNewsTickerWidget(context),
                const SizedBox(height: 16),
              ],
              
              _buildWelcomeCard(context),
              const SizedBox(height: 20),
              
              Expanded(
                child: _buildCategoryGrid(context),
              ),
            ],
          ),
        );
      },
    );
  }

 /* Widget _buildConnectionStatus(bool isOnline, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        //color: isOnline ? Colors.green[50] : Colors.orange[50],
       // borderRadius: BorderRadius.circular(8),
        //border: Border.all(color: isOnline ? Colors.green : Colors.orange),
      ),
      /*child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
         /* Icon(
            isOnline ? Icons.wifi : Icons.signal_wifi_off,
            color: isOnline ? Colors.green : Colors.orange,
          ),*/
          /* const SizedBox(width: 8),
           Text(isOnline ? context.tr('online') : context.tr('offline'),
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),*/
        ],
      ),*/
    );
  }*/

  Widget _buildNewsTickerWidget(BuildContext context) {
    return const NewsTicker();
  }

  Widget _buildWelcomeCard(BuildContext context) {
  return Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          //const Icon(Icons.flag, size: 48, color: Colors.blue),
          Image.asset(
            'assets/images/logo.png', // مسار الصورة التي رفعتها
            width: 70, // يمكنك تعديل العرض والارتفاع حسب الحاجة
            height: 70,), 
          const SizedBox(height: 1),
          // ✅ استخدام الترجمة بدلاً من النص الثابت
          Text(
            context.appTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(
            context.tr('political_election'), // أو إضافة وصف جديد في الترجمة
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

 Widget _buildCategoryGrid(BuildContext context) {
  return GridView.count(
    crossAxisCount: 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: 1.0,
    children: [
      _buildSmartCategoryCard(
        title: context.candidates, // ✅ مترجم
        icon: Icons.people_alt,
        color: Colors.blue,
        category: 'candidates',
        badgeCount: _getCandidatesCount(),
        context: context,
      ),
      _buildSmartCategoryCard(
        title: context.offices, // ✅ إصلاح: استخدام الترجمة
        icon: Icons.business,
        color: Colors.blue,
        category: 'offices',
        badgeCount: _getOfficesCount(),
        context: context,
      ),
      _buildSmartCategoryCard(
        title: context.faq, // ✅ إصلاح: استخدام الترجمة
        icon: Icons.question_answer,
        color: Colors.blue,
        category: 'faq',
        badgeCount: _getFAQsCount(),
        context: context,
      ),
      _buildSmartCategoryCard(
        title: context.settings, // ✅ إصلاح: استخدام الترجمة
        icon: Icons.settings,
        color: Colors.blue,
        category: 'settings',
        badgeCount: _getNewsCount(),
        context: context,
      ),
    ],
  );
}

  Widget _buildSmartCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required String category,
    required BuildContext context,
    int? badgeCount,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _handleCategoryTap(category, context),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25), // 25 ≈ 0.1 * 255

                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleCategoryTap(String category, BuildContext context) {
    AnalyticsService.trackEvent('home_category_tapped', 
      parameters: {'category': category});
    
    switch (category) {
      case 'candidates':
        Navigator.push(context, 
          MaterialPageRoute(builder: (_) => const ProvincesScreen()));
        break;
      case 'offices':
        Navigator.push(context, 
          MaterialPageRoute(builder: (_) => const OfficesScreen()));
        break;
      case 'faq':
        Navigator.push(context, 
          MaterialPageRoute(builder: (_) => const FAQScreen()));
        break;
      case 'settings':
        Navigator.push(context, 
          MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
    }
  }

  int _getCandidatesCount() => LocalDatabase.getCandidates().length;
  int _getOfficesCount() => LocalDatabase.getOffices().length;
  int _getFAQsCount() => LocalDatabase.getFAQs().length;
  int _getNewsCount() => LocalDatabase.getNews().length;
}

