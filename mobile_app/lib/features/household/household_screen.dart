import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/themes/app_theme.dart';
import '../../models/household_model.dart';
import '../../services/household_service.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key, required this.householdService});

  final HouseholdService householdService;

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  List<HouseholdModel> _households = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _households = await widget.householdService.getHouseholds();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _error = e; _loading = false; });
    }
  }

  Future<void> _createHousehold() async {
    final name = await _showInputDialog('Create Household', 'Household name');
    if (name == null || name.trim().isEmpty) return;
    try {
      await widget.householdService.createHousehold(name.trim());
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _joinHousehold() async {
    final code = await _showInputDialog('Join Household', 'Invite code');
    if (code == null || code.trim().isEmpty) return;
    try {
      await widget.householdService.joinHousehold(code.trim());
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String?> _showInputDialog(String title, String hint) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Households')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: FilledButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                )
              : _households.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.group_outlined, size: 64, color: AppColors.primaryDim),
                            const SizedBox(height: 16),
                            Text(
                              'No households yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a household or join one using an invite code.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _households.length,
                      itemBuilder: (ctx, i) => _HouseholdCard(
                        household: _households[i],
                        onLeave: () async {
                          await widget.householdService.leaveHousehold(_households[i].id);
                          _load();
                        },
                      ),
                    ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _createHousehold,
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _joinHousehold,
                  icon: const Icon(Icons.group_add_rounded),
                  label: const Text('Join'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HouseholdCard extends StatelessWidget {
  const _HouseholdCard({required this.household, required this.onLeave});

  final HouseholdModel household;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    household.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.exit_to_app, size: 20),
                  onPressed: onLeave,
                  tooltip: 'Leave household',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.vpn_key_rounded, size: 16, color: AppColors.primaryDim),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    household.inviteCode,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: household.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied!')),
                    );
                  },
                  tooltip: 'Copy invite code',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${household.members.length} member(s)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ...household.members.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${m.userName} (${m.role})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
