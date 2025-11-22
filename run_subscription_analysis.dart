import 'subscription_structure_analysis.dart';

void main() {
  print('💳 REDP!NG SUBSCRIPTION STRUCTURE ANALYSIS');
  print('=' * 80);
  print('');

  // Display pricing recommendation table
  print(SubscriptionStructureAnalysis.getPricingRecommendationTable());

  print('\n');
  print('📊 QUICK ASSESSMENT SUMMARY');
  print('=' * 50);

  // Display quick assessment
  final assessment = SubscriptionStructureAnalysis.getQuickAssessment();
  for (final entry in assessment.entries) {
    print('${entry.key.padRight(25)}: ${entry.value}');
  }

  print('\n');
  print('📋 DETAILED ANALYSIS DATA AVAILABLE');
  print(
    'Call SubscriptionStructureAnalysis.analyzeSubscriptionStructure() for complete details',
  );
  print('');
  print('✅ ANALYSIS COMPLETE: Review pricing recommendations above');
}
