// lib/features/explore/data/seeds/explore_seed.dart
//
// Seed que escribe las barberías mock usando geoflutterfire_plus para
// calcular geohashes correctos automáticamente.
//
// USO (solo en desarrollo):
//   import 'package:flutter/foundation.dart' show kDebugMode;
//   import 'package:barberly/features/explore/data/seeds/explore_seed.dart';
//
//   if (kDebugMode) {
//     await seedBarbershopsAndServices();
//   }
//
// Coloca esta llamada en main.dart después de Firebase.initializeApp(),
// o detrás de un botón temporal en debug. Una sola ejecución basta.
// ===========================================================================
/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

Future<void> seedBarbershopsAndServices() async {
  final db = FirebaseFirestore.instance;

  // ── 5 Barberías de Ciudad Neily ─────────────────────────────────────────
  final barbershops = [
    {
      'id': 'barbershop_001',
      'lat': 8.6135,
      'lng': -82.9585,
      'data': {
        'name': 'Imperio Barbershop',
        'ownerName': 'Carlos Méndez Vargas',
        'phone': '+506 8812-3456',
        'address': 'Av. Central, contiguo al Banco Nacional, Ciudad Neily',
        'rating': 4.8,
        'reviewCount': 127,
        'imageUrl':
            'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=800',
        'hasActivePromotion': true,
        'tags': ['fade', 'barba', 'afeitado_clasico', 'niños'],
        'isActive': true,
      },
    },
    {
      'id': 'barbershop_002',
      'lat': 8.6142,
      'lng': -82.9601,
      'data': {
        'name': 'Galactic Cuts Neily',
        'ownerName': 'Roberto Jiménez Arias',
        'phone': '+506 8723-9901',
        'address': '50m norte del Parque Central, Ciudad Neily',
        'rating': 4.6,
        'reviewCount': 89,
        'imageUrl':
            'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800',
        'hasActivePromotion': true,
        'tags': ['degradado', 'diseño', 'color', 'keratina'],
        'isActive': true,
      },
    },
    {
      'id': 'barbershop_003',
      'lat': 8.6118,
      'lng': -82.9572,
      'data': {
        'name': 'El Maestro Barber Lounge',
        'ownerName': 'Óscar Brenes Solano',
        'phone': '+506 8645-7723',
        'address': 'Barrio El Carmen, frente a la escuela, Ciudad Neily',
        'rating': 4.5,
        'reviewCount': 203,
        'imageUrl':
            'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=800',
        'hasActivePromotion': false,
        'tags': ['clasico', 'afeitado', 'bigote', 'senior'],
        'isActive': true,
      },
    },
    {
      'id': 'barbershop_004',
      'lat': 8.6159,
      'lng': -82.9617,
      'data': {
        'name': 'Sharp & Clean Studio',
        'ownerName': 'Luis Diego Rojas',
        'phone': '+506 8531-2288',
        'address': 'Centro Comercial Plaza Neily, local 14',
        'rating': 4.3,
        'reviewCount': 56,
        'imageUrl':
            'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?w=800',
        'hasActivePromotion': false,
        'tags': ['fade', 'skin_fade', 'tratamientos_capilares'],
        'isActive': true,
      },
    },
    {
      'id': 'barbershop_005',
      'lat': 8.6101,
      'lng': -82.9553,
      'data': {
        'name': 'La Navaja de Oro',
        'ownerName': 'Mauricio Varela Cruz',
        'phone': '+506 8900-4412',
        'address': 'Barrio Las Palmas, 200m sur del EBAIS, Ciudad Neily',
        'rating': 4.7,
        'reviewCount': 311,
        'imageUrl':
            'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800',
        'hasActivePromotion': false,
        'tags': ['afeitado_clasico', 'navaja', 'arreglo_barba', 'cejas'],
        'isActive': true,
      },
    },
  ];

  // ── Escribir cada barbería con geohash calculado por geoflutterfire_plus ──
  for (final shop in barbershops) {
    final lat = shop['lat'] as double;
    final lng = shop['lng'] as double;

    // GeoFirePoint genera el geohash internamente con el algoritmo correcto.
    // El método .data lo retorna como un Map listo para Firestore con la
    // estructura {'geohash': '...', 'geopoint': GeoPoint(...)}.
    final geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));

    final docData = {
      ...shop['data'] as Map<String, dynamic>,
      'position': geoFirePoint.data, // ← geohash + geopoint correctos
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await db.collection('barbershops').doc(shop['id'] as String).set(docData);

    // ignore: avoid_print
    print(
      '✅ Barbería ${shop['id']} escrita con geohash: '
      '${geoFirePoint.data['geohash']}',
    );
  }

  // ignore: avoid_print
  print('🎉 Seed completado: ${barbershops.length} barberías en Ciudad Neily');
}

// ── Para borrar y empezar desde cero ────────────────────────────────────────

Future<void> deleteAllBarbershops() async {
  final db = FirebaseFirestore.instance;
  final snapshot = await db.collection('barbershops').get();
  for (final doc in snapshot.docs) {
    await doc.reference.delete();
  }
  // ignore: avoid_print
  print('🗑️ Borradas ${snapshot.docs.length} barberías');
}
*/

// lib/features/explore/data/seeds/explore_seed.dart
//
// Seed completo: barberías + servicios denormalizados.
// Usa geoflutterfire_plus para calcular geohashes correctos.
//
// USO (solo en desarrollo):
//   import 'package:flutter/foundation.dart' show kDebugMode;
//   import 'package:barberly/features/explore/data/seeds/explore_seed.dart';
//
//   if (kDebugMode) {
//     await seedBarbershopsAndServices();
//   }
// ===========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

Future<void> seedBarbershopsAndServices() async {
  final db = FirebaseFirestore.instance;

  // ════════════════════════════════════════════════════════════════════════
  // 1) BARBERÍAS
  // ════════════════════════════════════════════════════════════════════════

  final barbershops = [
    {
      'id': 'barbershop_001',
      'lat': 8.6135,
      'lng': -82.9585,
      'data': {
        'name': 'Imperio Barbershop',
        'ownerName': 'Carlos Méndez Vargas',
        'phone': '+506 8812-3456',
        'address': 'Av. Central, contiguo al Banco Nacional, Ciudad Neily',
        'rating': 4.8,
        'reviewCount': 127,
        'imageUrl':
            'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=800',
        'hasActivePromotion': true,
        'tags': ['fade', 'barba', 'afeitado_clasico', 'niños'],
        'isActive': true,
      }
    },
    {
      'id': 'barbershop_002',
      'lat': 8.6142,
      'lng': -82.9601,
      'data': {
        'name': 'Galactic Cuts Neily',
        'ownerName': 'Roberto Jiménez Arias',
        'phone': '+506 8723-9901',
        'address': '50m norte del Parque Central, Ciudad Neily',
        'rating': 4.6,
        'reviewCount': 89,
        'imageUrl':
            'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800',
        'hasActivePromotion': true,
        'tags': ['degradado', 'diseño', 'color', 'keratina'],
        'isActive': true,
      }
    },
    {
      'id': 'barbershop_003',
      'lat': 8.6118,
      'lng': -82.9572,
      'data': {
        'name': 'El Maestro Barber Lounge',
        'ownerName': 'Óscar Brenes Solano',
        'phone': '+506 8645-7723',
        'address': 'Barrio El Carmen, frente a la escuela, Ciudad Neily',
        'rating': 4.5,
        'reviewCount': 203,
        'imageUrl':
            'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=800',
        'hasActivePromotion': false,
        'tags': ['clasico', 'afeitado', 'bigote', 'senior'],
        'isActive': true,
      }
    },
    {
      'id': 'barbershop_004',
      'lat': 8.6159,
      'lng': -82.9617,
      'data': {
        'name': 'Sharp & Clean Studio',
        'ownerName': 'Luis Diego Rojas',
        'phone': '+506 8531-2288',
        'address': 'Centro Comercial Plaza Neily, local 14',
        'rating': 4.3,
        'reviewCount': 56,
        'imageUrl':
            'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?w=800',
        'hasActivePromotion': false,
        'tags': ['fade', 'skin_fade', 'tratamientos_capilares'],
        'isActive': true,
      }
    },
    {
      'id': 'barbershop_005',
      'lat': 8.6101,
      'lng': -82.9553,
      'data': {
        'name': 'La Navaja de Oro',
        'ownerName': 'Mauricio Varela Cruz',
        'phone': '+506 8900-4412',
        'address': 'Barrio Las Palmas, 200m sur del EBAIS, Ciudad Neily',
        'rating': 4.7,
        'reviewCount': 311,
        'imageUrl':
            'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800',
        'hasActivePromotion': false,
        'tags': ['afeitado_clasico', 'navaja', 'arreglo_barba', 'cejas'],
        'isActive': true,
      }
    },
  ];

  for (final shop in barbershops) {
    final lat = shop['lat'] as double;
    final lng = shop['lng'] as double;
    final geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));

    final docData = {
      ...shop['data'] as Map<String, dynamic>,
      'position': geoFirePoint.data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await db
        .collection('barbershops')
        .doc(shop['id'] as String)
        .set(docData);

    // ignore: avoid_print
    print('✅ Barbería ${shop['id']} → geohash: '
        '${_geohashOf(geoFirePoint)}');
  }

  // ════════════════════════════════════════════════════════════════════════
  // 2) SERVICIOS DENORMALIZADOS
  // ════════════════════════════════════════════════════════════════════════
  //
  // Cada servicio guarda un snapshot de la barbería para que la
  // ServiceCard se pinte con UNA sola lectura.

  final services = [
    // Imperio Barbershop (001) — 2 servicios
    {
      'id': 'svc_001_corte',
      'barbershopId': 'barbershop_001',
      'lat': 8.6135,
      'lng': -82.9585,
      'snapshot': {
        'name': 'Imperio Barbershop',
        'imageUrl':
            'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=800',
        'rating': 4.8,
        'address': 'Av. Central, contiguo al Banco Nacional, Ciudad Neily',
      },
      'data': {
        'serviceName': 'Corte Clásico',
        'description':
            'Corte a tijera o máquina con acabado impecable, incluye lavado y peinado final.',
        'price': 6500.0,
        'durationMinutes': 30,
        'category': 'corte',
        'isActive': true,
      }
    },
    {
      'id': 'svc_001_combo',
      'barbershopId': 'barbershop_001',
      'lat': 8.6135,
      'lng': -82.9585,
      'snapshot': {
        'name': 'Imperio Barbershop',
        'imageUrl':
            'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=800',
        'rating': 4.8,
        'address': 'Av. Central, contiguo al Banco Nacional, Ciudad Neily',
      },
      'data': {
        'serviceName': 'Combo Premium Barba + Corte',
        'description':
            'Corte de cabello + perfilado y arreglo completo de barba con productos premium.',
        'price': 10500.0,
        'durationMinutes': 55,
        'category': 'combo',
        'isActive': true,
      }
    },
    // Galactic Cuts (002) — 2 servicios
    {
      'id': 'svc_002_fade',
      'barbershopId': 'barbershop_002',
      'lat': 8.6142,
      'lng': -82.9601,
      'snapshot': {
        'name': 'Galactic Cuts Neily',
        'imageUrl':
            'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800',
        'rating': 4.6,
        'address': '50m norte del Parque Central, Ciudad Neily',
      },
      'data': {
        'serviceName': 'Skin Fade Profesional',
        'description':
            'Degradado a piel con diseño personalizado, terminado con navaja para máxima precisión.',
        'price': 8000.0,
        'durationMinutes': 45,
        'category': 'corte',
        'isActive': true,
      }
    },
    {
      'id': 'svc_002_color',
      'barbershopId': 'barbershop_002',
      'lat': 8.6142,
      'lng': -82.9601,
      'snapshot': {
        'name': 'Galactic Cuts Neily',
        'imageUrl':
            'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800',
        'rating': 4.6,
        'address': '50m norte del Parque Central, Ciudad Neily',
      },
      'data': {
        'serviceName': 'Coloración + Corte',
        'description':
            'Aplicación de color profesional con corte incluido. Tinte de calidad, sin daño capilar.',
        'price': 15000.0,
        'durationMinutes': 90,
        'category': 'tratamiento',
        'isActive': true,
      }
    },
    // El Maestro (003) — 1 servicio
    {
      'id': 'svc_003_clasico',
      'barbershopId': 'barbershop_003',
      'lat': 8.6118,
      'lng': -82.9572,
      'snapshot': {
        'name': 'El Maestro Barber Lounge',
        'imageUrl':
            'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=800',
        'rating': 4.5,
        'address': 'Barrio El Carmen, frente a la escuela, Ciudad Neily',
      },
      'data': {
        'serviceName': 'Afeitado Clásico Caballero',
        'description':
            'Afeitado tradicional con toallas calientes, espuma artesanal y loción post-shave.',
        'price': 5500.0,
        'durationMinutes': 35,
        'category': 'barba',
        'isActive': true,
      }
    },
    // Sharp & Clean (004) — 1 servicio
    {
      'id': 'svc_004_tratamiento',
      'barbershopId': 'barbershop_004',
      'lat': 8.6159,
      'lng': -82.9617,
      'snapshot': {
        'name': 'Sharp & Clean Studio',
        'imageUrl':
            'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?w=800',
        'rating': 4.3,
        'address': 'Centro Comercial Plaza Neily, local 14',
      },
      'data': {
        'serviceName': 'Tratamiento Capilar Hidratante',
        'description':
            'Diagnóstico capilar + aplicación de mascarilla nutritiva con masaje craneal.',
        'price': 12000.0,
        'durationMinutes': 60,
        'category': 'tratamiento',
        'isActive': true,
      }
    },
    // La Navaja de Oro (005) — 1 servicio
    {
      'id': 'svc_005_navaja',
      'barbershopId': 'barbershop_005',
      'lat': 8.6101,
      'lng': -82.9553,
      'snapshot': {
        'name': 'La Navaja de Oro',
        'imageUrl':
            'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800',
        'rating': 4.7,
        'address': 'Barrio Las Palmas, 200m sur del EBAIS, Ciudad Neily',
      },
      'data': {
        'serviceName': 'Afeitado con Navaja Clásica',
        'description':
            'Ritual completo: pre-shave con vapor, afeitado con navaja recta, mascarilla post y cierre con agua fría.',
        'price': 9000.0,
        'durationMinutes': 40,
        'category': 'barba',
        'isActive': true,
      }
    },
  ];

  for (final svc in services) {
    final lat = svc['lat'] as double;
    final lng = svc['lng'] as double;
    final geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));

    final docData = {
      ...svc['data'] as Map<String, dynamic>,
      'barbershopId': svc['barbershopId'],
      'barbershopSnapshot': svc['snapshot'],
      'position': geoFirePoint.data,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await db
        .collection('services_explore')
        .doc(svc['id'] as String)
        .set(docData);

    // ignore: avoid_print
    print('✅ Servicio ${svc['id']} → geohash: '
        '${_geohashOf(geoFirePoint)}');
  }

  // ignore: avoid_print
  print('🎉 Seed completado: ${barbershops.length} barberías + '
      '${services.length} servicios');
}

/// Helper para imprimir el geohash sin repetir cast.
String _geohashOf(GeoFirePoint p) =>
    (p.data['geohash'] ?? 'N/A') as String;

// ── Borrar todo (útil para empezar de cero) ────────────────────────────────

Future<void> deleteAllExploreData() async {
  final db = FirebaseFirestore.instance;

  final shops = await db.collection('barbershops').get();
  for (final doc in shops.docs) {
    await doc.reference.delete();
  }

  final svcs = await db.collection('services_explore').get();
  for (final doc in svcs.docs) {
    await doc.reference.delete();
  }

  // ignore: avoid_print
  print('🗑️ Borradas ${shops.docs.length} barberías + '
      '${svcs.docs.length} servicios');
}