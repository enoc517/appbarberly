import 'package:cloud_firestore/cloud_firestore.dart';

/// Pobla Firestore con una barbería de prueba completa.
///
/// Idempotente: se puede llamar varias veces, sobrescribe los mismos docs
/// pero no duplica. El shop ID es fijo ('shop-1') para que tu app lo encuentre
/// siempre en el mismo lugar.
///
/// 🧹 Borrar este archivo cuando el seed ya no sea necesario.
Future<void> seedDemoData() async {
  final firestore = FirebaseFirestore.instance;
  const shopId = 'shop-1';

  final shopRef = firestore.collection('barbershops').doc(shopId);

  // ---- 1. El barbershop (doc raíz) ----
  await shopRef.set({
    'name': 'La Tijera Dorada',
    'district': 'Escazú, San José',
    'heroImageUrl':
        'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=1200',
    'ownerId': 'owner-demo-1',
  });

  // ---- 2. Servicios (subcolección /services) ----
  final services = [
    {
      'id': 'svc-corte',
      'name': 'Corte clásico',
      'description': 'Corte con tijera y máquina, incluye lavado',
      'durationMinutes': 30,
      'price': 8000.0,
      'featured': true,
    },
    {
      'id': 'svc-barba',
      'name': 'Arreglo de barba',
      'description': 'Perfilado, recorte y toalla caliente',
      'durationMinutes': 20,
      'price': 6000.0,
      'featured': false,
    },
    {
      'id': 'svc-combo',
      'name': 'Combo corte + barba',
      'description': 'El paquete completo, con masaje facial',
      'durationMinutes': 45,
      'price': 12000.0,
      'featured': true,
    },
    {
      'id': 'svc-tinte',
      'name': 'Tinte',
      'description': 'Coloración profesional con productos premium',
      'durationMinutes': 60,
      'price': 18000.0,
      'featured': false,
    },
  ];

  for (final svc in services) {
    final id = svc['id'] as String;
    final data = Map<String, dynamic>.from(svc)..remove('id');
    await shopRef.collection('services').doc(id).set(data);
  }

  // ---- 3. Barberos (subcolección /barbers) ----
  final barbers = [
    {
      'id': 'barber-carlos',
      'name': 'Carlos Méndez',
      'avatarUrl':
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=300',
      'active': true,
    },
    {
      'id': 'barber-diego',
      'name': 'Diego Solís',
      'avatarUrl':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
      'active': true,
    },
    {
      'id': 'barber-luis',
      'name': 'Luis Vargas',
      'avatarUrl':
          'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=300',
      'active': true,
    },
  ];

  for (final b in barbers) {
    final id = b['id'] as String;
    final data = Map<String, dynamic>.from(b)..remove('id');
    await shopRef.collection('barbers').doc(id).set(data);
  }

  // ---- 4. Slots de los próximos 7 días (subcolección /slots/{YYYY-MM-DD}) ----
  final today = DateTime.now();
  final startDay = DateTime(today.year, today.month, today.day);

  for (var i = 0; i < 7; i++) {
    final day = startDay.add(Duration(days: i));
    final dayKey = _dateKey(day);

    // Slots de 9:00 a 18:00 cada 30 minutos (18 slots por día)
    final times = <Map<String, dynamic>>[];
    for (var hour = 9; hour < 18; hour++) {
      for (var minute = 0; minute < 60; minute += 30) {
        final startTime = DateTime(day.year, day.month, day.day, hour, minute);
        times.add({
          'startTime': startTime.toIso8601String(),
          'status': 'available',
        });
      }
    }

    await shopRef.collection('slots').doc(dayKey).set({
      'times': times,
    });
  }
}

String _dateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}