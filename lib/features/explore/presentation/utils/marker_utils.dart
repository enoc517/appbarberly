// lib/features/explore/presentation/utils/marker_utils.dart
//
// Utilidades para crear marcadores de FlutterMap personalizados.
//
// Diseño "Celestial Tailor":
//   · Barbería normal     → pin Space Blue  (#0F1C2C)
//   · Barbería con promo  → pin Lilo Red    (#B7102A) + badge ⚡
// ===========================================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:barberly/features/explore/domain/entities/explore_entities.dart';

// ════════════════════════════════════════════════════════════════════════════
// COLORES — Design System "Celestial Tailor"
// ════════════════════════════════════════════════════════════════════════════

class _DesignTokens {
  static const Color spaceBlue = Color(0xFF0F1C2C);
  static const Color liloRed = Color(0xFFB7102A);
}

// ════════════════════════════════════════════════════════════════════════════
// MARKER UTILS
// ════════════════════════════════════════════════════════════════════════════

class MarkerUtils {
  MarkerUtils._();

  static List<Marker> buildMarkers({
    required List<BarbershopEntity> barbershops,
    required void Function(BarbershopEntity) onTap,
  }) {
    return barbershops.map((shop) {
      final color = shop.hasActivePromotion
          ? _DesignTokens.liloRed
          : _DesignTokens.spaceBlue;

      return Marker(
        point: LatLng(shop.lat, shop.lng),
        width: 40,
        height: 52,
        child: GestureDetector(
          onTap: () => onTap(shop),
          child: _PinWidget(color: color, hasPromo: shop.hasActivePromotion),
        ),
      );
    }).toList();
  }
}

class _PinWidget extends StatelessWidget {
  final Color color;
  final bool hasPromo;
  const _PinWidget({required this.color, required this.hasPromo});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 52),
      painter: _PinPainter(color: color, hasPromo: hasPromo),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color color;
  final bool hasPromo;
  const _PinPainter({required this.color, required this.hasPromo});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()..color = color;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 50 / 255)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final shadowPath = _pinPath(w, h, offsetY: 4);
    canvas.drawPath(shadowPath, shadowPaint);

    final pinPath = _pinPath(w, h);
    canvas.drawPath(pinPath, bodyPaint);

    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 230 / 255);
    canvas.drawCircle(Offset(w / 2, h * 0.37), 10, circlePaint);

    final icon = hasPromo ? '⚡' : '✂';
    _drawText(
      canvas: canvas,
      text: icon,
      x: w / 2,
      y: h * 0.37 - 6,
      fontSize: 12,
      color: hasPromo ? _DesignTokens.liloRed : _DesignTokens.spaceBlue,
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.hasPromo != hasPromo;
  }

  ui.Path _pinPath(double w, double h, {double offsetY = 0}) {
    final cx = w / 2;
    final topRadius = w * 0.42;
    final tipY = h * 0.92 + offsetY;

    return ui.Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(cx, topRadius + offsetY),
          radius: topRadius,
        ),
      )
      ..moveTo(cx - topRadius * 0.38, topRadius * 1.45 + offsetY)
      ..quadraticBezierTo(
        cx,
        tipY,
        cx + topRadius * 0.38,
        topRadius * 1.45 + offsetY,
      )
      ..close();
  }

  void _drawText({
    required Canvas canvas,
    required String text,
    required double x,
    required double y,
    required double fontSize,
    required Color color,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(x - tp.width / 2, y));
  }
}
