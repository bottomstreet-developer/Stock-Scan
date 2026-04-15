import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stocksnap/models/item.dart';
import 'package:stocksnap/screens/add_edit_item_screen.dart';
import 'package:stocksnap/services/database_service.dart';
import 'package:stocksnap/services/inventory_notifier.dart';
import 'package:stocksnap/services/prefs_service.dart';
import 'package:stocksnap/services/purchase_service.dart';
import 'package:stocksnap/utils/responsive.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final Item item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Item _item;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _updateQuantity(int delta) async {
    final nextQty = (_item.quantity + delta).clamp(0, 999999);
    final updated = _item.copyWith(
      quantity: nextQty,
      updatedAt: DateTime.now(),
    );
    setState(() => _loading = true);
    try {
      await DatabaseService.instance.updateItem(updated);
      notifyInventoryChanged();
      setState(() => _item = updated);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editItem() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditItemScreen(item: _item)),
    );
    if (!mounted) return;
    final reloaded = await DatabaseService.instance.getAllItems();
    if (!mounted) return;
    final matched = reloaded.where((e) => e.id == _item.id).firstOrNull;
    if (matched == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _item = matched);
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A0A0A),
              foregroundColor: Colors.white,
              minimumSize: const Size(90, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || _item.id == null) return;
    await DatabaseService.instance.deleteItem(_item.id!);
    notifyInventoryChanged();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = PrefsService.instance.currency;
    final hasPhoto = _item.photoPath != null && _item.photoPath!.isNotEmpty;
    return ValueListenableBuilder<bool>(
      valueListenable: PurchaseService.instance.isProNotifier,
      builder: (context, isPro, _) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _item.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: R.fs(22),
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE4E6EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasPhoto) ...[
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (ctx) => Scaffold(
                                  backgroundColor: Colors.black,
                                  body: SafeArea(
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: InteractiveViewer(
                                            child: Image.file(
                                              File(_item.photoPath!),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 16,
                                          left: 16,
                                          child: GestureDetector(
                                            onTap: () => Navigator.pop(ctx),
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.6,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.file(
                                        File(_item.photoPath!),
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'View',
                                      style: TextStyle(
                                        fontSize: R.fs(14),
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 12,
                                      color: Color(0xFF8A8A8A),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF0F1F3),
                        ),
                      ],
                      _row('SKU', _item.sku ?? '-'),
                      _row('Barcode', _item.barcode ?? '-'),
                      _row('Category', _item.category ?? '-'),
                      Row(
                        children: [
                          Text(
                            'Quantity',
                            style: TextStyle(fontSize: R.fs(14), color: Color(0xFF8A8A8A)),
                          ),
                          const Spacer(),
                          Text(
                            '${_item.quantity}',
                            style: TextStyle(
                              fontSize: R.fs(14),
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _loading ? null : () => _updateQuantity(-1),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF5F5F5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.remove, size: 18, color: Color(0xFF1A1A1A)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _loading ? null : () => _updateQuantity(1),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A1A1A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, size: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFFF0F1F3)),
                      _row('Cost Price', '$currencySymbol${_item.costPrice.toStringAsFixed(2)}'),
                      _row('Sell Price', '$currencySymbol${_item.sellPrice.toStringAsFixed(2)}'),
                      _row(
                        'Profit Margin',
                        isPro ? '${_item.profitMargin.toStringAsFixed(2)}%' : 'Pro feature',
                      ),
                      const Divider(color: Color(0xFFF0F1F3)),
                      _row('Min Quantity', _item.minQuantity.toString()),
                      const SizedBox(height: 8),
                      Text(
                        'Notes',
                        style: TextStyle(fontSize: R.fs(14), color: Color(0xFF8A8A8A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (_item.notes == null || _item.notes!.isEmpty) ? '-' : _item.notes!,
                        style: TextStyle(
                          fontSize: R.fs(14),
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: R.sp(52),
                child: ElevatedButton(
                  onPressed: _editItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Edit Item'),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _deleteItem,
                child: const Center(
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFFF4757),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: R.fs(14), color: Color(0xFF8A8A8A)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: R.fs(14),
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
