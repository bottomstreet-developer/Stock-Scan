import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:stocksnap/services/prefs_service.dart';

class PurchaseService {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();
  static const String _entitlementId = 'stocksnap_pro';
  static const String _androidApiKey = 'goog_VwCbaIyncqJjCpPfw0DIUvVdpwL';
  static const String _iosApiKey = 'appl_NSfnjqhiHLlXSAiWLANTmRcLWRE';

  final ValueNotifier<bool> isProNotifier = ValueNotifier<bool>(false);
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      final configuration = PurchasesConfiguration(
        Platform.isIOS ? _iosApiKey : _androidApiKey,
      );
      await Purchases.configure(configuration);
      await refreshProStatus();
    } catch (_) {
      isProNotifier.value = PrefsService.instance.isPro;
    } finally {
      _initialized = true;
    }
  }

  bool get isPro => isProNotifier.value;

  void addListener(VoidCallback listener) {
    isProNotifier.addListener(listener);
  }

  void removeListener(VoidCallback listener) {
    isProNotifier.removeListener(listener);
  }

  Future<void> refreshProStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isActive =
          customerInfo.entitlements.active.containsKey(_entitlementId);
      isProNotifier.value = isActive;
      await PrefsService.instance.setIsPro(isActive);
    } catch (_) {
      isProNotifier.value = PrefsService.instance.isPro;
    }
  }

  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  Future<bool> purchaseMonthly() async {
    return _purchaseByType(PackageType.monthly);
  }

  Future<bool> purchaseAnnual() async {
    return _purchaseByType(PackageType.annual);
  }

  Future<bool> _purchaseByType(PackageType packageType) async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return false;
      final package = current.availablePackages
          .where((p) => p.packageType == packageType)
          .firstOrNull;
      if (package == null) return false;
      await Purchases.purchasePackage(package);
      await refreshProStatus();
      return isPro;
    } catch (_) {
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
      await refreshProStatus();
      return isPro;
    } catch (_) {
      return false;
    }
  }
}
