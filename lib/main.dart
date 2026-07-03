import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/firebase_service.dart';
import 'core/services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local-first storage initialization (no internet / Firebase config required).
  await Hive.initFlutter();
  await HiveService.instance.initialize();

  // Coba inisialisasi Firebase (auth/forum). Gagal gracefully → mode demo.
  await FirebaseService.initialize();

  runApp(
    const ProviderScope(child: StudyFlowApp()),
  );
}
