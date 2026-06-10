import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/network_config.dart';

class OnboardingQuestion {
  final String id;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> options;
  final bool isDynamic;
  final String type; // 'text' | 'single' | 'multi' | 'text_search'
  final bool stopAfterThis;

  OnboardingQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.options,
    this.isDynamic = false,
    this.type = 'single',
    this.stopAfterThis = false,
  });
}

class OnboardingProvider extends ChangeNotifier {
  final String _baseUrl = NetworkConfig.baseUrl;

  // ── Static "bootstrap" questions (always first) ─────────────────────────────
  // After these 2, we fetch AI-generated questions from backend
  late final List<OnboardingQuestion> _staticQuestions = [
    OnboardingQuestion(
      id: 'name',
      title: 'What\'s your full name?',
      subtitle: 'Let\'s start with how we should address you.',
      type: 'text',
      options: [],
    ),
    OnboardingQuestion(
      id: 'location',
      title: 'Which city are you based in?',
      subtitle: 'This helps us tailor ideas to your local market.',
      type: 'text_search',
      options: [],
    ),
  ];

  List<OnboardingQuestion> _aiQuestions = [];
  final Map<String, List<String>> _answers = {};

  bool _isGenerating = false;   // Used during final idea generation
  bool _isQuestionsLoading = false; // Loading next AI question
  bool _isSubmitting = false;   // Guard against duplicate submissions
  bool _isComplete = false;
  bool _isIdeaMode = false;
  int _aiQuestionsAsked = 0;

  List<OnboardingQuestion> get questions {
    final neededStatic = _staticQuestions.where((q) {
      if (_isIdeaMode && _answers.containsKey(q.title) && _answers[q.title]!.isNotEmpty) {
        return false;
      }
      return true;
    }).toList();
    return [...neededStatic, ..._aiQuestions];
  }
  
  Map<String, List<String>> get answers => _answers;
  bool get isGenerating => _isGenerating;
  bool get isQuestionsLoading => _isQuestionsLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isComplete => _isComplete;
  bool get isIdeaMode => _isIdeaMode;
  int get aiQuestionsAsked => _aiQuestionsAsked;

  /// Pre-fill the user's name from Google sign-in or email
  void preFillNameFromAuth() {
    final user = FirebaseAuth.instance.currentUser;
    var displayName = user?.displayName ?? '';
    
    // Fallback to email if display name is empty
    if (displayName.isEmpty && user?.email != null) {
      displayName = user!.email!.split('@').first;
      if (displayName.isNotEmpty) {
        displayName = displayName[0].toUpperCase() + displayName.substring(1);
      }
    }
    
    if (displayName.isNotEmpty) {
      _answers['What\'s your full name?'] = [displayName];
      notifyListeners();
    }
  }

  void saveAnswer(String questionTitle, String answer) {
    _answers[questionTitle] = [answer];
    notifyListeners();
  }

  void toggleAnswer(String questionTitle, String answer) {
    final list = _answers[questionTitle] ?? [];
    if (list.contains(answer)) {
      list.remove(answer);
    } else {
      list.add(answer);
    }
    _answers[questionTitle] = list;
    notifyListeners();
  }

  void saveTextAnswer(String questionTitle, String text) {
    if (text.trim().isEmpty) {
      _answers.remove(questionTitle);
    } else {
      _answers[questionTitle] = [text.trim()];
    }
    notifyListeners();
  }

  /// Fetch the next AI-generated question from backend.
  /// Returns true if a new question was added; false if complete.
  Future<bool> generateNextQuestion() async {
    // We only ask Name and Location initially, so immediately proceed to idea generation.
    return false;
  }

  Map<String, String> get flatAnswers {
    final result = <String, String>{};
    _answers.forEach((key, value) {
      result[key] = value.join(', ');
    });
    return result;
  }

  /// Alias for backward compatibility
  Map<String, List<String>> get visibleAnswers => Map.unmodifiable(_answers);


  Future<void> completeOnboardingOnBackend() async {
    _isGenerating = true;
    notifyListeners();

    try {
      final response1 = await http.post(
        Uri.parse('$_baseUrl/onboarding/complete'),
        headers: await NetworkConfig.getHeaders(),
        body: jsonEncode({'answers': flatAnswers}),
      ).timeout(const Duration(seconds: 12));

      if (response1.statusCode != 200) {
        throw Exception('Failed to complete onboarding on backend.');
      }

      final name = _answers['What\'s your full name?']?.first ?? 'My';
      final response2 = await http.post(
        Uri.parse('$_baseUrl/profile'),
        headers: await NetworkConfig.getHeaders(),
        body: jsonEncode({
          'storeName': '$name\'s Store',
          'industry': _answers['Choose Business Domains']?.join(', ') ?? 'General',
          'targetAudience': 'General Public',
          'budget': _answers['What is your startup budget?']?.first ?? 'Not Specified',
          'experienceLevel': 'Beginner',
          'stage': 'Concept',
        }),
      ).timeout(const Duration(seconds: 12));
      
      if (response2.statusCode != 200) {
        throw Exception('Failed to create profile.');
      }
    } catch (e) {
      _isGenerating = false;
      notifyListeners();
      debugPrint('Error completing onboarding on backend: $e');
      rethrow;
    }

    _isGenerating = false;
    _isComplete = true;
    notifyListeners();
  }

  /// Set submitting guard to prevent duplicate calls
  void setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  Future<void> resetForNewIdea() async {
    _aiQuestions.clear();
    _aiQuestionsAsked = 0;
    _isGenerating = false;
    _isQuestionsLoading = false;
    _isSubmitting = false;
    _isComplete = false;
    _isIdeaMode = true;
    
    // Retain only static answers (Name and Location)
    final name = _answers['What\'s your full name?'];
    final location = _answers['Which city are you based in?'];
    _answers.clear();
    if (name != null) _answers['What\'s your full name?'] = name;
    if (location != null) _answers['Which city are you based in?'] = location;

    // Start generating the first AI question if static questions are skipped
    if (name != null && name.isNotEmpty && location != null && location.isNotEmpty) {
      // Don't wait for it if we don't want to block, but it's safe to run async
      generateNextQuestion();
    }

    notifyListeners();
  }

  void cancelIdeaMode() {
    _isIdeaMode = false;
    _isSubmitting = false;
    notifyListeners();
  }

  Future<void> completeIdeaOnboarding() async {
    await completeOnboardingOnBackend();
    _isIdeaMode = false;
    notifyListeners();
  }

  void completeOnboarding() {
    _isComplete = true;
    notifyListeners();
  }

  String buildIdeaPrompt() {
    final parts = <String>[];
    _answers.forEach((key, value) {
      if (value.isNotEmpty) parts.add('- $key: ${value.join(", ")}');
    });
    return 'Based on my profile below, generate a detailed, highly personalized business idea for me. '
        'Tailor it to my local market and location. '
        'Make it actionable with first steps I can take this week.\n\nMy Profile:\n${parts.join('\n')}';
  }
}
