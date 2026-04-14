import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stocksnap/models/item.dart';
import 'package:stocksnap/screens/add_edit_item_screen.dart';
import 'package:stocksnap/screens/item_detail_screen.dart';
import 'package:stocksnap/services/database_service.dart';
import 'package:stocksnap/services/inventory_notifier.dart';
import 'package:stocksnap/services/prefs_service.dart';
import 'package:stocksnap/services/purchase_service.dart';
import 'package:stocksnap/utils/responsive.dart';
import 'package:stocksnap/widgets/item_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Item> _items = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    inventoryChangeNotifier.addListener(_onInventoryChanged);
    _loadItems();
    _searchController.addListener(_searchItems);
  }

  @override
  void dispose() {
    inventoryChangeNotifier.removeListener(_onInventoryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onInventoryChanged() => _loadItems();

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final items = await DatabaseService.instance.getAllItems();
      await PrefsService.instance.setItemsCount(items.length);
      if (!mounted) return;
      setState(() {
        _items = items;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load inventory.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchItems() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      await _loadItems();
      return;
    }
    final results = await DatabaseService.instance.searchItems(query);
    if (!mounted) return;
    setState(() => _items = results);
  }

  void _onSearch(String _) {
    _searchItems();
  }

  Future<void> _openAddItem() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
    );
    await _loadItems();
  }

  Future<void> _showDebugSampleItemsSheet() async {
    final now = DateTime.now();
    final sampleItems = <Item>[
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
    final selected = List<bool>.filled(sampleItems.length, false);

    final added = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Debug: Add Sample Items',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select items to insert',
                style: TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(sampleItems.length, (index) {
                      final item = sampleItems[index];
                      return CheckboxListTile(
                        value: selected[index],
                        activeColor: const Color(0xFF00C48C),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setModalState(() => selected[index] = value ?? false);
                        },
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        subtitle: Text(
                          '${item.sku} · Qty ${item.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    for (var i = 0; i < sampleItems.length; i++) {
                      if (selected[i]) {
                        await DatabaseService.instance.insertItem(sampleItems[i]);
                      }
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Add Selected'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (added == true) {
      await _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = PurchaseService.instance.isPro;
    final currency = PrefsService.instance.currency;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Inventory',
          style: TextStyle(
            fontSize: R.fs(28),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        titleSpacing: 20,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE4E6EA)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search Items...',
                  hintStyle: TextStyle(color: Color(0xFF8A8A8A), fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF8A8A8A), size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: R.ph(16, 14),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: Color(0xFF1A1A1A),
                backgroundColor: Colors.white,
                onRefresh: _loadItems,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            children: [
                              _stateCard(
                                icon: Icons.error_outline,
                                title: 'Something went wrong',
                                message: _errorMessage!,
                                actionLabel: 'Try again',
                                onAction: _loadItems,
                              ),
                            ],
                          )
                        : _items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(
                                    height: 500,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            size: 48,
                                            color: Color(0xFFCCCCCC),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No Items Yet',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0A0A0A),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Tap + To Add Your First Item',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF8A8A8A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.all(R.sp(16)),
                                itemCount: _items.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: R.sp(8)),
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  return ItemCard(
                                    item: item,
                                    currency: currency,
                                    showProfit: isPro,
                                    onTap: () async {
                                      await showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24),
                                          ),
                                        ),
                                        builder: (context) => ItemDetailScreen(item: item),
                                      );
                                      await _loadItems();
                                    },
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      floatingActionButton: GestureDetector(
        onLongPress: kDebugMode ? _showDebugSampleItemsSheet : null,
        child: FloatingActionButton(
          onPressed: _openAddItem,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF0A0A0A), size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF888888), height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
