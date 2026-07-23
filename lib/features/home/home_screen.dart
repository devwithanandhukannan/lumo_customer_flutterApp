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
    setState(() => _loadingCategories = true);
    try {
      final cats = await ApiClient.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loadingCategories = false;
        });
        if (cats.isNotEmpty) _selectCategory(cats[0]['id']?.toString() ?? '');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categories = _fallbackCategories;
          _loadingCategories = false;
        });
        if (_categories.isNotEmpty) _selectCategory(_categories[0]['id']?.toString() ?? '');
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
      if (mounted) setState(() { _services = svcs.isNotEmpty ? svcs : _getFallbackServices(categoryId); _loadingServices = false; });
    } catch (_) {
      if (mounted) setState(() { _services = _getFallbackServices(categoryId); _loadingServices = false; });
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
        // Safety preference
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
                        const Text('Female Pro Preferred', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                        const Spacer(),
                        Switch(
                          value: _femaleProPreferred,
                          activeTrackColor: AppColors.primary,
                          activeThumbColor: Colors.white,
                          onChanged: (v) => setState(() => _femaleProPreferred = v),
                        ),
                      ],
                    ),
                    const Text('Police-verified female pros for female customers', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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

        if (_loadingCategories)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(cat['name']?.toString() ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textMuted)),
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

        if (_loadingServices)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                return GestureDetector(
                  onTap: () => _openBooking(svc),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(svc['icon']?.toString() ?? '🔧', style: const TextStyle(fontSize: 24)),
                        const Spacer(),
                        Text(svc['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text('₹${svc['base_price']}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 100),
      ],
    );
  }

  static final List<Map<String, dynamic>> _fallbackCategories = [
    {'id': 'cat-clean', 'name': 'Cleaning'},
    {'id': 'cat-elec', 'name': 'Electrical'},
    {'id': 'cat-plumb', 'name': 'Plumbing'},
    {'id': 'cat-salon', 'name': 'Salon & Spa'},
    {'id': 'cat-safety', 'name': 'Safety'},
  ];

  List<Map<String, dynamic>> _getFallbackServices(String catId) {
    return [
      {'id': 'srv-clean-01', 'name': 'Home Deep Cleaning', 'base_price': '499', 'duration_minutes': 120, 'icon': '🧹'},
      {'id': 'srv-clean-02', 'name': 'Kitchen Cleaning', 'base_price': '349', 'duration_minutes': 60, 'icon': '🍽️'},
    ];
  }
}
