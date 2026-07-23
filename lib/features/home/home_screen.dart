import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../booking/booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _categories = [];
  String? _selectedCategoryId;
  List<dynamic> _services = [];
  bool _loadingCategories = false;
  bool _loadingServices = false;
  bool _femaleProPreferred = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });
    try {
      final cats = await ApiClient.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loadingCategories = false;
        });
        if (cats.isNotEmpty) {
          _selectCategory(cats[0]['id']?.toString() ?? '');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
          // Use hardcoded fallback categories if backend not available
          _categories = _fallbackCategories;
        });
        if (_categories.isNotEmpty) {
          _selectCategory(_categories[0]['id']?.toString() ?? '');
        }
      }
    }
  }

  Future<void> _selectCategory(String categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _loadingServices = true;
    });
    try {
      final svcs = await ApiClient.getServices(categoryId: categoryId);
      if (mounted) {
        setState(() {
          _services = svcs.isNotEmpty ? svcs : _getFallbackServices(categoryId);
          _loadingServices = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _services = _getFallbackServices(categoryId);
          _loadingServices = false;
        });
      }
    }
  }

  void _openBooking(Map<String, dynamic> service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          service: service,
          femaleProPreferred: _femaleProPreferred,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Safety Preference Banner ──────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_user, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Female Pro Preferred',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 13)),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: _femaleProPreferred,
                            activeTrackColor: AppColors.primary,
                            activeThumbColor: Colors.white,
                            onChanged: (v) => setState(() => _femaleProPreferred = v),
                          ),
                        ),
                      ],
                    ),
                    const Text('Police-verified female pros for female customers',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Service Categories', style: AppText.heading3),
        ),
        const SizedBox(height: 12),

        // ── Category Pills ────────────────────────────────────────────────
        if (_loadingCategories)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.primary)))
        else
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategoryId == cat['id']?.toString();
                return GestureDetector(
                  onTap: () => _selectCategory(cat['id']?.toString() ?? ''),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      cat['name']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Available Services', style: AppText.heading3),
        ),
        const SizedBox(height: 12),

        // ── Service Grid ──────────────────────────────────────────────────
        if (_loadingServices)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.primary)))
        else if (_services.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No services available',
                      style: TextStyle(color: AppColors.textMuted))))
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _services.length,
              itemBuilder: (_, i) {
                final svc = _services[i];
                return _ServiceCard(
                  service: svc,
                  onTap: () => _openBooking(svc),
                );
              },
            ),
          ),
        const SizedBox(height: 100), // FAB clearance
      ],
    );
  }

  // ─── Fallback Data ─────────────────────────────────────────────────────────
  static final List<Map<String, dynamic>> _fallbackCategories = [
    {'id': 'cat-clean', 'name': 'Cleaning'},
    {'id': 'cat-elec', 'name': 'Electrical'},
    {'id': 'cat-plumb', 'name': 'Plumbing'},
    {'id': 'cat-salon', 'name': 'Salon & Spa'},
    {'id': 'cat-safety', 'name': 'Safety'},
  ];

  List<Map<String, dynamic>> _getFallbackServices(String catId) {
    final fallbacks = {
      'cat-clean': [
        {'id': 'srv-clean-01', 'name': 'Home Deep Cleaning', 'base_price': '499', 'duration_minutes': 120, 'icon': '🧹'},
        {'id': 'srv-clean-02', 'name': 'Kitchen Cleaning', 'base_price': '349', 'duration_minutes': 60, 'icon': '🍽️'},
        {'id': 'srv-clean-03', 'name': 'Bathroom Sanitization', 'base_price': '299', 'duration_minutes': 45, 'icon': '🚿'},
      ],
      'cat-elec': [
        {'id': 'srv-elec-01', 'name': 'Switch & Socket Repair', 'base_price': '199', 'duration_minutes': 30, 'icon': '⚡'},
        {'id': 'srv-elec-02', 'name': 'Fan Installation', 'base_price': '249', 'duration_minutes': 45, 'icon': '💨'},
        {'id': 'srv-elec-03', 'name': 'Wiring & Inspection', 'base_price': '599', 'duration_minutes': 90, 'icon': '🔌'},
      ],
      'cat-plumb': [
        {'id': 'srv-plumb-01', 'name': 'Tap Repair', 'base_price': '249', 'duration_minutes': 30, 'icon': '🔧'},
        {'id': 'srv-plumb-02', 'name': 'Pipe Leak Fix', 'base_price': '349', 'duration_minutes': 60, 'icon': '🪠'},
        {'id': 'srv-plumb-03', 'name': 'Drain Unblocking', 'base_price': '399', 'duration_minutes': 45, 'icon': '🚰'},
      ],
      'cat-salon': [
        {'id': 'srv-salon-01', 'name': 'Home Haircut (Female)', 'base_price': '499', 'duration_minutes': 60, 'icon': '✂️'},
        {'id': 'srv-salon-02', 'name': 'Facial & Cleanup', 'base_price': '799', 'duration_minutes': 90, 'icon': '🧖'},
        {'id': 'srv-salon-03', 'name': 'Mehendi Design', 'base_price': '599', 'duration_minutes': 120, 'icon': '🌿'},
      ],
      'cat-safety': [
        {'id': 'srv-safe-01', 'name': 'Women Safety Escort', 'base_price': '999', 'duration_minutes': 120, 'icon': '🛡️'},
        {'id': 'srv-safe-02', 'name': 'Night Guard Visit', 'base_price': '1499', 'duration_minutes': 240, 'icon': '🌙'},
      ],
    };
    return fallbacks[catId] ?? [];
  }
}

// ─── Service Card ────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  Color get _accentColor {
    final id = service['id']?.toString() ?? '';
    if (id.contains('clean')) return const Color(0xFF3B82F6);
    if (id.contains('elec')) return const Color(0xFFF59E0B);
    if (id.contains('plumb')) return const Color(0xFF10B981);
    if (id.contains('salon')) return const Color(0xFFEC4899);
    if (id.contains('safe')) return const Color(0xFFEF4444);
    return const Color(0xFF6366F1);
  }

  @override
  Widget build(BuildContext context) {
    final price = service['base_price']?.toString() ?? '0';
    final duration = service['duration_minutes']?.toString() ?? '0';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accentColor.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  service['icon']?.toString() ?? '🔧',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const Spacer(),
            Text(
              service['name']?.toString() ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('₹$price',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _accentColor,
                        fontSize: 13)),
                const Spacer(),
                Text('$duration min',
                    style: AppText.caption.copyWith(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
