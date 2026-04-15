import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stocksnap/services/purchase_service.dart';
import 'package:stocksnap/utils/responsive.dart';

class StocksnapProPlanSheet extends StatefulWidget {
  const StocksnapProPlanSheet({super.key});

  @override
  State<StocksnapProPlanSheet> createState() => _StocksnapProPlanSheetState();
}

class _StocksnapProPlanSheetState extends State<StocksnapProPlanSheet> {
  String _selectedPlan = 'yearly';
  bool _isPurchasing = false;
  String _monthlyPrice = '\$4.99 / month';
  String _yearlyPrice = '\$34.99 / year';

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    try {
      final offerings = await PurchaseService.instance.getOfferings();
      final packages = offerings?.current?.availablePackages ?? [];
      for (final p in packages) {
        final priceStr = p.storeProduct.priceString;
        if (p.packageType == PackageType.monthly) {
          if (mounted) setState(() => _monthlyPrice = '$priceStr / month');
        } else if (p.packageType == PackageType.annual) {
          if (mounted) setState(() => _yearlyPrice = '$priceStr / year');
        }
      }
    } catch (_) {
      // keep hardcoded fallback prices if fetch fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'StockSnap Pro',
              style: TextStyle(
                fontSize: R.fs(22),
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Unlimited items & profit tracking',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF888888),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const _FeatureRow(text: 'Unlimited Items (Free = 30)'),
            const _FeatureRow(text: 'Profit & Margin Tracking'),
            const _FeatureRow(text: 'Low Stock Alerts'),
            const _FeatureRow(text: 'CSV Export'),
            const _FeatureRow(text: 'Backup & Restore Inventory'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PlanOption(
                    selected: _selectedPlan == 'yearly',
                    title: 'Yearly',
                    subtitle: _yearlyPrice,
                    onTap: () => setState(() => _selectedPlan = 'yearly'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlanOption(
                    selected: _selectedPlan == 'monthly',
                    title: 'Monthly',
                    subtitle: _monthlyPrice,
                    onTap: () => setState(() => _selectedPlan = 'monthly'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isPurchasing
                  ? null
                  : () async {
                      setState(() => _isPurchasing = true);
                      try {
                        final success = _selectedPlan == 'yearly'
                            ? await PurchaseService.instance.purchaseAnnual()
                            : await PurchaseService.instance.purchaseMonthly();
                        if (!context.mounted) return;
                        if (success) {
                          Navigator.of(context).pop(true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Purchase unavailable. Please try again.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        final msg = e.toString().contains('cancelled')
                            ? 'Purchase cancelled.'
                            : 'Something went wrong. Please try again.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                      } finally {
                        if (mounted) setState(() => _isPurchasing = false);
                      }
                    },
              child: Container(
                width: double.infinity,
                height: R.sp(54),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C48C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isPurchasing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _selectedPlan == 'yearly'
                              ? 'Continue with Yearly'
                              : 'Continue with Monthly',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF888888),
              ),
              child: const Text('Maybe later'),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    final restored = await PurchaseService.instance.restorePurchases();
                    if (!context.mounted) return;
                    if (restored) Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    'Restore purchases',
                    style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    await launchUrl(
                      Uri.parse('https://paprclip.app/terms'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: const Text(
                    'Terms of Use',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB0B0B0)),
                  ),
                ),
                const Text(
                  ' · ',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB0B0B0)),
                ),
                GestureDetector(
                  onTap: () async {
                    await launchUrl(
                      Uri.parse('https://paprclip.app/privacy'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB0B0B0)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.star, size: 14, color: Color(0xFF00C48C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: R.fs(14), color: const Color(0xFF0A0A0A)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF0A0A0A) : const Color(0xFFE8E8E8),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF0A0A0A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: selected ? const Color(0xAAFFFFFF) : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showStocksnapProUpgradeSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const StocksnapProPlanSheet(),
  );
}
