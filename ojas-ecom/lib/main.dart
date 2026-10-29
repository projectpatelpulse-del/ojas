import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:ojas_user/core/routes/app_router.dart';
import 'package:ojas_user/core/services/session_service.dart';
import 'package:provider/provider.dart';
import 'package:ojas_user/core/services/socket_service.dart';
import 'package:ojas_user/core/controllers/settings_controller.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/core/controllers/wishlist_controller.dart';
import 'package:ojas_user/core/theme/app_theme.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable browser address bar URL updates when using context.push()
  GoRouter.optionURLReflectsImperativeAPIs = true;
  
  // Initialize Firebase for Web with explicit options (safely check if already initialized)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC2StOCcAiACVKZg1G4d1k-zyl1YxctVcQ",
        authDomain: "ojas-app-d0bc6.firebaseapp.com",
        projectId: "ojas-app-d0bc6",
        storageBucket: "ojas-app-d0bc6.firebasestorage.app",
        messagingSenderId: "25163277339",
        appId: "1:25163277339:web:90cc45ebf7f2189b4bc4be",
        measurementId: "G-ZYKJ1CH89N",
      ),
    );
  }

  await SessionService.instance.initSession();
  
  // Initialize Real-time services
  SocketService.instance.init();
  await SettingsController.instance.init();
  await HomeController.instance.init();
  await WishlistController.instance.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: SettingsController.instance),
        ChangeNotifierProvider.value(value: HomeController.instance),
        ChangeNotifierProvider.value(value: WishlistController.instance),
      ],
      child: ListenableBuilder(
        listenable: Listenable.merge([
          SettingsController.instance,
          HomeController.instance,
          WishlistController.instance,
        ]),
        builder: (context, _) {
          final settings = SettingsController.instance.settings;

          return Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp.router(
                routerConfig: AppRouter.router,
                debugShowCheckedModeBanner: false,
                title: settings.marketplaceName,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeMode.dark,
              );
            },
          );
        },
      ),
    );
  }
}
