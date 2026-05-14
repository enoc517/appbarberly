import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/router/app_router.dart';
import 'firebase_options.dart';

// import 'package:flutter/foundation.dart' show kDebugMode;
// import 'package:barberly/features/explore/data/seeds/explore_seed.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔍 TEST TEMPORAL
  try {
    await FirebaseFirestore.instance.collection('_test').doc('ping').set({
      'timestamp': FieldValue.serverTimestamp(),
      'message': 'Hola desde Flutter',
    });
    debugPrint('✅ Escritura OK');
  } catch (e) {
    debugPrint('❌ Error: $e');
  }
/*
  if (kDebugMode) {
    await seedBarbershopsAndServices();
  }
*/
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
