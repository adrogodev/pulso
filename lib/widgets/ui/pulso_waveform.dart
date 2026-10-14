import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Widget de onda o pulso geométrico monocromático característico de Pulso.
class PulsoWaveform extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final bool animated;

  const PulsoWaveform({
    super.key,
    this.width = 64,
    this.height = 64,
    this.color = AppColors.textPrimary,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _PulsoWaveformPainter(color: color)),
    );
  }
}

class _PulsoWaveformPainter extends CustomPainter {
  final Color color;

  const _PulsoWaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final barHeights = [0.25, 0.50, 0.85, 0.40, 0.95, 0.65, 0.30, 0.75, 0.45];

    final spacing = size.width / (barHeights.length + 1);
    final centerY = size.height / 2;

    for (var i = 0; i < barHeights.length; i++) {
      final x = spacing * (i + 1);
      final halfH = (size.height * barHeights[i]) / 2;
      canvas.drawLine(
        Offset(x, centerY - halfH),
        Offset(x, centerY + halfH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PulsoWaveformPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
