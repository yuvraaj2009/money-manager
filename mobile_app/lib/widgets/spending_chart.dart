import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/themes/app_theme.dart';
import '../models/analytics_model.dart';

class SpendingChart extends StatelessWidget {
  const SpendingChart({
    super.key,
    required this.points,
    this.height = 220,
  });

  final List<TrendPointModel> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Column(
          children: [
            SizedBox(
              height: height,
              child: CustomPaint(
                painter: _SpendingChartPainter(points: points, progress: value),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points
                  .map(
                    (point) => Expanded(
                      child: Text(
                        point.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _SpendingChartPainter extends CustomPainter {
  _SpendingChartPainter({required this.points, required this.progress});

  final List<TrendPointModel> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = math.max(
      points.map((point) => point.totalSpending).fold<int>(0, math.max),
      1,
    );
    final dx = points.length <= 1 ? size.width : size.width / (points.length - 1);
    final linePath = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x = dx * i;
      final normalized = point.totalSpending / maxValue;
      final y = size.height - ((size.height - 28) * normalized * progress) - 12;
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final previousX = dx * (i - 1);
        final previousPoint = points[i - 1];
        final previousNormalized = previousPoint.totalSpending / maxValue;
        final previousY =
            size.height - ((size.height - 28) * previousNormalized * progress) - 12;
        final controlX = (previousX + x) / 2;
        linePath.cubicTo(controlX, previousY, controlX, y, x, y);
        fillPath.cubicTo(controlX, previousY, controlX, y, x, y);
      }
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x330F52FF), Color(0x000F52FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SpendingChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.progress != progress;
  }
}
