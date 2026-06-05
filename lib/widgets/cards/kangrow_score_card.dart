import 'package:flutter/material.dart';
import '../../app_theme.dart';

class KangrowScoreCard extends StatelessWidget {
  final Map<String, dynamic> metadata;

  const KangrowScoreCard({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    // Parse the validation data from metadata
    final valData = metadata['validation'] ?? metadata;
    final int overallScore = valData['overallScore'] ?? 75;
    final String verdict = valData['verdict'] ?? 'Moderate Opportunity';
    final String verdictDetail = valData['verdict_detail'] ?? valData['detail'] ?? 'The product has decent market viability, but requires careful sourcing execution.';

    final dimensions = valData['dimensions'] ?? {};
    final marketDemand = dimensions['marketDemand'] ?? dimensions['demand'] ?? {'score': 70, 'insight': 'Steady demand expected.'};
    final competition = dimensions['competition'] ?? {'score': 60, 'insight': 'Established players exist.'};
    final profitPotential = dimensions['profitPotential'] ?? dimensions['margin'] ?? {'score': 75, 'insight': 'Healthy estimated margin.'};
    final executionDifficulty = dimensions['executionDifficulty'] ?? dimensions['execution'] ?? {'score': 65, 'insight': 'Standard sourcing process.'};
    final riskLevel = dimensions['riskLevel'] ?? dimensions['risk'] ?? {'score': 70, 'insight': 'Requires initial ad spend.'};

    final List<dynamic> topRisks = valData['topRisks'] ?? valData['risks'] ?? [];
    final List<dynamic> quickWins = valData['quickWins'] ?? valData['wins'] ?? [];

    Color scoreColor;
    if (overallScore >= 80) {
      scoreColor = AppColors.accentSuccess;
    } else if (overallScore >= 60) {
      scoreColor = Colors.amber;
    } else {
      scoreColor = AppColors.danger;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Title + Verdict Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.analytics_outlined, color: scoreColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Opportunity Score',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scoreColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    verdict,
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Score circular gauge & general description
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: overallScore / 100,
                        backgroundColor: AppColors.borderDark,
                        color: scoreColor,
                        strokeWidth: 6,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          overallScore.toString(),
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '/100',
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    verdictDetail,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Dimensions breakdown
            const Text(
              'VIABILITY BREAKDOWN',
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildDimensionRow(context, 'Market Demand', marketDemand['score'] ?? 70, marketDemand['insight'] ?? ''),
            _buildDimensionRow(context, 'Competitive Density', competition['score'] ?? 60, competition['insight'] ?? ''),
            _buildDimensionRow(context, 'Profit Potential', profitPotential['score'] ?? 75, profitPotential['insight'] ?? ''),
            _buildDimensionRow(context, 'Execution Simplicity', executionDifficulty['score'] ?? 65, executionDifficulty['insight'] ?? ''),
            _buildDimensionRow(context, 'Risk Level (Lower is Better)', 100 - (riskLevel['score'] ?? 30) as int, riskLevel['insight'] ?? ''),

            // Quick wins & risks
            if (quickWins.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.bolt, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'RECOMMENDED QUICK WINS',
                    style: TextStyle(
                      color: AppColors.textGray,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...quickWins.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(' • ', style: TextStyle(color: Colors.amber)),
                    Expanded(
                      child: Text(
                        w.toString(),
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              )),
            ],

            if (topRisks.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'CRITICAL RISKS',
                    style: TextStyle(
                      color: AppColors.textGray,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...topRisks.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, color: AppColors.danger, size: 16),
                    Expanded(
                      child: Text(
                        r.toString(),
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionRow(BuildContext context, String label, int score, String insight) {
    Color barColor;
    if (score >= 80) {
      barColor = AppColors.accentSuccess;
    } else if (score >= 60) {
      barColor = Colors.amber;
    } else {
      barColor = AppColors.danger;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$score/100',
                style: TextStyle(
                  color: barColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: AppColors.borderDark,
              color: barColor,
              minHeight: 4.5,
            ),
          ),
          if (insight.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              insight,
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
