import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stocksnap/models/item.dart';
import 'package:stocksnap/screens/earn_screen.dart';
import 'package:stocksnap/services/database_service.dart';
import 'package:stocksnap/services/inventory_notifier.dart';
import 'package:stocksnap/services/notification_service.dart';
import 'package:stocksnap/services/prefs_service.dart';
import 'package:stocksnap/services/purchase_service.dart';
import 'package:stocksnap/services/backup_service.dart';
import 'package:stocksnap/utils/app_dialogs.dart';
import 'package:stocksnap/utils/app_feedback.dart';
import 'package:stocksnap/utils/responsive.dart';
import 'package:stocksnap/widgets/pro_upgrade_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '-';
  String _currencySymbol = '\$';
  Future<String?> _lastBackupDateFuture = BackupService.getLastBackupDate();
  bool _appLockEnabled = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    PurchaseService.instance.addListener(_onProChanged);
    _loadVersion();
    _loadCurrencySymbol();
    _loadAppLockEnabled();
  }

  void _onProChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PurchaseService.instance.removeListener(_onProChanged);
    super.dispose();
  }

  Future<void> _loadAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
    });
  }

  Future<void> _loadCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    final symbol = prefs.getString('currency_symbol') ?? PrefsService.instance.currency;
    if (!mounted) return;
    setState(() {
      _currencySymbol = symbol;
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = '${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _launchUrl(String value) async {
    final uri = Uri.parse(value);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _getCurrencyLabel(String symbol) {
    const map = {
      '\$': 'USD',
      '£': 'GBP',
      '€': 'EUR',
      '₹': 'INR',
      '¥': 'JPY',
      'A\$': 'AUD',
      'C\$': 'CAD',
      'S\$': 'SGD',
    };
    return map[symbol] ?? symbol;
  }

  Future<void> _handleAppLockToggle(bool value) async {
    if (value) {
      try {
        // Check if device supports biometrics at hardware level
        final isSupported = await _localAuth.isDeviceSupported();
        if (!isSupported) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Biometric authentication not supported on this device',
                ),
              ),
            );
          }
          return;
        }

        // Get available biometrics
        await _localAuth.getAvailableBiometrics();

        // If no biometrics enrolled, still allow PIN/pattern as fallback
        // by proceeding with authenticate which will use device credentials
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Confirm to enable App Lock',
          options: const AuthenticationOptions(
            biometricOnly: false, // allow PIN/pattern fallback
            stickyAuth: true,
          ),
        );

        if (!authenticated) return;
      } catch (e) {
        debugPrint('Biometric error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not enable App Lock: ${e.toString()}')),
          );
        }
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', value);
    if (mounted) setState(() => _appLockEnabled = value);
  }

  void _showCurrencyPicker() {
    final currencies = [
      {'symbol': '\$', 'label': 'USD — US Dollar'},
      {'symbol': '£', 'label': 'GBP — British Pound'},
      {'symbol': '€', 'label': 'EUR — Euro'},
      {'symbol': '₹', 'label': 'INR — Indian Rupee'},
      {'symbol': '¥', 'label': 'JPY — Japanese Yen'},
      {'symbol': 'A\$', 'label': 'AUD — Australian Dollar'},
      {'symbol': 'C\$', 'label': 'CAD — Canadian Dollar'},
      {'symbol': 'S\$', 'label': 'SGD — Singapore Dollar'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Currency',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...currencies.map(
              (c) => GestureDetector(
                onTap: () async {
                  setState(() => _currencySymbol = c['symbol']!);
                  await PrefsService.instance.setCurrency(_currencySymbol);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF0F1F3)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                c['symbol']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            c['label']!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      if (_currencySymbol == c['symbol'])
                        const Icon(
                          Icons.check,
                          size: 18,
                          color: Color(0xFF00C48C),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setDebugPro(bool value) async {
    PurchaseService.instance.isProNotifier.value = value;
    await PrefsService.instance.setIsPro(value);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _addSampleItems() async {
    final now = DateTime.now();
    final sampleItems = [
      Item(
        name: 'Nike Air Max',
        sku: 'NK001',
        quantity: 10,
        costPrice: 45,
        sellPrice: 120,
        category: 'Footwear',
        minQuantity: 2,
        notes: 'Popular resale sneakers',
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        name: 'Vintage Denim Jacket',
        sku: 'VDJ01',
        quantity: 3,
        costPrice: 15,
        sellPrice: 65,
        category: 'Apparel',
        minQuantity: 1,
        notes: 'Thrifted classic fit',
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        name: 'iPhone 14 Case',
        sku: 'IP14C',
        quantity: 25,
        costPrice: 3,
        sellPrice: 19.99,
        category: 'Accessories',
        minQuantity: 5,
        notes: 'Clear shockproof case',
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        name: 'Thrift Store Lamp',
        sku: 'TSL01',
        quantity: 2,
        costPrice: 8,
        sellPrice: 35,
        category: 'Home Decor',
        minQuantity: 1,
        notes: 'Ceramic vintage base',
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        name: 'Levi\'s 501 Jeans',
        sku: 'LV501',
        quantity: 5,
        costPrice: 20,
        sellPrice: 75,
        category: 'Apparel',
        minQuantity: 2,
        notes: 'High demand size mix',
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        name: 'Ceramic Mug Set',
        sku: 'CMS01',
        quantity: 8,
        costPrice: 12,
        sellPrice: 34.99,
        category: 'Kitchen',
        minQuantity: 2,
        notes: 'Set of 4 handmade mugs',
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        name: 'Polaroid Camera',
        sku: 'POL01',
        quantity: 1,
        costPrice: 45,
        sellPrice: 110,
        category: 'Electronics',
        minQuantity: 1,
        notes: 'Tested and working',
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        name: 'Vintage Sunglasses',
        sku: 'VS001',
        quantity: 6,
        costPrice: 5,
        sellPrice: 28,
        category: 'Accessories',
        minQuantity: 2,
        notes: 'Retro frame style',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    try {
      for (final item in sampleItems) {
        await DatabaseService.instance.insertItem(item);
      }
      final count = (await DatabaseService.instance.getAllItems()).length;
      await PrefsService.instance.setItemsCount(count);
      notifyInventoryChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample items added.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add sample items.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PurchaseService.instance.isProNotifier,
      builder: (context, isPro, _) => Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        titleSpacing: 20,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isPro) ...[
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STOCKSNAP PRO',
                      style: TextStyle(
                        fontSize: R.fs(11),
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF999999),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _featureRow('Unlimited Items (Free = 30)'),
                    _featureRow('Profit & Margin Tracking'),
                    _featureRow('Low Stock Alerts'),
                    _featureRow('CSV Export'),
                    _featureRow('Backup & Restore Inventory'),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: isPro ? null : () => showStocksnapProUpgradeSheet(context),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            isPro ? 'You are Pro' : 'Upgrade to Pro',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final ok = await PurchaseService.instance.restorePurchases();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Purchases restored.'
                                : 'No active purchases found.'),
                          ),
                        );
                        setState(() {});
                      },
                      child: const SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Restore Purchases',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('REMINDERS'),
                  _row(
                    'Low Stock Alerts',
                    trailing: Switch(
                      activeThumbColor: const Color(0xFF00C48C),
                      value: PrefsService.instance.notificationsEnabled,
                      onChanged: (value) async {
                        if (value == true && !PurchaseService.instance.isPro) {
                          await showStocksnapProUpgradeSheet(context);
                          return;
                        }
                        if (value) {
                          await NotificationService.instance.requestPermission();
                        }
                        await PrefsService.instance.setNotificationsEnabled(value);
                        await NotificationService.instance.scheduleDailyLowStockCheck();
                        if (!context.mounted) return;
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('SECURITY'),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF0F1F3)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Lock',
                                style: TextStyle(
                                  fontSize: R.fs(15),
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Require Face ID / Fingerprint To Open StockSnap',
                                style: TextStyle(
                                  fontSize: R.fs(12),
                                  color: Color(0xFF8A8A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          activeThumbColor: const Color(0xFF00C48C),
                          value: _appLockEnabled,
                          onChanged: _handleAppLockToggle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('BACKUP'),
                  FutureBuilder<String?>(
                    future: _lastBackupDateFuture,
                    builder: (context, snapshot) {
                      final date = snapshot.data;
                      return Text(
                        date != null ? 'Last backed up: $date' : 'Never backed up',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A8A8A),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      if (!PurchaseService.instance.isPro) {
                        await showStocksnapProUpgradeSheet(context);
                        return;
                      }
                      final ok = await BackupService.backupNow(context);
                      if (!context.mounted) return;
                      showAppSnackBar(ok ? 'Backup complete' : 'Backup failed');
                      if (ok && mounted) {
                        setState(() {
                          _lastBackupDateFuture = BackupService.getLastBackupDate();
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Back Up Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      if (!PurchaseService.instance.isPro) {
                        await showStocksnapProUpgradeSheet(context);
                        return;
                      }
                      final confirm = await showConfirmDialog(
                        context,
                        title: 'Restore Backup',
                        content:
                            'This will replace all your current inventory with the backup. This cannot be undone.',
                        confirmLabel: 'Restore',
                        cancelLabel: 'Cancel',
                      );
                      if (confirm != true || !context.mounted) return;
                      final ok = await BackupService.restoreBackup();
                      if (!context.mounted) return;
                      showAppSnackBar(ok
                          ? 'Restore complete. Restart the app.'
                          : 'Restore failed');
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Center(
                        child: Text(
                          'Restore Backup',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('ACCOUNT'),
                  _row(
                    'Currency',
                    onTap: _showCurrencyPicker,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getCurrencyLabel(_currencySymbol),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Color(0xFFCCCCCC),
                        ),
                      ],
                    ),
                  ),
                  _row(
                    'Refer & Earn',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C48C)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Earn 30%',
                            style: TextStyle(
                              fontSize: R.fs(11),
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00C48C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Color(0xFFCCCCCC),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const EarnScreen(),
                      ),
                    ),
                  ),
                  _row(
                    'Feedback',
                    onTap: () => _launchUrl('https://forms.gle/4dnFBwmwAMgpkXmb6'),
                  ),
                  _row(
                    'Privacy Policy',
                    onTap: () => _launchUrl('https://paprclip.app/privacy'),
                  ),
                  _row(
                    'Terms of Use',
                    onTap: () => _launchUrl('https://paprclip.app/terms'),
                  ),
                  _row(
                    'App Version',
                    trailing: Text(
                      _version,
                      style: const TextStyle(color: Color(0xFF8A8A8A)),
                    ),
                  ),
                ],
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFBD59)),
                ),
                child: Column(
                  children: [
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEBUG: Pro Access',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            'Toggle Pro features without purchasing',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A8A8A),
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: PurchaseService.instance.isPro,
                        onChanged: _setDebugPro,
                        activeThumbColor: const Color(0xFF00C48C),
                      ),
                    ],
                  ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _addSampleItems,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1A1A1A)),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1A1A1A),
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Add sample items',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(R.sp(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8ECF0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 0, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: R.fs(11),
          fontWeight: FontWeight.w600,
          color: Color(0xFF8A8A8A),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _row(String label, {Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF0F1F3)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: R.fs(15),
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.star, size: 16, color: Color(0xFF00C896)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
            ),
          ),
        ],
      ),
    );
  }

}
