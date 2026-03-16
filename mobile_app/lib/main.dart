import 'package:flutter/material.dart';

import 'core/cache/cache_service.dart';
import 'core/routes/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/themes/app_theme.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/budget/budget_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/update/update_dialog.dart';
import 'repositories/transaction_repository.dart';
import 'services/analytics_service.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/budget_service.dart';
import 'services/profile_service.dart';
import 'services/transaction_service.dart';
import 'services/version_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();

  final authService = AuthService();

  runApp(MoneyManagerApp(authService: authService));
}

class MoneyManagerApp extends StatefulWidget {
  const MoneyManagerApp({super.key, required this.authService});

  final AuthService authService;

  @override
  State<MoneyManagerApp> createState() => _MoneyManagerAppState();
}

class _MoneyManagerAppState extends State<MoneyManagerApp> {
  bool _loggedIn = false;
  bool _checkingAuth = true;
  String? _cachedToken;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await widget.authService.isLoggedIn();
    if (loggedIn) {
      _cachedToken = await widget.authService.getToken();
    }
    if (mounted) {
      setState(() {
        _loggedIn = loggedIn;
        _checkingAuth = false;
      });
    }
  }

  void _onLoginSuccess() async {
    _cachedToken = await widget.authService.getToken();
    if (mounted) {
      setState(() {
        _loggedIn = true;
      });
    }
  }

  void _onLogout() async {
    await widget.authService.signOut();
    await CacheService.instance.clearAll();
    _cachedToken = null;
    if (mounted) {
      setState(() {
        _loggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: _checkingAuth
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _loggedIn
              ? _buildAppShell()
              : LoginScreen(
                  authService: widget.authService,
                  onLoginSuccess: _onLoginSuccess,
                ),
    );
  }

  Widget _buildAppShell() {
    final apiService = ApiService(
      tokenProvider: () => _cachedToken,
    );
    final repository = TransactionRepository(
      transactionService: TransactionService(apiService),
      analyticsService: AnalyticsService(apiService),
      budgetService: BudgetService(apiService),
    );
    final profileService = ProfileService(apiService);

    return AppShell(
      apiService: apiService,
      repository: repository,
      profileService: profileService,
      authService: widget.authService,
      onLogout: _onLogout,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.apiService,
    required this.repository,
    required this.profileService,
    required this.authService,
    required this.onLogout,
  });

  final ApiService apiService;
  final TransactionRepository repository;
  final ProfileService profileService;
  final AuthService authService;
  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  int _refreshToken = 0;
  VersionCheckResult? _forceUpdateResult;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final versionService = VersionService(widget.apiService);
    final result = await versionService.checkForUpdate();
    if (!mounted) return;

    if (result.updateRequired) {
      setState(() => _forceUpdateResult = result);
    } else if (result.updateAvailable) {
      showDialog(
        context: context,
        builder: (_) => UpdateAvailableDialog(result: result),
      );
    }
  }

  Future<void> _openAddTransaction() async {
    final saved = await Navigator.of(context).push<bool?>(
      AppRouter.addTransaction(widget.repository),
    );
    if (saved == true && mounted) {
      setState(() {
        _refreshToken++;
        _currentIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved successfully.')),
      );
    }
  }

  Future<void> _openTransactions() async {
    await Navigator.of(context).push<void>(
      AppRouter.transactions(widget.repository, _openTransactionDetail),
    );
    if (mounted) {
      setState(() {
        _refreshToken++;
      });
    }
  }

  Future<void> _openTransactionDetail(String transactionId) {
    return Navigator.of(context).push<void>(
      AppRouter.transactionDetail(widget.repository, transactionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_forceUpdateResult != null) {
      return UpdateRequiredScreen(result: _forceUpdateResult!);
    }

    final screens = [
      DashboardScreen(
        repository: widget.repository,
        refreshToken: _refreshToken,
        onViewAnalytics: () => setState(() => _currentIndex = 1),
        onViewBudgets: () => setState(() => _currentIndex = 2),
        onViewTransactions: _openTransactions,
        onOpenTransactionDetail: _openTransactionDetail,
      ),
      AnalyticsScreen(
        repository: widget.repository,
        refreshToken: _refreshToken,
      ),
      BudgetScreen(
        repository: widget.repository,
        refreshToken: _refreshToken,
        onBudgetChanged: () {
          if (mounted) {
            setState(() {
              _refreshToken++;
            });
          }
        },
      ),
      ProfileScreen(
        profileService: widget.profileService,
        authService: widget.authService,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        backgroundColor: AppTheme.lightTheme().colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 10,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _BottomBar(
        index: _currentIndex,
        onSelect: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme()
              .scaffoldBackgroundColor
              .withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x1A7073A0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120C1248),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              active: index == 0,
              label: 'Dashboard',
              icon: Icons.grid_view_rounded,
              onTap: () => onSelect(0),
            ),
            _NavItem(
              active: index == 1,
              label: 'Analytics',
              icon: Icons.bar_chart_rounded,
              onTap: () => onSelect(1),
            ),
            const SizedBox(width: 48),
            _NavItem(
              active: index == 2,
              label: 'Budget',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => onSelect(2),
            ),
            _NavItem(
              active: index == 3,
              label: 'Profile',
              icon: Icons.person_rounded,
              onTap: () => onSelect(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.active,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool active;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppTheme.lightTheme().colorScheme.primary
        : const Color(0xFF666A98);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
