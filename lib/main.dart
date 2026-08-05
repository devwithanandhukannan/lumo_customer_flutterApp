import 'dart:ui';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/session_storage.dart';
import 'core/network/api_client.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/customer_profile_setup_screen.dart';
import 'features/home/home_screen.dart';
import 'features/bookings/my_bookings_screen.dart';
import 'features/profile/profile_screen.dart';
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
        backgroundColor: Colors.transparent,
        titleSpacing: 16,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withAlpha(80), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF0F172A), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('LUMO', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                  Text(
                    SessionStorage.userName.isNotEmpty ? 'Hello, ${SessionStorage.userName.split(' ').first}!' : 'Home Services',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successGreenSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.successGreen.withAlpha(80)),
              boxShadow: [
                BoxShadow(color: AppColors.successGreen.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, color: AppColors.successGreen, size: 14),
                SizedBox(width: 4),
                Text('SAFE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.successGreen, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.only(top: 8),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x2EFFFFFF), Color(0x12FFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorderBright, width: 1.2),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', isSelected: currentIndex == 0, onTap: () => onTap(0)),
                _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Bookings', isSelected: currentIndex == 1, onTap: () => onTap(1)),
                _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile & Settings', isSelected: currentIndex == 2, onTap: () => onTap(2)),
              ],
            ),
          ),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary.withAlpha(120) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
