import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stocksnap/models/item.dart';
import 'package:stocksnap/screens/mobile_scanner_screen.dart';
import 'package:stocksnap/services/database_service.dart';
import 'package:stocksnap/services/inventory_notifier.dart';
import 'package:stocksnap/services/prefs_service.dart';
import 'package:stocksnap/services/purchase_service.dart';
import 'package:stocksnap/utils/responsive.dart';
import 'package:stocksnap/widgets/pro_upgrade_sheet.dart';

class AddEditItemScreen extends StatefulWidget {
  const AddEditItemScreen({super.key, this.item});

  final Item? item;

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  bool get _canScan {
    if (Platform.isIOS) {
      return !Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
    }
    return true;
  }

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController(text: '');
  final _costController = TextEditingController(text: '');
  final _sellController = TextEditingController(text: '');
  final _minQtyController = TextEditingController(text: '');
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _photoPath;
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item == null) return;
    _nameController.text = item.name;
    _skuController.text = item.sku ?? '';
    _barcodeController.text = item.barcode ?? '';
    _categoryController.text = item.category ?? '';
    _quantityController.text = item.quantity.toString();
    _costController.text = item.costPrice.toString();
    _sellController.text = item.sellPrice.toString();
    _minQtyController.text = item.minQuantity.toString();
    _notesController.text = item.notes ?? '';
    _photoPath = item.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _sellController.dispose();
    _minQtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (photo == null) return;
      setState(() => _photoPath = photo.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to pick image.')),
      );
    }
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const MobileScannerScreen(),
      ),
    );
    if (!mounted || code == null || code.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _barcodeController.text = code);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final allItems = await DatabaseService.instance.getAllItems();
      final isPro = PurchaseService.instance.isPro;
      if (!_isEdit && !isPro && allItems.length >= 30) {
        if (mounted) {
          await showStocksnapProUpgradeSheet(context);
        }
        // After paywall closes, re-check pro status.
        if (!PurchaseService.instance.isPro) return;
      }

      final now = DateTime.now();
      final item = Item(
        id: widget.item?.id,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        barcode:
            _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
        costPrice: double.tryParse(_costController.text.trim()) ?? 0,
        sellPrice: double.tryParse(_sellController.text.trim()) ?? 0,
        photoPath: _photoPath,
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        minQuantity: int.tryParse(_minQtyController.text.trim()) ?? 0,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.item?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEdit) {
        await DatabaseService.instance.updateItem(item);
      } else {
        await DatabaseService.instance.insertItem(item);
      }
      final count = (await DatabaseService.instance.getAllItems()).length;
      await PrefsService.instance.setItemsCount(count);
      notifyInventoryChanged();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save item.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showPrefillPicker() {
    final currencySymbol = PrefsService.instance.currency;
    final samples = <Map<String, String>>[
      {
        'name': 'Nike Air Max',
        'sku': 'NK001',
        'category': 'Footwear',
        'cost': '45',
        'sell': '120',
        'qty': '10',
        'min': '2',
        'notes': 'Popular resale sneakers',
      },
      {
        'name': 'Vintage Denim Jacket',
        'sku': 'VDJ01',
        'category': 'Apparel',
        'cost': '15',
        'sell': '65',
        'qty': '3',
        'min': '1',
        'notes': 'Thrifted classic fit',
      },
      {
        'name': 'iPhone 14 Case',
        'sku': 'IP14C',
        'category': 'Accessories',
        'cost': '3',
        'sell': '19.99',
        'qty': '25',
        'min': '5',
        'notes': 'Clear shockproof case',
      },
      {
        'name': 'Thrift Store Lamp',
        'sku': 'TSL01',
        'category': 'Home Decor',
        'cost': '8',
        'sell': '35',
        'qty': '2',
        'min': '1',
        'notes': 'Vintage brass finish',
      },
      {
        'name': 'Levi\'s 501 Jeans',
        'sku': 'LV501',
        'category': 'Apparel',
        'cost': '20',
        'sell': '75',
        'qty': '5',
        'min': '1',
        'notes': 'Classic straight fit',
      },
      {
        'name': 'Ceramic Mug Set',
        'sku': 'CMS01',
        'category': 'Kitchen',
        'cost': '12',
        'sell': '34.99',
        'qty': '8',
        'min': '2',
        'notes': 'Set of 4 handmade mugs',
      },
      {
        'name': 'Polaroid Camera',
        'sku': 'POL01',
        'category': 'Electronics',
        'cost': '45',
        'sell': '110',
        'qty': '1',
        'min': '1',
        'notes': 'Tested and working',
      },
      {
        'name': 'Vintage Sunglasses',
        'sku': 'VS001',
        'category': 'Accessories',
        'cost': '5',
        'sell': '28',
        'qty': '6',
        'min': '2',
        'notes': 'Retro frame style',
      },
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Prefill with sample',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetContext),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...samples.map(
                (item) => GestureDetector(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _nameController.text = item['name']!;
                      _skuController.text = item['sku']!;
                      _categoryController.text = item['category']!;
                      _costController.text = item['cost']!;
                      _sellController.text = item['sell']!;
                      _quantityController.text = item['qty']!;
                      _minQtyController.text = item['min']!;
                      _notesController.text = item['notes']!;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF0F1F3)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item['category']} · $currencySymbol${item['sell']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8A8A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Color(0xFFCCCCCC),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = PrefsService.instance.currency;
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              mini: true,
              backgroundColor: Colors.orange,
              onPressed: _showPrefillPicker,
              child: const Icon(
                Icons.bug_report,
                color: Colors.white,
                size: 18,
              ),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 12,
              16,
              12,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.item == null ? 'Add Item' : 'Edit Item',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _photoPath == null
                              ? const Icon(Icons.add_a_photo, color: Color(0xFF8A8A8A))
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(File(_photoPath!), fit: BoxFit.cover),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _nameController,
                        label: 'Name',
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      _field(controller: _skuController, label: 'SKU'),
                      const SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.fromLTRB(R.sp(16), R.sp(12), R.sp(16), R.sp(12)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE4E6EA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Barcode',
                              style: TextStyle(
                                fontSize: R.fs(12),
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _barcodeController,
                                    style: TextStyle(
                                      fontSize: R.fs(15),
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                if (_canScan) ...[
                                  GestureDetector(
                                    onTap: _scanBarcode,
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.qr_code_scanner,
                                        size: 22,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _field(controller: _categoryController, label: 'Category'),
                      const SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.fromLTRB(R.sp(16), R.sp(12), R.sp(16), R.sp(12)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE4E6EA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cost price',
                              style: TextStyle(
                                fontSize: R.fs(12),
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  currencySymbol,
                                  style: TextStyle(
                                    fontSize: R.fs(15),
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: TextFormField(
                                    controller: _costController,
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    style: TextStyle(
                                      fontSize: R.fs(15),
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.fromLTRB(R.sp(16), R.sp(12), R.sp(16), R.sp(12)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE4E6EA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sell price',
                              style: TextStyle(
                                fontSize: R.fs(12),
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  currencySymbol,
                                  style: TextStyle(
                                    fontSize: R.fs(15),
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: TextFormField(
                                    controller: _sellController,
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    style: TextStyle(
                                      fontSize: R.fs(15),
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _quantityController,
                        label: 'Quantity',
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            int.tryParse(value ?? '') == null ? 'Enter a valid number' : null,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _minQtyController,
                        label: 'Min quantity for alert',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _notesController,
                        label: 'Notes',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Item'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF8A8A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? prefixText,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(R.sp(16), R.sp(12), R.sp(16), R.sp(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E6EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: R.fs(12),
              color: Color(0xFF8A8A8A),
            ),
          ),
          const SizedBox(height: 2),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: TextStyle(
              fontSize: R.fs(15),
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ).copyWith(
              prefixText: prefixText,
              prefixStyle: TextStyle(
                fontSize: R.fs(15),
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
