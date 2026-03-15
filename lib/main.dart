
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_app_check/firebase_app_check.dart'; // Add App Check
import 'package:google_fonts/google_fonts.dart';
import 'ui/splash_screen.dart';
import 'ui/home_screen.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/verify_email_screen.dart';
import 'ui/profile/profile_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/history/history_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  // Initialize App Check
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
      webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'), 
    );
  } catch (e) {
    debugPrint("App Check init error: $e");
  }

  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the simple StateProvider we created
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'SonicFix',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      
      // LIGHT THEME
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), // Tech Blue
          brightness: Brightness.light,
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFFFF9800), // Orange Accent
          tertiary: const Color(0xFF00BCD4), // Cyan
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      ),
      
      // DARK THEME
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E17), // Deep Space Blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
          primary: const Color(0xFF2196F3), // Tech Blue
          secondary: const Color(0xFFFF9800), // Orange Accent
          surface: const Color(0xFF131B29),
          surfaceContainerHighest: const Color(0xFF1E2A3F),
          onSurface: Colors.white,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
        ),
        // Removed cardTheme to prevent type errors - Material 3 defaults are excellent
      ),
      
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth_wrapper': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          if (user.emailVerified) {
             return const HomeScreen(); 
          } else {
             return const VerifyEmailScreen();
          }
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}