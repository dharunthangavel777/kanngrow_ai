import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/network_config.dart';

class OnboardingQuestion {
  final String id;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> options;
  final bool isDynamic;
  final String type; // 'text' | 'single' | 'multi'
  final bool Function(Map<String, List<String>> answers)? condition;

  OnboardingQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.options,
    this.isDynamic = false,
    this.type = 'single',
    this.condition,
  });
}

class OnboardingProvider extends ChangeNotifier {
  final String _baseUrl = NetworkConfig.baseUrl;

  final List<OnboardingQuestion> _allQuestions = [
    OnboardingQuestion(
      id: 'name',
      title: 'What is your full name?',
      subtitle: 'Let\'s start with how we should address you.',
      type: 'text',
      options: [],
    ),
    OnboardingQuestion(
      id: 'age',
      title: 'How old are you?',
      subtitle: 'This helps us understand your demographic group.',
      type: 'single',
      options: [
        {'title': 'Under 18', 'icon': Icons.child_care_rounded, 'desc': 'Just starting out'},
        {'title': '18-24', 'icon': Icons.school_outlined, 'desc': 'Young entrepreneur'},
        {'title': '25-34', 'icon': Icons.work_outline, 'desc': 'Career builder'},
        {'title': '35-44', 'icon': Icons.insights_rounded, 'desc': 'Experienced professional'},
        {'title': '45+', 'icon': Icons.elderly_rounded, 'desc': 'Seasoned veteran'},
      ],
    ),
    OnboardingQuestion(
      id: 'education',
      title: 'Educational Qualification',
      subtitle: 'What is your highest level of completed education?',
      type: 'single',
      options: [
        {'title': 'High School', 'icon': Icons.school_rounded, 'desc': 'Completed secondary school'},
        {'title': 'Bachelor\'s Degree', 'icon': Icons.workspace_premium_rounded, 'desc': 'College / University graduate'},
        {'title': 'Master\'s Degree', 'icon': Icons.auto_stories_rounded, 'desc': 'Post-graduate level'},
        {'title': 'PhD', 'icon': Icons.psychology_rounded, 'desc': 'Doctoral researcher'},
        {'title': 'Self-Taught / Other', 'icon': Icons.menu_book_rounded, 'desc': 'Learned through experience'},
      ],
    ),
    OnboardingQuestion(
      id: 'profession',
      title: 'What is your current profession?',
      subtitle: 'This details your professional background.',
      type: 'single',
      options: [
        {'title': 'Student', 'icon': Icons.school_outlined, 'desc': 'Exploring entrepreneurship'},
        {'title': 'Full-time Employee', 'icon': Icons.work_outline_rounded, 'desc': 'Looking to transition or side-hustle'},
        {'title': 'Freelancer', 'icon': Icons.badge_outlined, 'desc': 'Independent contractor'},
        {'title': 'Business Owner', 'icon': Icons.business_outlined, 'desc': 'Already running an enterprise'},
        {'title': 'Unemployed / Other', 'icon': Icons.person_search_rounded, 'desc': 'Looking for new opportunities'},
      ],
    ),
    OnboardingQuestion(
      id: 'budget',
      title: 'What is your startup budget?',
      subtitle: 'This helps filter ideas based on financial feasibility.',
      type: 'single',
      options: [
        {'title': 'Lean (< ₹50,000)', 'icon': Icons.money_off_csred_rounded, 'desc': 'Bootstrap with minimal capital'},
        {'title': 'Medium (₹50,000 - ₹2,00,000)', 'icon': Icons.attach_money_rounded, 'desc': 'Moderate initial investment'},
        {'title': 'High (₹2,00,000 - ₹5,00,000)', 'icon': Icons.monetization_on_rounded, 'desc': 'Substantial starting capital'},
        {'title': 'Enterprise (> ₹5,00,000)', 'icon': Icons.account_balance_rounded, 'desc': 'Ready to scale with full resources'},
      ],
    ),
    OnboardingQuestion(
      id: 'time',
      title: 'Time Commitment',
      subtitle: 'How much time can you dedicate to this business weekly?',
      type: 'single',
      options: [
        {'title': 'Side Hustle (5-10 hrs/week)', 'icon': Icons.hourglass_bottom_rounded, 'desc': 'Main job remains primary'},
        {'title': 'Part-time (10-20 hrs/week)', 'icon': Icons.hourglass_empty_rounded, 'desc': 'Significant dedication alongside other tasks'},
        {'title': 'Full-time (40+ hrs/week)', 'icon': Icons.hourglass_full_rounded, 'desc': '100% committed to growth'},
      ],
    ),
    OnboardingQuestion(
      id: 'domains',
      title: 'Choose Business Domains',
      subtitle: 'Select one or more domains you are interested in.',
      type: 'multi',
      options: [
        {'title': 'Technology', 'icon': Icons.computer_rounded, 'desc': 'Software, AI, Cloud, SaaS'},
        {'title': 'Retail & E-Commerce', 'icon': Icons.storefront_rounded, 'desc': 'Direct-to-Consumer, Dropshipping, Brands'},
        {'title': 'Food & Agriculture', 'icon': Icons.local_restaurant_rounded, 'desc': 'Agri-Tech, Food Brands, Cafes'},
        {'title': 'Manufacturing & Hardware', 'icon': Icons.precision_manufacturing_rounded, 'desc': 'IoT, Textiles, Crafts, Electronics'},
      ],
    ),
    // Conditional Tech Sub-domains
    OnboardingQuestion(
      id: 'tech_sub',
      title: 'Select Tech Focus Areas',
      subtitle: 'Choose the sub-domains of Technology you want to pursue.',
      type: 'multi',
      condition: (answers) => answers['Choose Business Domains']?.contains('Technology') ?? false,
      options: [
        {'title': 'Software Development', 'icon': Icons.code_rounded, 'desc': 'SaaS, Mobile Apps, Web Tools'},
        {'title': 'Artificial Intelligence', 'icon': Icons.auto_awesome_rounded, 'desc': 'AI Agents, Automation, ML Models'},
        {'title': 'IT Consulting & Services', 'icon': Icons.support_agent_rounded, 'desc': 'Agency, Cybersecurity, Cloud migration'},
      ],
    ),
    // Conditional Software Dev details
    OnboardingQuestion(
      id: 'software_details',
      title: 'Software Development Focus',
      subtitle: 'Select the processes and platforms you prefer.',
      type: 'multi',
      condition: (answers) => answers['Select Tech Focus Areas']?.contains('Software Development') ?? false,
      options: [
        {'title': 'Mobile Applications (iOS/Android)', 'icon': Icons.phone_android_rounded, 'desc': 'Consumer apps, utilities'},
        {'title': 'B2B SaaS (Software as a Service)', 'icon': Icons.business_rounded, 'desc': 'Subscription software for businesses'},
        {'title': 'Web Applications & Portals', 'icon': Icons.web_rounded, 'desc': 'Marketplaces, custom portals'},
        {'title': 'Developer Tooling & APIs', 'icon': Icons.settings_ethernet_rounded, 'desc': 'SDKs, code generators, dev tools'},
      ],
    ),
    // Conditional AI details
    OnboardingQuestion(
      id: 'ai_details',
      title: 'AI Product Details',
      subtitle: 'What type of AI application are you looking to build?',
      type: 'multi',
      condition: (answers) => answers['Select Tech Focus Areas']?.contains('Artificial Intelligence') ?? false,
      options: [
        {'title': 'Generative AI Content Tools', 'icon': Icons.article_rounded, 'desc': 'Copywriting, design, audio generation'},
        {'title': 'Conversational AI & Customer Support', 'icon': Icons.chat_rounded, 'desc': 'Smart chatbots, call agents'},
        {'title': 'Workflow Automation / RPA', 'icon': Icons.network_check_rounded, 'desc': 'Automating repetitive digital tasks'},
      ],
    ),
    // Conditional Retail Sub-domains
    OnboardingQuestion(
      id: 'retail_sub',
      title: 'Select E-Commerce Focus',
      subtitle: 'Choose your preferred e-commerce models.',
      type: 'multi',
      condition: (answers) => answers['Choose Business Domains']?.contains('Retail & E-Commerce') ?? false,
      options: [
        {'title': 'D2C Brand', 'icon': Icons.local_offer_rounded, 'desc': 'Create own apparel, cosmetics, or physical products'},
        {'title': 'Dropshipping / Reselling', 'icon': Icons.local_shipping_rounded, 'desc': 'Sell third-party products with no inventory'},
        {'title': 'B2B Wholesale Marketplace', 'icon': Icons.warehouse_rounded, 'desc': 'Supply bulk items to other retailers'},
      ],
    ),
    // Conditional D2C Brand details
    OnboardingQuestion(
      id: 'd2c_details',
      title: 'D2C Brand Niche',
      subtitle: 'Which product niche appeals to you most?',
      type: 'multi',
      condition: (answers) => answers['Select E-Commerce Focus']?.contains('D2C Brand') ?? false,
      options: [
        {'title': 'Fashion & Apparel', 'icon': Icons.checkroom_rounded, 'desc': 'Streetwear, eco-clothing, custom items'},
        {'title': 'Cosmetics & Personal Care', 'icon': Icons.face_rounded, 'desc': 'Organic skincare, herbal beauty'},
        {'title': 'Home Decor & Living', 'icon': Icons.home_rounded, 'desc': 'Handicrafts, minimalist styling'},
      ],
    ),
    // Conditional Food & Agri Sub-domains
    OnboardingQuestion(
      id: 'food_sub',
      title: 'Select Food & Agri Focus',
      subtitle: 'Which agricultural or culinary models interest you?',
      type: 'multi',
      condition: (answers) => answers['Choose Business Domains']?.contains('Food & Agriculture') ?? false,
      options: [
        {'title': 'Agri-Tech Solutions', 'icon': Icons.agriculture_rounded, 'desc': 'Hydroponics, smart irrigation, IoT farming'},
        {'title': 'Packaged Food Brand', 'icon': Icons.breakfast_dining_rounded, 'desc': 'Healthy snacks, organic honey, custom spices'},
        {'title': 'Food Delivery / Cloud Kitchen', 'icon': Icons.delivery_dining_rounded, 'desc': 'Meal prep, niche deliveries'},
      ],
    ),
    // Conditional Manufacturing Sub-domains
    OnboardingQuestion(
      id: 'mfg_sub',
      title: 'Select Manufacturing Focus',
      subtitle: 'Choose hardware production or fabrication models.',
      type: 'multi',
      condition: (answers) => answers['Choose Business Domains']?.contains('Manufacturing & Hardware') ?? false,
      options: [
        {'title': 'Custom Electronics / IoT', 'icon': Icons.developer_board_rounded, 'desc': 'Smart sensors, microcontrollers'},
        {'title': 'Textile & Apparel Production', 'icon': Icons.factory_rounded, 'desc': 'Garment fabrication, sourcing'},
        {'title': 'Crafts & Furniture Workshops', 'icon': Icons.handyman_rounded, 'desc': 'Wooden decor, artisanal goods'},
      ],
    )
  ];

  final Map<String, List<String>> _answers = {};
  bool _isGenerating = false;
  bool _isComplete = false;
  bool _isIdeaMode = false;

  List<OnboardingQuestion> get questions {
    final List<OnboardingQuestion> visible = [];
    final Map<String, List<String>> localAnswers = {};
    _answers.forEach((key, value) {
      localAnswers[key] = List<String>.from(value);
    });

    for (final q in _allQuestions) {
      if (q.condition == null || q.condition!(localAnswers)) {
        visible.add(q);
      } else {
        localAnswers.remove(q.title);
      }
    }
    return visible;
  }

  Map<String, List<String>> get answers => _answers;

  Map<String, List<String>> get visibleAnswers {
    final visibleTitles = questions.map((q) => q.title).toSet();
    final result = <String, List<String>>{};
    _answers.forEach((key, value) {
      if (visibleTitles.contains(key)) {
        result[key] = value;
      }
    });
    return result;
  }

  bool get isGenerating => _isGenerating;
  bool get isComplete => _isComplete;
  bool get isIdeaMode => _isIdeaMode;

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

  Future<bool> generateNextQuestion() async {
    // Pre-defined conditional questionnaire doesn't require backend call
    return false;
  }

  Future<void> completeOnboardingOnBackend() async {
    try {
      final profileAnswers = <String, String>{};
      visibleAnswers.forEach((key, value) {
        profileAnswers[key] = value.join(', ');
      });

      await http.post(
        Uri.parse('$_baseUrl/onboarding/complete'),
        headers: await NetworkConfig.getHeaders(),
        body: jsonEncode({
          'answers': profileAnswers,
        }),
      ).timeout(const Duration(seconds: 12));

      await http.post(
        Uri.parse('$_baseUrl/profile'),
        headers: await NetworkConfig.getHeaders(),
        body: jsonEncode({
          'storeName': profileAnswers['What is your full name?'] != null
              ? '${profileAnswers['What is your full name?']}\'s Store'
              : 'My E-commerce Store',
          'industry': profileAnswers['Choose Business Domains'] ?? 'General E-commerce',
          'targetAudience': 'General Public',
          'budget': profileAnswers['What is your startup budget?'] ?? 'Not Specified',
          'experienceLevel': 'Beginner',
          'stage': 'Concept',
        }),
      ).timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('Error completing onboarding on backend: $e');
    }

    _isComplete = true;
    notifyListeners();
  }

  void resetForNewIdea() {
    _answers.clear();
    _isGenerating = false;
    _isComplete = false;
    _isIdeaMode = true;
    notifyListeners();
  }

  Future<void> completeIdeaOnboarding() async {
    await completeOnboardingOnBackend();
    _isComplete = true;
    _isIdeaMode = false;
    notifyListeners();
  }

  void completeOnboarding() {
    _isComplete = true;
    notifyListeners();
  }
}
