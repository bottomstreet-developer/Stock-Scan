import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  PrefsService._();

  static final PrefsService instance = PrefsService._();
  SharedPreferences? _prefs;

  static const _isProKey = 'is_pro';
  static const _itemsCountKey = 'items_count';
  static const _currencyKey = 'currency_symbol';
  static const _legacyCurrencyKey = 'currency';
  static const _notificationsEnabledKey = 'notifications_enabled';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _sp {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('PrefsService.init() must be called before use.');
    }
    return prefs;
  }

  bool get isPro => _sp.getBool(_isProKey) ?? false;
  Future<void> setIsPro(bool value) => _sp.setBool(_isProKey, value);

  int get itemsCount => _sp.getInt(_itemsCountKey) ?? 0;
  Future<void> setItemsCount(int value) => _sp.setInt(_itemsCountKey, value);

  String get currency {
    final stored = _sp.getString(_currencyKey) ?? _sp.getString(_legacyCurrencyKey);
    return _normalizeCurrencySymbol(stored);
  }

  Future<void> setCurrency(String value) =>
      _sp.setString(_currencyKey, _normalizeCurrencySymbol(value));

  String _normalizeCurrencySymbol(String? value) {
    switch (value) {
      case 'USD':
      case r'$':
        return r'$';
      case 'GBP':
      case '£':
        return '£';
      case 'EUR':
      case '€':
        return '€';
      case 'INR':
      case '₹':
        return '₹';
      case 'JPY':
      case '¥':
        return '¥';
      case 'AUD':
      case 'A\$':
        return 'A\$';
      case 'CAD':
      case 'C\$':
        return 'C\$';
      case 'SGD':
      case 'S\$':
        return 'S\$';
      default:
        return r'$';
    }
  }

  bool get notificationsEnabled =>
      _sp.getBool(_notificationsEnabledKey) ?? false;
  Future<void> setNotificationsEnabled(bool value) =>
      _sp.setBool(_notificationsEnabledKey, value);
}
