import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/findmed_logo.dart';
import '../widgets/company_logo.dart';
import '../services/database_helper.dart';
import '../models/user.dart';

class AssignManagerPage extends StatefulWidget {
  final AppUser? manager; // present for new assignment
  final Map<String, dynamic>? managerData; // present for reassign
  final List<Map<String, dynamic>> branches;
  final List<Map<String, dynamic>> companies;
  final bool isReassign;

  const AssignManagerPage({
    super.key,
    this.manager,
    this.managerData,
    required this.branches,
    required this.companies,
    required this.isReassign,
  });

  @override
  State<AssignManagerPage> createState() => _AssignManagerPageState();
}

class _AssignManagerPageState extends State<AssignManagerPage> {
  int? _selectedBranchId;
  bool _processing = false;
  late final Map<int, String> _companyNameById;

  @override
  void initState() {
    super.initState();
    _companyNameById = {
      for (final c in widget.companies) c['id'] as int: c['name'] as String,
    };
    if (widget.isReassign) {
      _selectedBranchId =
          widget.managerData?['branch_id'] as int?; // preselect current
    }
  }

  Future<void> _commit() async {
    if (_selectedBranchId == null || _processing) return;
    setState(() => _processing = true);
    bool success = false;
    try {
      if (widget.isReassign) {
        final managerId = widget.managerData!['id'] as int;
        success = await DatabaseHelper.instance.reassignManagerToBranch(
          managerId,
          _selectedBranchId!,
        );
      } else {
        final managerId = widget.manager!.id;
        success = await DatabaseHelper.instance.assignManagerToBranchAdmin(
          managerId,
          _selectedBranchId!,
        );
      }
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    setState(() => _processing = false);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isReassign
                ? 'Failed to reassign manager'
                : 'Failed to assign manager',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.isReassign
        ? (widget.managerData?['display_name'] as String? ?? 'Manager')
        : (widget.manager?.displayName ?? 'Manager');
    // Current branch id (only in reassign mode); safe null checks.
    final int? currentBranchId = widget.isReassign
        ? (widget.managerData != null
              ? widget.managerData!['branch_id'] as int?
              : null)
        : null;
    // Group branches by company for formal grouped UI
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final b in widget.branches) {
      final cid = b['company_id'] as int?;
      if (cid == null) continue;
      grouped.putIfAbsent(cid, () => []).add(b);
    }
    // Sort companies by name
    final sortedCompanyIds = grouped.keys.toList()
      ..sort(
        (a, b) =>
            (_companyNameById[a] ?? '').compareTo(_companyNameById[b] ?? ''),
      );
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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isReassign ? 'Reassign Manager' : 'Assign Manager',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brandBlueDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manager: $displayName',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a branch below. Each entry shows its company.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: sortedCompanyIds.length,
              itemBuilder: (context, idx) {
                final companyId = sortedCompanyIds[idx];
                final companyName = _companyNameById[companyId] ?? 'Company';
                final companyBranches = grouped[companyId]!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CompanyLogo(companyName: companyName, size: 42),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                companyName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.brandBlueDark,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.brandBlue.withValues(
                                  alpha: 0.07,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.brandBlue.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Text(
                                '${companyBranches.length} branches',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.brandBlueDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...companyBranches.map((b) {
                          final branchId = b['id'] as int;
                          final selected = _selectedBranchId == branchId;
                          final isCurrent =
                              currentBranchId != null &&
                              currentBranchId == branchId;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                setState(() => _selectedBranchId = branchId),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.brandBlue
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                                color: selected
                                    ? AppTheme.brandBlue.withValues(alpha: 0.06)
                                    : Colors.white,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.store,
                                    color: selected
                                        ? AppTheme.brandBlue
                                        : AppTheme.brandBlueDark,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              b['branch_name'] as String? ?? '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (isCurrent)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange
                                                      .withValues(alpha: 0.10),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.orange
                                                        .withValues(
                                                          alpha: 0.40,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Current',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          (b['branch_address'] as String? ?? '')
                                              .trim(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.brandBlue,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _selectedBranchId == null || _processing
                      ? null
                      : _commit,
                  icon: _processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _processing
                        ? (widget.isReassign
                              ? 'Reassigning...'
                              : 'Assigning...')
                        : (widget.isReassign
                              ? 'Confirm Reassign'
                              : 'Confirm Assign'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
