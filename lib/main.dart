import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftbook_ai/login_page.dart';
import 'package:swiftbook_ai/theme_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required before using async in main
  await loadThemeFromPrefs(); // Load saved theme
  runApp(const MyApp());
}

// Global notifier to toggle theme
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

// Key for SharedPreferences
const String themePrefKey = 'theme_mode';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: currentTheme,
          theme: lightTheme,
          darkTheme: darkTheme,
          // Wrap LoginPage inside AppUpdateChecker
          home: const AppUpdateChecker(
            child: LoginPage(),
          ),
        );
      },
    );
  }
}

/// Helper Widget that checks for mandatory Play Store updates on Android
class AppUpdateChecker extends StatefulWidget {
  final Widget child;

  const AppUpdateChecker({super.key, required this.child});

  @override
  State<AppUpdateChecker> createState() => _AppUpdateCheckerState();
}

class _AppUpdateCheckerState extends State<AppUpdateChecker> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    // In-App Updates are only supported on Android
    if (!isAndroidPlatform()) {
      setState(() => _isChecking = false);
      return;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        // Trigger Google Play's full-screen immediate update screen
        final status = await InAppUpdate.performImmediateUpdate();

        // If user backs out or update fails, re-check to block entry
        if (status != AppUpdateResult.success) {
          _checkForUpdate();
          return;
        }
      }
    } catch (e) {
      debugPrint('InAppUpdate Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while querying Google Play
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Render the actual app once checked
    return widget.child;
  }
}

Future<void> loadThemeFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final themeString = prefs.getString(themePrefKey) ?? 'dark';
  themeNotifier.value = getThemeModeFromString(themeString);
}

// Convert string back to ThemeMode
ThemeMode getThemeModeFromString(String mode) {
  switch (mode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

/// Cross-platform safety check for dart:io
bool isAndroidPlatform() {
  try {
    return Platform.isAndroid;
  } catch (_) {
    return false; // Web or non-supported target
  }
}