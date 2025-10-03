import 'package:al_faw_zakho/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/providers/theme_provider.dart';
import '/core/providers/language_provider.dart';
import '/core/services/analytics_service.dart';

/// 🎯 شاشة الإعدادات المحسنة - تدعم العربية والإنجليزية فقط
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: const _SettingsBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        context.tr('settings'),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      elevation: 2,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: const [
        _AppearanceSection(),
        SizedBox(height: 24),
        _LanguageSection(),
        SizedBox(height: 24),
        _AboutSection(),
        SizedBox(height: 32),
        _AppVersionFooter(),
      ],
    );
  }
}

/// 🎨 قسم المظهر
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: context.tr('appearance'),
      icon: Icons.palette,
      children: [
        _SettingCard(
          child: _ThemeSwitchTile(),
        ),
      ],
    );
  }
}

/// 🌍 قسم اللغة
class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: context.tr('language'),
      icon: Icons.language,
      children: [
        _SettingCard(
          child: _LanguageSelectionTile(),
        ),
      ],
    );
  }
}

/// ℹ️ قسم حول التطبيق
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: context.tr('about_app'),
      icon: Icons.info,
      children: [
        _SettingCard(
          child: _AppInfoDetails(),
        ),
      ],
    );
  }
}

/// 🏗️ مكون قسم الإعدادات
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العنوان مع الأيقونة
        Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        // المحتوى
        ...children,
      ],
    );
  }
}

/// 🎴 بطاقة الإعدادات
class _SettingCard extends StatelessWidget {
  final Widget child;

  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.
          //withOpacity(0.1),
          withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

/// 🔄 زر تبديل السمة المحسن
class _ThemeSwitchTile extends StatefulWidget {
  @override
  State<_ThemeSwitchTile> createState() => _ThemeSwitchTileState();
}

class _ThemeSwitchTileState extends State<_ThemeSwitchTile> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.
          //withOpacity(0.1),
          withValues(alpha:0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: Colors.orange,
          size: 22,
        ),
      ),
      title: Text(
        context.tr('dark_mode'),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        isDark ? context.tr('enabled') : context.tr('disabled'),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).hintColor,
        ),
      ),
      trailing: _buildSwitch(themeProvider, isDark),
      onTap: () => _handleThemeToggle(themeProvider, !isDark),
    );
  }

  Widget _buildSwitch(ThemeProvider themeProvider, bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isToggling
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 48,
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            )
          : Switch.adaptive(
              key: const ValueKey('switch'),
              value: isDark,
              onChanged: (value) => _handleThemeToggle(themeProvider, value),
            ),
    );
  }

  Future<void> _handleThemeToggle(ThemeProvider themeProvider, bool value) async {
    if (_isToggling) return;

    AnalyticsService.trackEvent('theme_toggled', parameters: {
      'from': themeProvider.themeMode.toString(),
      'to': value ? 'dark' : 'light',
    });

    setState(() => _isToggling = true);

    try {
      await Future.delayed(const Duration(milliseconds: 200)); // محاكاة التأخير
      await themeProvider.setTheme(value ? ThemeMode.dark : ThemeMode.light);
    } catch (e) {
      _showErrorSnackBar(context, 'فشل تغيير السمة');
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// 🌍 خيار اختيار اللغة المحسن
class _LanguageSelectionTile extends StatefulWidget {
  @override
  State<_LanguageSelectionTile> createState() => _LanguageSelectionTileState();
}

class _LanguageSelectionTileState extends State<_LanguageSelectionTile> {
  bool _isChangingLanguage = false;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.languageCode;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.
          //withOpacity(0.1),
          withValues(alpha:0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.translate,
          color: Colors.blue,
          size: 22,
        ),
      ),
      title: Text(
        context.tr('language'),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _getLanguageDisplayName(currentLanguage),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).hintColor,
        ),
      ),
      trailing: _buildLanguageDropdown(languageProvider),
    );
  }

  Widget _buildLanguageDropdown(LanguageProvider languageProvider) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isChangingLanguage
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).primaryColor,
              ),
            )
          : DropdownButtonHideUnderline(
              key: const ValueKey('dropdown'),
              child: DropdownButton<String>(
                value: languageProvider.languageCode,
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                elevation: 2,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onChanged: _handleLanguageChange,
                items: _buildLanguageItems(),
              ),
            ),
    );
  }

  List<DropdownMenuItem<String>> _buildLanguageItems() {
    return [
      DropdownMenuItem(
        value: 'ar',
        child: Row(
          children: [
            const Text('🇸🇦'),
            const SizedBox(width: 8),
            Text(context.tr('arabic')),
          ],
        ),
      ),
      DropdownMenuItem(
        value: 'en',
        child: Row(
          children: [
            const Text('🇺🇸'),
            const SizedBox(width: 8),
            Text(context.tr('english')),
          ],
        ),
      ),
    ];
  }

  Future<void> _handleLanguageChange(String? newLanguageCode) async {
    if (newLanguageCode == null || _isChangingLanguage) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (newLanguageCode == languageProvider.languageCode) return;

    AnalyticsService.trackEvent('language_changed', parameters: {
      'from': languageProvider.languageCode,
      'to': newLanguageCode,
    });

    setState(() => _isChangingLanguage = true);

    try {
      await languageProvider.setLanguage(newLanguageCode);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('language_changed')),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingLanguage = false);
      }
    }
  }

  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'ar': return context.tr('arabic');
      case 'en': return context.tr('english');
      default: return context.tr('arabic');
    }
  }
}

/// 📱 معلومات التطبيق المحسنة
class _AppInfoDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان والشعار
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.
                    //withOpacity(0.1),
                    withValues(alpha:0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flag,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('app_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('political_election'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          // معلومات الإصدار
          _InfoRow(
            icon: Icons.verified,
            label: context.tr('version'),
            value: '1.0.0',
          ),
          _InfoRow(
            icon: Icons.build,
            label: context.tr('build'),
            value: '2024.10.01',
          ),
          _InfoRow(
            icon: Icons.update,
            label: 'آخر تحديث',
            value: 'يناير 2024',
          ),
          _InfoRow(
            icon: Icons.security,
            label: 'الحالة',
            value: 'مستقر',
          ),
        ],
      ),
    );
  }
}

/// 📊 صف المعلومات
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔚 تذييل الإصدار
class _AppVersionFooter extends StatelessWidget {
  const _AppVersionFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Al-Faw Zakhо Gathering © 2024',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'جميع الحقوق محفوظة',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}
