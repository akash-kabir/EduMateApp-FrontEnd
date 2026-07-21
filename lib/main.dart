import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'provider/animation_provider.dart';
import 'package:flutter/foundation.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/pwa_install_screen.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const EduMateApp());
}

class EduMateApp extends StatefulWidget {
  const EduMateApp({super.key});

  @override
  State<EduMateApp> createState() => _EduMateAppState();
}

class _EduMateAppState extends State<EduMateApp> with TickerProviderStateMixin {
  late AnimationProvider _animationProvider;

  @override
  void initState() {
    super.initState();
    _animationProvider = AnimationProvider(this);
  }

  @override
  void dispose() {
    _animationProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _animationProvider,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'EduMate',
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: (kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
            ? const PwaInstallScreen()
            : const SplashScreen(),
      ),
    );
  }
}
