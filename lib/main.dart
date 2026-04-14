import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stocksnap/screens/home_screen.dart';
import 'package:stocksnap/utils/responsive.dart';
import 'package:stocksnap/services/database_service.dart';
import 'package:stocksnap/services/notification_service.dart';
import 'package:stocksnap/services/prefs_service.dart';
import 'package:stocksnap/services/purchase_service.dart';

class AppColors {
  static const primary = Color(0xFF1A1A1A);
  static const accent = Color(0xFF00C48C);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSecondary = Color(0xFFF8F9FA);
  static const border = Color(0xFFF0F1F3);
  static const borderStrong = Color(0xFFE4E6EA);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textTertiary = Color(0xFFB0B0B0);
  static const success = Color(0xFF00C48C);
  static const error = Color(0xFFFF4757);
}

bool suppressLock = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await PrefsService.instance.init();
  await DatabaseService.instance.database;
  await PurchaseService.instance.init();
  await NotificationService.instance.init();
  runApp(const StockSnapApp());
}

class StockSnapApp extends StatelessWidget {
  const StockSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);

    return MaterialApp(
      title: 'StockSnap',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        R.init(context);
        return child!;
      },
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          surfaceTint: Colors.transparent,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.interTextTheme(base.textTheme),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          shape: CircleBorder(),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1A1A1A),
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE4E6EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE4E6EA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF00C48C);
            }
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFBDEFE3);
            }
            return null;
          }),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Colors.transparent,
          iconTheme: WidgetStateProperty.all(const IconThemeData(size: 24)),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ),
      home: const AppEntry(),
    );
  }
}

int _compareAppStoreVersion(String store, String current) {
  List<int> parts(String v) {
    return v
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  final sa = parts(store);
  final sb = parts(current);
  final n = sa.length > sb.length ? sa.length : sb.length;
  for (var i = 0; i < n; i++) {
    final ai = i < sa.length ? sa[i] : 0;
    final bi = i < sb.length ? sb[i] : 0;
    if (ai != bi) return ai.compareTo(bi);
  }
  return 0;
}

Future<void> checkForStockSnapAppUpdate(BuildContext context) async {
  if (Platform.isAndroid) {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('InAppUpdate check failed: $e');
    }
  } else if (Platform.isIOS) {
    await _checkIOSUpdateFromShell(context);
  }
}

Future<void> _checkIOSUpdateFromShell(BuildContext context) async {
  if (!kReleaseMode) return;
  try {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!context.mounted) return;
    final response = await http.get(
      Uri.parse(
        'https://itunes.apple.com/lookup?bundleId=com.paprclip.inventory.tracker',
      ),
    );
    if (response.statusCode != 200) return;
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return;
    final results = data['results'];
    if (results is! List || results.isEmpty) return;
    final first = results[0];
    if (first is! Map<String, dynamic>) return;
    final storeVersion = first['version']?.toString();
    if (storeVersion == null || storeVersion.isEmpty) return;
    final info = await PackageInfo.fromPlatform();
    if (_compareAppStoreVersion(storeVersion, info.version) <= 0) return;
    if (!context.mounted) return;
    await Future.microtask(() async {
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'StockSnap',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A8A8A),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Update Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'A new version is available with improvements and bug fixes. Please update to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8A8A8A),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final uri = Uri.parse('https://apps.apple.com/app/id6746798698');
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: const Text('Update Now'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Version $storeVersion available',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFCCCCCC),
                ),
              ),
            ],
          ),
        ),
      );
    });
  } catch (_) {}
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> with WidgetsBindingObserver {
  bool _loading = true;
  bool _locked = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (suppressLock) return;
      SharedPreferences.getInstance().then((prefs) {
        final lockEnabled = prefs.getBool('app_lock_enabled') ?? false;
        if (!mounted || !lockEnabled) return;
        setState(() => _locked = true);
      });
    }
  }

  Future<void> _init() async {
    bool lockEnabled = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      lockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      if (lockEnabled) {
        final localAuth = LocalAuthentication();
        final available = await localAuth.isDeviceSupported();
        if (!available) lockEnabled = false;
      }
    } catch (_) {
      lockEnabled = false;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _locked = lockEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_locked) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              const Text(
                'StockSnap',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        final authenticated = await _localAuth.authenticate(
                          localizedReason: 'Unlock StockSnap',
                        );
                        if (!mounted) return;
                        if (authenticated) {
                          setState(() => _locked = false);
                        }
                      } catch (_) {}
                    },
                    child: const Text('Unlock'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const HomeScreen();
  }
}
