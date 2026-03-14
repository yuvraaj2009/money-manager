import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/themes/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/analytics_model.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.categories,
    this.size = 220,
    this.centerTitle,
    this.centerSubtitle,
  });

  final List<CategoryTotalModel> categories;
  final double size;
  final String? centerTitle;
  final String? centerSubtitle;

  @override
  Widget build(BuildContext context) {
    final topCategory = categories.isNotEmpty ? categories.first : null;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _CategoryPiePainter(categories: categories, progress: value),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerTitle ?? (topCategory?.name ?? 'No data'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    centerSubtitle ??
                        (topCategory == null ? '' : '${topCategory.percentage.toStringAsFixed(0)}%'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryPiePainter extends CustomPainter {
  _CategoryPiePainter({required this.categories, required this.progress});

  final List<CategoryTotalModel> categories;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.16;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final backgroundPaint = Paint()
      ..color = AppColors.surfaceHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);

    if (categories.isEmpty) {
      return;
    }

    final total = categories.fold<int>(0, (sum, item) => sum + item.totalAmount);
    var startAngle = -math.pi / 2;
    for (final category in categories) {
      final sweep = total == 0
          ? 0.0
          : ((category.totalAmount / total) * math.pi * 2 * progress).clamp(0.0, math.pi * 2);
      final paint = Paint()
        ..color = AppFormatters.colorFromHex(category.color)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep + 0.08;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryPiePainter oldDelegate) {
    return oldDelegate.categories != categories || oldDelegate.progress != progress;
  }
}
