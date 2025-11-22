import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/findmed_logo.dart';

class EditBranchPage extends StatefulWidget {
  final Map<String, dynamic> branch;
  final List<Map<String, dynamic>> companies;
  const EditBranchPage({
    super.key,
    required this.branch,
    required this.companies,
  });

  @override
  State<EditBranchPage> createState() => _EditBranchPageState();
}

class _EditBranchPageState extends State<EditBranchPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _addrCtrl;
  late TextEditingController _phoneCtrl;
  late int _companyId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.branch['branch_name'] as String? ?? '',
    );
    _addrCtrl = TextEditingController(
      text: widget.branch['branch_address'] as String? ?? '',
    );
    _phoneCtrl = TextEditingController(
      text: widget.branch['phone_number'] as String? ?? '',
    );
    _companyId =
        widget.branch['company_id'] as int? ??
        widget.companies.first['id'] as int;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_nameCtrl.text.trim().isEmpty || _addrCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and address are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await DatabaseHelper.instance.updateBranchAdmin(
      branchId: widget.branch['id'] as int,
      companyId: _companyId,
      branchName: _nameCtrl.text.trim(),
      branchAddress: _addrCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update branch'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Row(
          children: [
            FindMedLogo(size: 34),
            SizedBox(width: 10),
            Text(
              'FindMed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Company',
              border: OutlineInputBorder(),
            ),
            initialValue: _companyId,
            items: widget.companies
                .map(
                  (c) => DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text(c['name'] as String),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _companyId = v ?? _companyId),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Branch Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addrCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Branch Address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
