import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/network_config.dart';

class OnboardingQuestion {
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> options;
  final bool isDynamic;

  OnboardingQuestion({
    required this.title,
    required this.subtitle,
    required this.options,
    this.isDynamic = false,
  });
}

class OnboardingProvider extends ChangeNotifier {
  final String _baseUrl = NetworkConfig.baseUrl;

  final List<OnboardingQuestion> _questions = [
    OnboardingQuestion(
      title: 'Who are you?',
      subtitle: 'Tell us a bit about your background so we can tailor our advice.',
      options: [
        {'title': 'Student', 'icon': Icons.school_outlined, 'desc': 'Exploring entrepreneurship'},
        {'title': 'Employee', 'icon': Icons.work_outline_rounded, 'desc': 'Looking to start a side hustle'},
        {'title': 'First-time Seller', 'icon': Icons.rocket_launch_outlined, 'desc': 'Building my first store'},
        {'title': 'Experienced Seller', 'icon': Icons.loop_rounded, 'desc': 'I have built stores before'},
      ],
    ),
    OnboardingQuestion(
      title: 'What is your experience level?',
      subtitle: 'This helps the AI set the right tone and depth for answers.',
      options: [
        {'title': 'Beginner', 'icon': Icons.trending_flat_rounded, 'desc': 'I am new to e-commerce'},
        {'title': 'Intermediate', 'icon': Icons.trending_up_rounded, 'desc': 'I know the basics and have some experience'},
        {'title': 'Expert', 'icon': Icons.auto_graph_rounded, 'desc': 'I am well-versed in building and scaling businesses'},
      ],
    ),
    OnboardingQuestion(
      title: 'What stage are you at?',
      subtitle: 'Let us know where your store currently stands.',
      options: [
        {'title': 'Just a Product Concept', 'icon': Icons.lightbulb_outline_rounded, 'desc': 'I have a product in mind'},
        {'title': 'Building MVP', 'icon': Icons.construction_rounded, 'desc': 'I am actively building the first version'},
        {'title': 'Launched', 'icon': Icons.flight_takeoff_rounded, 'desc': 'Product is live with some users'},
        {'title': 'Scaling', 'icon': Icons.insights_rounded, 'desc': 'We are growing and generating revenue'},
      ],
    ),
  ];

  final Map<String, String> _answers = {};
  bool _isGenerating = false;
  bool _isComplete = false;

  List<OnboardingQuestion> get questions => _questions;
  Map<String, String> get answers => _answers;
  bool get isGenerating => _isGenerating;
  bool get isComplete => _isComplete;

  void saveAnswer(String questionTitle, String answer) {
    _answers[questionTitle] = answer;
    notifyListeners();
  }

  /// Calls the backend to generate the next personalized onboarding question.
  /// Returns [true] if a new question was added, or [false] if onboarding is complete.
  Future<bool> generateNextQuestion() async {
    _isGenerating = true;
    notifyListeners();

    try {
      final dynamicQuestionsAsked = _questions.where((q) => q.isDynamic).length;
      
      final response = await http.post(
        Uri.parse('$_baseUrl/onboarding/next-question'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer mock-token',
        },
        body: jsonEncode({
          'answeredQuestions': _answers,
          'questionsAsked': dynamicQuestionsAsked,
        }),
      );

      _isGenerating = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null && body['data']['question'] != null) {
          final q = body['data']['question'];
          
          // Map options and icons
          final List<dynamic> rawOptions = q['options'] ?? [];
          final optionsList = rawOptions.map((opt) {
            final title = opt['title'] as String;
            return {
              'title': title,
              'desc': opt['desc'] as String,
              'icon': _getIconForOption(title),
            };
          }).toList();

          _questions.add(
            OnboardingQuestion(
              title: q['title'] as String,
              subtitle: q['subtitle'] as String,
              isDynamic: true,
              options: optionsList,
            ),
          );
          
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error generating next onboarding question: $e');
    }

    _isGenerating = false;
    notifyListeners();
    return false;
  }

  /// Completes the onboarding by saving all responses to the backend database.
  Future<void> completeOnboardingOnBackend() async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/onboarding/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer mock-token',
        },
        body: jsonEncode({
          'answers': _answers,
        }),
      );
      
      // Also initialize a profile on the backend using the responses
      await http.post(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer mock-token',
        },
        body: jsonEncode({
          'storeName': _answers['Store Name'] ?? 'My E-commerce Store',
          'industry': _answers['E-Commerce Category'] ?? 'General E-commerce',
          'targetAudience': _answers['Target Audience'] ?? 'General Public',
          'budget': _answers['Start-up Budget'] ?? 'Not Specified',
          'experienceLevel': _answers['What is your experience level?'] ?? 'Beginner',
          'stage': _answers['What stage are you at?'] ?? 'Concept',
        }),
      );
    } catch (e) {
      debugPrint('Error completing onboarding on backend: $e');
    }

    _isComplete = true;
    notifyListeners();
  }

  void completeOnboarding() {
    _isComplete = true;
    notifyListeners();
  }

  static IconData _getIconForOption(String title) {
    final t = title.toLowerCase();
    if (t.contains('physical') || t.contains('goods')) return Icons.inventory_2_outlined;
    if (t.contains('digital') || t.contains('course')) return Icons.download_rounded;
    if (t.contains('dropship')) return Icons.local_shipping_outlined;
    if (t.contains('service')) return Icons.design_services_outlined;
    if (t.contains('subscription')) return Icons.card_giftcard_rounded;
    if (t.contains('gen z') || t.contains('millennial')) return Icons.people_outline;
    if (t.contains('parent') || t.contains('family')) return Icons.family_restroom_rounded;
    if (t.contains('professional') || t.contains('b2b')) return Icons.business_center_outlined;
    if (t.contains('active') || t.contains('fitness')) return Icons.directions_run_rounded;
    if (t.contains('budget') || t.contains('under') || t.contains('lean')) return Icons.wallet_giftcard;
    if (t.contains('growth') || t.contains('2,500')) return Icons.trending_up_rounded;
    if (t.contains('established') || t.contains('10,000')) return Icons.store_mall_directory_outlined;
    if (t.contains('scale') || t.contains('brand')) return Icons.auto_graph_rounded;
    return Icons.help_outline_rounded;
  }
}
