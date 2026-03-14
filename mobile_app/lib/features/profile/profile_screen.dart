import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/themes/app_theme.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profileService,
  });

  final ProfileService profileService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();
  final _membersController = TextEditingController();

  ProfileModel _profile = ProfileModel.empty();
  Object? _error;
  bool _loading = true;
  bool _saving = false;
  String _currency = 'INR';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await widget.profileService.getProfile();
      if (!mounted) {
        return;
      }
      _profile = profile;
      _nameController.text = profile.name;
      _incomeController.text = profile.monthlyIncomeRupees.toStringAsFixed(0);
      _membersController.text = profile.householdMembers.toString();
      _currency = profile.currency;
      setState(() {
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final incomeRupees = double.tryParse(_incomeController.text.trim());
    final members = int.tryParse(_membersController.text.trim());

    if (name.isEmpty ||
        incomeRupees == null ||
        incomeRupees < 0 ||
        members == null ||
        members <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a valid name, income, and household size.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final saved = await widget.profileService.saveProfile(
        _profile.copyWith(
          name: name,
          monthlyIncome: (incomeRupees * 100).round(),
          currency: _currency,
          householdMembers: members,
        ),
      );
      if (!mounted) {
        return;
      }
      _profile = saved;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully.')),
      );
      setState(() {
        _saving = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: FilledButton(
          onPressed: _load,
          child: const Text('Retry profile'),
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding,
          12,
          AppConstants.pagePadding,
          130,
        ),
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCD9FF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child:
                    const Icon(Icons.person_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Text(
                'Household Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDim],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x240F52FF),
                  blurRadius: 28,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOUSEHOLD SUMMARY',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  _profile.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        label: 'Monthly Income',
                        value:
                            'Rs ${_profile.monthlyIncomeRupees.toStringAsFixed(0)}',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _HeroStat(
                        label: 'Members',
                        value: '${_profile.householdMembers}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SectionCard(
            title: 'Owner Details',
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _incomeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Income (Rs)',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Household Preferences',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  items: const [
                    DropdownMenuItem(value: 'INR', child: Text('INR')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _currency = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _membersController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Household Members'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDim],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x220F52FF),
                    blurRadius: 24,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Text('Save Profile'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
