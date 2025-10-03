// lib/presentation/screens/provinces/provinces_screen.dart
import 'package:flutter/material.dart';
import '../candidates/candidates_by_province_screen.dart';

import '/core/localization/app_localizations.dart';
import '/core/services/analytics_service.dart';
import '/data/static/iraqi_provinces.dart';

class ProvincesScreen extends StatelessWidget {
  const ProvincesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('provinces')),
        centerTitle: true,
      ),
      body: const _ProvincesList(),
    );
  }
}

class _ProvincesList extends StatelessWidget {
  const _ProvincesList();

  @override
  Widget build(BuildContext context) {
    final provinces = IraqiProvinces.allProvinces;

    return ListView.builder(
      itemCount: provinces.length,
      itemBuilder: (context, index) {
        final province = provinces[index];
        return _ProvinceCard(
          province: province,
          onTap: () {
            AnalyticsService.trackEvent('province_selected', parameters: {
              'province': province,
            });
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CandidatesByProvinceScreen(province: province),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProvinceCard extends StatelessWidget {
  final String province;
  final VoidCallback onTap;

  const _ProvinceCard({
    required this.province,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_city,
            color: Colors.blue.shade700,
            size: 24,
          ),
        ),
        title: Text(
          province,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${context.tr('our_candidates_in')} $province',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
