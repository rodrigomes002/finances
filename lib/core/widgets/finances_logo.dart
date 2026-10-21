import 'package:flutter/material.dart';

class FinancesLogo extends StatelessWidget {
  const FinancesLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo Finanças',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: CustomPaint(painter: _FinancesLogoPainter()),
        ),
      ),
    );
  }
}

class _FinancesLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 108);

    final barPaint = Paint()..color = const Color(0xFFF4FBF8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(25, 58, 41, 80),
        const Radius.circular(4),
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(46, 48, 62, 80),
        const Radius.circular(4),
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(67, 38, 83, 80),
        const Radius.circular(4),
      ),
      barPaint,
    );

    final trendPaint = Paint()
      ..color = const Color(0xFF8DC8F2)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final trend = Path()
      ..moveTo(20, 51)
      ..lineTo(37, 39)
      ..lineTo(46, 44)
      ..lineTo(72, 22);
    canvas.drawPath(trend, trendPaint);

    final arrowHead = Path()
      ..moveTo(67, 16)
      ..lineTo(87, 13)
      ..lineTo(83, 33)
      ..close();
    canvas.drawPath(arrowHead, Paint()..color = const Color(0xFF8DC8F2));
  }

  @override
  bool shouldRepaint(covariant _FinancesLogoPainter oldDelegate) => false;
}
