import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'splashpage.dart';
import 'theme/app_theme.dart';
import 'services/database_helper.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.init();
  // Seed additional demo medicines (safe to call multiple times)
  await DatabaseHelper.instance.seedAdditionalDemoMedicines();
  runApp(const FindMedDemoApp());
}

class FindMedDemoApp extends StatelessWidget {
  const FindMedDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'FindMed Demo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashPage(),
      ),
    );
  }
}
