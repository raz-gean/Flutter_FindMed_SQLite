import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../models/user.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';

class MedicineFormPage extends StatefulWidget {
  final String title;
  final AppUser manager;
  final int branchId;
  final Medicine? existing;
  final Future<void> Function() onSuccess;
  const MedicineFormPage({
    super.key,
    required this.title,
    required this.manager,
    required this.branchId,
    required this.onSuccess,
    this.existing,
  });

  @override
  State<MedicineFormPage> createState() => _MedicineFormPageState();
}

class _MedicineFormPageState extends State<MedicineFormPage> {
  late TextEditingController _nameController;
  late TextEditingController _genericNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _stockController;
  late TextEditingController _priceController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _nameController = TextEditingController(text: m?.name ?? '');
    _genericNameController = TextEditingController(text: m?.genericName ?? '');
    _descriptionController = TextEditingController(text: m?.description ?? '');
    _stockController = TextEditingController(text: m?.stock.toString() ?? '0');
    _priceController = TextEditingController(
      text: m?.price.toStringAsFixed(2) ?? '0.00',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericNameController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    int stock;
    double price;
    try {
      stock = int.parse(_stockController.text.trim());
      if (stock < 0) stock = 0;
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid stock value')));
      return;
    }
    try {
      price = double.parse(_priceController.text.trim());
      if (price < 0) price = 0.0;
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid price value')));
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await DatabaseHelper.instance.addMedicine(
          name: name,
          genericName: _genericNameController.text.trim(),
          description: _descriptionController.text.trim(),
          managerId: widget.manager.id,
          branchId: widget.branchId,
          initialStock: stock,
          initialPrice: price,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Medicine added')));
      } else {
        final med = widget.existing!;
        await DatabaseHelper.instance.updateMedicine(
          medicineId: med.id,
          name: name,
          genericName: _genericNameController.text.trim(),
          description: _descriptionController.text.trim(),
          managerId: widget.manager.id,
          branchId: widget.branchId,
        );
        await DatabaseHelper.instance.updateMedicineInventory(
          medicineId: med.id,
          branchId: widget.branchId,
          managerId: widget.manager.id,
          newStock: stock,
          newPrice: price,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Medicine updated')));
      }
      await widget.onSuccess();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_nameController, 'Medicine Name *'),
          const SizedBox(height: 12),
          _field(_genericNameController, 'Generic Name'),
          const SizedBox(height: 12),
          _field(_descriptionController, 'Description', maxLines: 3),
          const SizedBox(height: 12),
          _field(
            _stockController,
            'Stock (integer)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _field(
            _priceController,
            'Price (₱)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _handleSave,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
