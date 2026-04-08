import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.values,
    required this.color,
    this.height = 120,
    this.minY,
    this.maxY,
  });

  final List<double> values;
  final Color color;
  final double height;
  final double? minY;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'No trend data yet',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: color,
          minY: minY,
          maxY: maxY,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    this.minY,
    this.maxY,
  });

  final List<double> values;
  final Color color;
  final double? minY;
  final double? maxY;

  @override
  void paint(Canvas canvas, Size size) {
    final resolvedMin = minY ?? values.reduce((a, b) => a < b ? a : b);
    final resolvedMax = maxY ?? values.reduce((a, b) => a > b ? a : b);
    final span = (resolvedMax - resolvedMin).abs() < 0.0001
        ? 1.0
        : resolvedMax - resolvedMin;

    final baselinePaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;

    final gridPaint = Paint()
      ..color = AppColors.line.withValues(alpha: 0.45)
      ..strokeWidth = 1;

    for (var index = 1; index <= 3; index++) {
      final y = (size.height - 1) * (index / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final baselineY = size.height - 1;
    canvas.drawLine(
      Offset.zero.translate(0, baselineY),
      Offset(size.width, baselineY),
      baselinePaint,
    );

    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final dx = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final normalized = (values[index] - resolvedMin) / span;
      final dy = size.height - 8 - (normalized * (size.height - 16));
      final point = Offset(dx, dy);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.24), color.withValues(alpha: 0.02)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3;
    canvas.drawPath(path, linePaint);

    final lastDx = values.length == 1 ? size.width / 2 : size.width;
    final lastNormalized = (values.last - resolvedMin) / span;
    final lastDy = size.height - 8 - (lastNormalized * (size.height - 16));

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(lastDx, lastDy), 4.5, dotPaint);
    canvas.drawCircle(
      Offset(lastDx, lastDy),
      8,
      Paint()..color = color.withValues(alpha: 0.14),
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY;
  }
}
