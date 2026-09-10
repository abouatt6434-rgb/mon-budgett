import 'package:flutter/material.dart';
import '../services/budget_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';

class BudgetProgressCard extends StatelessWidget {
  final String title;
  final BudgetProgress progress;

  const BudgetProgressCard({super.key, required this.title, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = progress.percent.clamp(0, 1.5).toDouble();
    final alert = BudgetService.alertLabelForPercent(progress.percent);
    Color barColor = AppColors.primary;
    if (progress.percent >= 1.0) {
      barColor = AppColors.danger;
    } else if (progress.percent >= 0.75) {
      barColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${CurrencyFormatter.format(progress.spent)} / ${CurrencyFormatter.format(progress.budget.amount)}',
                style: const TextStyle(color: AppColors.textLight, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent > 1 ? 1 : percent,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: barColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress.percent * 100).toStringAsFixed(0)}% utilisé · Reste ${CurrencyFormatter.format(progress.remaining < 0 ? 0 : progress.remaining)}',
            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
          if (alert != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: barColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(alert, style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
