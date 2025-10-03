// lib/presentation/screens/faq/faq_screen.dart
import 'package:flutter/material.dart';
import '/data/local/local_database.dart';
import '/core/services/analytics_service.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  List<dynamic> _faqs = [];

  @override
  void initState() {
    super.initState();
    _loadFAQs();
    AnalyticsService.trackEvent('faq_screen_opened');
  }

  void _loadFAQs() {
    setState(() {
      _faqs = LocalDatabase.getFAQs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأسئلة الشائعة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFAQs,
          ),
        ],
      ),
      body: _faqs.isEmpty
          ? const Center(child: Text('لا يوجد أسئلة متاحة حالياً'))
          : ListView.builder(
              itemCount: _faqs.length,
              itemBuilder: (context, index) {
                final faq = _faqs[index];
                return ExpansionTile(
                  leading: const Icon(Icons.question_answer, color: Colors.orange),
                  title: Text(faq.questionAr),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(faq.answerAr),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
