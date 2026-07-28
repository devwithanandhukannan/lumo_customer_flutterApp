import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/session_storage.dart';
import 'core/network/api_client.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/customer_profile_setup_screen.dart';
import 'features/home/home_screen.dart';
import 'features/bookings/my_bookings_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/settings_screen.dart';
import 'features/safety/sos_button_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionStorage.init();
  runApp(const LumoCustomerApp());
}

class LumoCustomerApp extends StatelessWidget {
  const LumoCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LUMO — Safety Home Services',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _isAuthenticated;
  bool _profileComplete = false;

  @override
  void initState() {
    super.initState();
    ApiClient.onUnauthorizedOrNotFound = () {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _profileComplete = false;
        });
      }
    };
    _verifyUserExists();
  }

  Future<void> _verifyUserExists() async {
    if (!SessionStorage.isAuthenticated) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _profileComplete = false;
        });
      }
      return;
    }

    try {
      final user = await ApiClient.getMe();
      if (user == null || user['id'] == null || user['isActive'] == false) {
        // User does not exist in database or is disabled — purge local storage completely!
        await SessionStorage.clearSession();
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _profileComplete = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _profileComplete = SessionStorage.isProfileComplete;
          });
        }
      }
    } catch (_) {
      await SessionStorage.clearSession();
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _profileComplete = false;
        });
      }
    }
  }

  void _onLoginSuccess() {
    // After OTP verified — check if profile is already complete
    if (mounted) {
      setState(() {
        _isAuthenticated = true;
        _profileComplete = SessionStorage.isProfileComplete;
      });
    }
  }

  void _onProfileComplete() {
    if (mounted) setState(() => _profileComplete = true);
  }

  void _onLogout() async {
    await SessionStorage.clearSession();
    if (mounted) setState(() {
      _isAuthenticated = false;
      _profileComplete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (!_isAuthenticated!) {
      return AuthScreen(onLoginSuccess: _onLoginSuccess);
    }
    // First-time registration — show profile completion
    if (!_profileComplete) {
      return CustomerProfileSetupScreen(onCompleted: _onProfileComplete);
    }
    return MainAppShell(onLogout: _onLogout);
  }
}

class MainAppShell extends StatefulWidget {
  final VoidCallback onLogout;
  const MainAppShell({super.key, required this.onLogout});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const MyBookingsScreen(),
      ProfileScreen(onLogout: widget.onLogout),
      SettingsScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButton: _currentIndex == 0 ? const SosButtonWidget() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LUMO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                Text(
                  SessionStorage.userName.isNotEmpty ? 'Hello, ${SessionStorage.userName.split(' ').first}!' : 'Home Services',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successGreenSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.successGreen.withAlpha(60)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, color: AppColors.successGreen, size: 12),
                SizedBox(width: 4),
                Text('SAFE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.successGreen)),
              ],
            ),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.only(top: 16),
        child: HomeScreen(),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', isSelected: currentIndex == 0, onTap: () => onTap(0)),
            _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Bookings', isSelected: currentIndex == 1, onTap: () => onTap(1)),
            _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', isSelected: currentIndex == 2, onTap: () => onTap(2)),
            _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings', isSelected: currentIndex == 3, onTap: () => onTap(3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? activeIcon : icon, color: isSelected ? AppColors.primary : AppColors.textMuted, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? AppColors.primary : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
