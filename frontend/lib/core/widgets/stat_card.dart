import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final String? trend;
  final bool? isPositiveTrend;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.trend,
    this.isPositiveTrend,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cardColor, size: 24),
              ),
              if (trend != null) ...[const Spacer(), _buildTrendIndicator()],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTextStyles.textTheme.headlineLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final isPositive = isPositiveTrend ?? true;
    final trendColor = isPositive ? AppColors.success : AppColors.error;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Row(
      children: [
        Icon(trendIcon, color: trendColor, size: 20),
        const SizedBox(width: 4),
        Text(
          trend!,
          style: AppTextStyles.textTheme.labelMedium?.copyWith(
            color: trendColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
