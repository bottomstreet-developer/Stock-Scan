import 'package:flutter/material.dart';
import 'package:stocksnap/screens/dashboard_screen.dart';
import 'package:stocksnap/screens/inventory_screen.dart';
import 'package:stocksnap/screens/settings_screen.dart';
import 'package:stocksnap/services/database_service.dart';
import 'package:stocksnap/services/stocksnap_tab_notifier.dart';
import 'package:stocksnap/services/notification_service.dart';
import 'package:stocksnap/services/prefs_service.dart';
import 'package:stocksnap/services/purchase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = stocksnapTabNotifier.value;
    stocksnapTabNotifier.addListener(_onTabNotifier);
    _refreshServices();
  }

  @override
  void dispose() {
    stocksnapTabNotifier.removeListener(_onTabNotifier);
    super.dispose();
  }

  void _onTabNotifier() {
    if (!mounted) return;
    setState(() => _index = stocksnapTabNotifier.value);
  }

  Future<void> _refreshServices() async {
    await PurchaseService.instance.refreshProStatus();
    final count = (await DatabaseService.instance.getAllItems()).length;
    await PrefsService.instance.setItemsCount(count);
    await NotificationService.instance.scheduleDailyLowStockCheck();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const InventoryScreen(),
      const DashboardScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF0A0A0A),
          unselectedItemColor: const Color(0xFF999999),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          iconSize: 24,
          currentIndex: _index,
          onTap: (value) => stocksnapTabNotifier.value = value,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.view_list_outlined),
              activeIcon: Icon(Icons.view_list_rounded),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
        ],
        ),
      ),
    );
  }
}
