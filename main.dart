import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'services/catalog_repository.dart';
import 'services/try_on_service.dart';
import 'state/try_on_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const TryOnApp());
}

class TryOnApp extends StatelessWidget {
  const TryOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Contract 1 (A <-> C): shared state.
        ChangeNotifierProvider(create: (_) => TryOnState()),
        // TODO(C): swap MockCatalogRepository for the real JSON-backed repo.
        Provider<CatalogRepository>(create: (_) => MockCatalogRepository()),
        // TODO(B): swap MockTryOnService for the Gemini / IDM-VTON client.
        Provider<TryOnService>(create: (_) => MockTryOnService()),
      ],
      child: MaterialApp(
        title: 'Virtual Try-On',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
