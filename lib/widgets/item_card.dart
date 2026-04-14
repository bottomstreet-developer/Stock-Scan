import 'package:flutter/material.dart';
import 'package:stocksnap/models/item.dart';
import 'package:stocksnap/utils/responsive.dart';
import 'package:stocksnap/services/prefs_service.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.currency,
    required this.showProfit,
    this.onTap,
  });

  final Item item;
  final String currency;
  final bool showProfit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lowStock = item.isLowStock;
    final currencySymbol = PrefsService.instance.currency;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: R.sp(16), vertical: R.sp(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF0F1F3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (lowStock)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4757),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: R.fs(15),
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.category ?? '',
                  style: TextStyle(fontSize: R.fs(13), color: Color(0xFF8A8A8A)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currencySymbol${item.sellPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: R.fs(15), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.quantity} In Stock',
                  style: TextStyle(fontSize: R.fs(13), color: Color(0xFF8A8A8A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
