// lib/features/explore/presentation/utils/marker_utils.dart
//
// Utilidades para crear marcadores de Google Maps personalizados.
//
// Diseño "Celestial Tailor":
//   · Barbería normal     → pin Space Blue  (#0F1C2C)
//   · Barbería con promo  → pin Lilo Red    (#B7102A) + badge ⚡
//
// DEPENDENCIAS REQUERIDAS en pubspec.yaml:
//   google_maps_flutter: ^2.9.0
//
// NOTA SOBRE BitmapDescriptor.fromAssetImage:
//   Para íconos de alta calidad, coloca los archivos en:
//     assets/icons/pin_space_blue.png   (tamaño 96×96 @3x)
//     assets/icons/pin_lilo_red.png     (tamaño 96×96 @3x)
//   y declara los assets en pubspec.yaml.
//   Como fallback sin assets, se usa canvas programático.
// ===========================================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:barberly/features/explore/domain/entities/explore_entities.dart';

// ════════════════════════════════════════════════════════════════════════════
// COLORES — Design System "Celestial Tailor"
// ════════════════════════════════════════════════════════════════════════════

class _DesignTokens {
  /// Space Blue — pin estándar
  static const Color spaceBlue = Color(0xFF0F1C2C);

  /// Lilo Red — pin con promoción activa ⚡
  static const Color liloRed = Color(0xFFB7102A);

  /// Blanco puro para el ícono del pin
  static const Color pinIconColor = Colors.white;
}

// ════════════════════════════════════════════════════════════════════════════
// MARKER UTILS
// ════════════════════════════════════════════════════════════════════════════

class MarkerUtils {
  MarkerUtils._(); // clase utilitaria, no instanciar

  // ── Cache de BitmapDescriptors (evita regenerar en cada rebuild) ──────────

  static BitmapDescriptor? _cachedPinBlue;
  static BitmapDescriptor? _cachedPinRed;

  // ── Punto de entrada principal ────────────────────────────────────────────

  /// Convierte una lista de [BarbershopEntity] en un [Set<Marker>] listo para
  /// pasarle a GoogleMap.
  ///
  /// [onTap] recibe la entidad seleccionada → el BLoC emite
  /// [ExploreMapBarbershopSelected] para mover la cámara.
  static Future<Set<Marker>> buildMarkers({
    required List<BarbershopEntity> barbershops,
    required void Function(BarbershopEntity) onTap,
  }) async {
    // Pre-cargar los descriptores la primera vez
    await _ensureDescriptorsLoaded();

    final markers = <Marker>{};

    for (final shop in barbershops) {
      final icon = shop.hasActivePromotion ? _cachedPinRed! : _cachedPinBlue!;

      final marker = Marker(
        markerId: MarkerId(shop.id),
        position: LatLng(shop.lat, shop.lng),
        icon: icon,
        // Ventana de información nativa de Google Maps (opcional — se puede
        // reemplazar por un BottomSheet personalizado en el onTap del BLoC)
        infoWindow: InfoWindow(
          title: shop.name,
          snippet: shop.hasActivePromotion
              ? '⚡ Promoción activa — ¡Ver oferta!'
              : '★ ${shop.rating.toStringAsFixed(1)}  ·  ${shop.reviewCount} reseñas',
        ),
        onTap: () => onTap(shop),
      );

      markers.add(marker);
    }

    return markers;
  }

  // ── Carga y cacheo de íconos ──────────────────────────────────────────────

  static Future<void> _ensureDescriptorsLoaded() async {
    if (_cachedPinBlue != null && _cachedPinRed != null) return;

    // Intentar cargar desde assets; si falla, pintar programáticamente
    try {
      _cachedPinBlue ??= await _loadFromAsset('assets/icons/pin_space_blue.png');
      _cachedPinRed  ??= await _loadFromAsset('assets/icons/pin_lilo_red.png');
    } catch (_) {
      // Fallback: generar el bitmap en canvas si los assets no existen
      _cachedPinBlue ??= await _buildPinBitmap(
        color: _DesignTokens.spaceBlue,
        hasPromo: false,
      );
      _cachedPinRed ??= await _buildPinBitmap(
        color: _DesignTokens.liloRed,
        hasPromo: true,
      );
    }
  }

  static Future<BitmapDescriptor> _loadFromAsset(String path) async {
    return BitmapDescriptor.asset(
      const ImageConfiguration(devicePixelRatio: 3.0, size: Size(32, 44)),
      path,
    );
  }

  // ── Generador de pins en canvas (sin assets) ──────────────────────────────
  //
  // Dibuja un pin estilo "lagrima" con la inicial de la barbería o ⚡.
  // Se ejecuta una sola vez y el resultado se cachea.

  static Future<BitmapDescriptor> _buildPinBitmap({
    required Color color,
    required bool hasPromo,
  }) async {
    const double w = 96.0;
    const double h = 120.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

    // ── Cuerpo del pin (forma de lágrima) ─────────────────────────────────
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Sombra difusa (16–24px blur acorde al design system)
    final shadowPath = _pinPath(w, h, offsetY: 4);
    canvas.drawPath(shadowPath, shadowPaint);

    // Cuerpo principal
    final pinPath = _pinPath(w, h);
    canvas.drawPath(pinPath, bodyPaint);

    // ── Círculo interior blanco ───────────────────────────────────────────
    final circlePaint = Paint()
      ..color = Colors.white.withAlpha(230)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h * 0.37), 22, circlePaint);

    // ── Ícono dentro del círculo ──────────────────────────────────────────
    if (hasPromo) {
      // Rayo ⚡ usando TextPainter
      _drawText(
        canvas: canvas,
        text: '⚡',
        x: w / 2,
        y: h * 0.37 - 12,
        fontSize: 22,
        color: _DesignTokens.liloRed,
      );
    } else {
      // Ícono de tijeras ✂ Space Blue
      _drawText(
        canvas: canvas,
        text: '✂',
        x: w / 2,
        y: h * 0.37 - 12,
        fontSize: 20,
        color: _DesignTokens.spaceBlue,
      );
    }

    // ── Renderizar ────────────────────────────────────────────────────────
    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes, width: 32, height: 44);
  }

  /// Construye el Path en forma de pin de mapa (lágrima invertida).
  static Path _pinPath(double w, double h, {double offsetY = 0}) {
    final cx = w / 2;
    final topRadius = w * 0.42; // radio de la cabeza circular del pin
    final tipY = h * 0.92 + offsetY; // punta inferior del pin

    return Path()
      ..addOval(
        Rect.fromCircle(center: Offset(cx, topRadius + offsetY), radius: topRadius),
      )
      ..moveTo(cx - topRadius * 0.38, topRadius * 1.45 + offsetY)
      ..quadraticBezierTo(cx, tipY, cx + topRadius * 0.38, topRadius * 1.45 + offsetY)
      ..close();
  }

  /// Dibuja texto centrado en el canvas.
  static void _drawText({
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

  // ── Invalidar caché (útil al cambiar de tema) ─────────────────────────────

  static void clearCache() {
    _cachedPinBlue = null;
    _cachedPinRed = null;
  }
}