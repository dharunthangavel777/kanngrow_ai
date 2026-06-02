import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/setup/wizard_option_card.dart';
import '../chat_screen.dart';

class BusinessDnaScreen extends StatefulWidget {
  const BusinessDnaScreen({super.key});

  @override
  State<BusinessDnaScreen> createState() => _BusinessDnaScreenState();
}

class _BusinessDnaScreenState extends State<BusinessDnaScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Form State
  final TextEditingController _nameController = TextEditingController();
  String? _industry;
  String? _targetAudience;
  String? _budget;
  String? _businessModel;
  String? _startupGoal;

  final int _totalPages = 6;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete setup and go to Chat Screen
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ChatScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        (route) => false,
      );
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _onOptionSelected(VoidCallback updateState) {
    updateState();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _nextPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar & Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _previousPage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / _totalPages,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lightCyan),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentIndex + 1}/$_totalPages',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentIndex = index),
                children: [
                  _buildNameStep(),
                  _buildIndustryStep(),
                  _buildAudienceStep(),
                  _buildBudgetStep(),
                  _buildModelStep(),
                  _buildGoalStep(),
                ],
              ),
            ),

            // Footer (Only for the Text Field step)
            if (_currentIndex == 0)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nameController.text.trim().isNotEmpty ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightCyan,
                      disabledBackgroundColor: AppColors.lightCyan.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.black, // Active color will be black
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildNameStep() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildStepHeader('Name your store', 'You can always change this later if you are still brainstorming.'),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          cursorColor: AppColors.lightCyan,
          decoration: InputDecoration(
            hintText: 'E.g. Kangrow AI',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            filled: true,
            fillColor: AppColors.surfaceCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.lightCyan, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildIndustryStep() {
    final industries = [
      {'title': 'Technology & Software', 'icon': Icons.computer_rounded},
      {'title': 'E-commerce & Retail', 'icon': Icons.shopping_cart_outlined},
      {'title': 'Health & Wellness', 'icon': Icons.favorite_border_rounded},
      {'title': 'Education', 'icon': Icons.school_outlined},
      {'title': 'Finance & FinTech', 'icon': Icons.account_balance_wallet_outlined},
      {'title': 'Other', 'icon': Icons.more_horiz_rounded},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildStepHeader('What industry are you in?', 'This helps us understand the market dynamics.'),
        ...industries.map((ind) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WizardOptionCard(
            title: ind['title'] as String,
            icon: ind['icon'] as IconData,
            isSelected: _industry == ind['title'],
            onTap: () => _onOptionSelected(() => setState(() => _industry = ind['title'] as String)),
          ),
        )),
      ],
    );
  }

  Widget _buildAudienceStep() {
    final audiences = [
      {'title': 'B2B', 'desc': 'Selling to other businesses'},
      {'title': 'B2C', 'desc': 'Selling directly to consumers'},
      {'title': 'B2B2C', 'desc': 'Selling through businesses to consumers'},
      {'title': 'Marketplace', 'desc': 'Connecting buyers and sellers'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildStepHeader('Who is your target audience?', 'Select your primary customer base.'),
        ...audiences.map((aud) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WizardOptionCard(
            title: aud['title'] as String,
            description: aud['desc'] as String,
            isSelected: _targetAudience == aud['title'],
            onTap: () => _onOptionSelected(() => setState(() => _targetAudience = aud['title'] as String)),
          ),
        )),
      ],
    );
  }

  Widget _buildBudgetStep() {
    final budgets = [
      {'title': 'Bootstrapped (\$0)', 'desc': 'I am building this with zero budget'},
      {'title': '< \$1,000', 'desc': 'I have a very small budget'},
      {'title': '\$1k - \$10k', 'desc': 'I have some capital to invest'},
      {'title': '\$10k+', 'desc': 'I am well-funded'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildStepHeader('What is your budget?', 'This will help the AI recommend affordable solutions.'),
        ...budgets.map((bud) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WizardOptionCard(
            title: bud['title'] as String,
            description: bud['desc'] as String,
            isSelected: _budget == bud['title'],
            onTap: () => _onOptionSelected(() => setState(() => _budget = bud['title'] as String)),
          ),
        )),
      ],
    );
  }

  Widget _buildModelStep() {
    final models = [
      {'title': 'Dropshipping', 'desc': 'Sell products without holding inventory'},
      {'title': 'Direct-to-Consumer (DTC)', 'desc': 'Build a brand and sell directly'},
      {'title': 'White Label', 'desc': 'Rebrand existing products as your own'},
      {'title': 'Wholesale', 'desc': 'Sell in bulk to other businesses'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildStepHeader('What is your business model?', 'How do you plan to make money?'),
        ...models.map((mod) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WizardOptionCard(
            title: mod['title'] as String,
            description: mod['desc'] as String,
            isSelected: _businessModel == mod['title'],
            onTap: () => _onOptionSelected(() => setState(() => _businessModel = mod['title'] as String)),
          ),
        )),
      ],
    );
  }

  Widget _buildGoalStep() {
    final goals = [
      {'title': 'Reach \$10k Monthly Sales', 'desc': 'Build a solid, profitable business'},
      {'title': 'Passive Income Store', 'desc': 'Work on my own terms, earn passively'},
      {'title': 'Get Acquired', 'desc': 'Build and sell the company within a few years'},
      {'title': 'Unicorn / IPO', 'desc': 'Build a massive, venture-backed company'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildStepHeader('What is your ultimate goal?', 'Where do you see this store in the future?'),
        ...goals.map((goal) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WizardOptionCard(
            title: goal['title'] as String,
            description: goal['desc'] as String,
            isSelected: _startupGoal == goal['title'],
            onTap: () => _onOptionSelected(() => setState(() => _startupGoal = goal['title'] as String)),
          ),
        )),
      ],
    );
  }
}
