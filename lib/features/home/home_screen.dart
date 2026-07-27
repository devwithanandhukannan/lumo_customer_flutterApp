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
  List<dynamic> _allServices = [];
  bool _loadingCategories = false;
  bool _loadingServices = false;
  bool _femaleProPreferred = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadAllServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllServices() async {
    try {
      final svcs = await ApiClient.getServices();
      if (mounted) setState(() => _allServices = svcs);
    } catch (_) {}
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
          _categories = [];
          _loadingCategories = false;
        });
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
      if (mounted) setState(() { _services = svcs; _loadingServices = false; });
    } catch (_) {
      if (mounted) setState(() { _services = []; _loadingServices = false; });
    }
  }

  List<dynamic> get _displayedServices {
    final list = _searchQuery.trim().isNotEmpty ? _allServices : _services;
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final desc = (s['description'] ?? '').toString().toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();
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
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        await _loadCategories();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // Search input
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search for home services (e.g. Plumbing, Cleaning)',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.cardBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
        ),

        const SizedBox(height: 16),
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
        if (_searchQuery.isEmpty) ...[
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
        ],

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(_searchQuery.isNotEmpty ? 'Search Results (${_displayedServices.length})' : 'Available Services', style: AppText.heading3),
        ),
        const SizedBox(height: 12),

        if (_loadingServices)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else if (_displayedServices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('No services found.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            ),
          )
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
              itemCount: _displayedServices.length,
              itemBuilder: (_, i) {
                final svc = _displayedServices[i];
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
    ),
  ),
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
