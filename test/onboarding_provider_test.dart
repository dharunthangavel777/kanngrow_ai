import 'package:flutter_test/flutter_test.dart';
import 'package:kangrow_ai/providers/onboarding_provider.dart';

void main() {
  group('OnboardingProvider Dynamic Flow Tests', () {
    late OnboardingProvider provider;

    setUp(() {
      provider = OnboardingProvider();
    });

    test('Initial questions contains base profile questions', () {
      final initialQuestions = provider.questions;
      
      // Initially, there should be name, age, education, profession, budget, time, and domains.
      // Total 7 questions (because conditional ones are not visible yet)
      expect(initialQuestions.length, 7);
      expect(initialQuestions[0].id, 'name');
      expect(initialQuestions[1].id, 'age');
      expect(initialQuestions[2].id, 'education');
      expect(initialQuestions[3].id, 'profession');
      expect(initialQuestions[4].id, 'budget');
      expect(initialQuestions[5].id, 'time');
      expect(initialQuestions[6].id, 'domains');
    });

    test('Selecting Technology domain reveals tech Focus Areas question', () {
      // 1. Fill basic details
      provider.saveTextAnswer('What is your full name?', 'John Doe');
      provider.saveAnswer('How old are you?', '18-24');
      provider.saveAnswer('Educational Qualification', 'Bachelor\'s Degree');
      provider.saveAnswer('What is your current profession?', 'Student');
      provider.saveAnswer('What is your startup budget?', 'Lean (< ₹50,000)');
      provider.saveAnswer('Time Commitment', 'Side Hustle (5-10 hrs/week)');

      // 2. Select Technology domain
      provider.toggleAnswer('Choose Business Domains', 'Technology');

      // The questions list should now include 'tech_sub'
      final questions = provider.questions;
      expect(questions.length, 8);
      expect(questions[7].id, 'tech_sub');

      // Verify visibleAnswers
      expect(provider.visibleAnswers.containsKey('Choose Business Domains'), true);
      expect(provider.visibleAnswers['Choose Business Domains'], ['Technology']);
    });

    test('Selecting Software Development in tech reveals software focus details', () {
      // 1. Fill base details & domains
      provider.saveTextAnswer('What is your full name?', 'John Doe');
      provider.saveAnswer('How old are you?', '18-24');
      provider.saveAnswer('Educational Qualification', 'Bachelor\'s Degree');
      provider.saveAnswer('What is your current profession?', 'Student');
      provider.saveAnswer('What is your startup budget?', 'Lean (< ₹50,000)');
      provider.saveAnswer('Time Commitment', 'Side Hustle (5-10 hrs/week)');
      provider.toggleAnswer('Choose Business Domains', 'Technology');

      // 2. Select Software Development in tech focus
      provider.toggleAnswer('Select Tech Focus Areas', 'Software Development');

      // Questions should now include both tech_sub and software_details
      final questions = provider.questions;
      expect(questions.length, 9);
      expect(questions[7].id, 'tech_sub');
      expect(questions[8].id, 'software_details');
    });

    test('Switching domain clears answers to no-longer-visible questions from visibleAnswers', () {
      // 1. Set Technology path
      provider.saveTextAnswer('What is your full name?', 'John Doe');
      provider.toggleAnswer('Choose Business Domains', 'Technology');
      provider.toggleAnswer('Select Tech Focus Areas', 'Software Development');
      provider.toggleAnswer('Software Development Focus', 'B2B SaaS (Software as a Service)');

      // Check tech questions are visible
      expect(provider.questions.any((q) => q.id == 'tech_sub'), true);
      expect(provider.questions.any((q) => q.id == 'software_details'), true);
      expect(provider.visibleAnswers.containsKey('Software Development Focus'), true);

      // 2. Switch Choose Business Domains to Retail & E-Commerce instead (removing Technology)
      provider.toggleAnswer('Choose Business Domains', 'Technology'); // uncheck Technology
      provider.toggleAnswer('Choose Business Domains', 'Retail & E-Commerce'); // check Retail

      // Verify tech questions are no longer in questions list
      expect(provider.questions.any((q) => q.id == 'tech_sub'), false);
      expect(provider.questions.any((q) => q.id == 'software_details'), false);

      // Verify retail questions are now visible
      expect(provider.questions.any((q) => q.id == 'retail_sub'), true);

      // CRITICAL: Verify visibleAnswers does NOT contain the technology / software answers anymore!
      expect(provider.visibleAnswers.containsKey('Select Tech Focus Areas'), false);
      expect(provider.visibleAnswers.containsKey('Software Development Focus'), false);
      
      // But it still contains the domains answer
      expect(provider.visibleAnswers['Choose Business Domains'], ['Retail & E-Commerce']);
    });
  });
}
