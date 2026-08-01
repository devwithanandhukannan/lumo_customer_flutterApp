import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';
import '../booking/booking_screen.dart';
import '../location/location_picker_modal.dart';

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
  bool _femaleProPreferred = false; // Update 4: Computed from customer gender in initState
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _activeAddress = SessionStorage.activeAddress;
  double _activeLat = SessionStorage.activeLat;
  double _activeLng = SessionStorage.activeLng;

  @override
  void initState() {
    super.initState();
    _activeAddress = SessionStorage.activeAddress;
    _activeLat = SessionStorage.activeLat;
    _activeLng = SessionStorage.activeLng;
    _loadCategories();
    _loadAllServices();
    // Update 4: Auto-enable female protection for female customers
    // Update 4: Auto-enable female protection for female customers
    final customerSex = SessionStorage.sex.toUpperCase();
    _femaleProPreferred = (customerSex == 'FEMALE');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPickerModal(
        initialAddress: _activeAddress,
        initialLat: _activeLat,
        initialLng: _activeLng,
        onLocationSelected: (addr, lat, lng) async {
          await SessionStorage.setLocation(addr, lat, lng);
          if (mounted) {
            setState(() {
              _activeAddress = addr;
              _activeLat = lat;
              _activeLng = lng;
            });
            _loadAllServices();
            if (_selectedCategoryId != null) _selectCategory(_selectedCategoryId!);
          }
        },
      ),
    );
  }

  Future<void> _loadAllServices() async {
    try {
      final svcs = await ApiClient.getServices(latitude: _activeLat, longitude: _activeLng);
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
      final svcs = await ApiClient.getServices(categoryId: categoryId, latitude: _activeLat, longitude: _activeLng);
      if (mounted) setState(() { _services = svcs; _loadingServices = false; });
    } catch (_) {
      if (mounted) setState(() { _services = []; _loadingServices = false; });
    }
  }

  List<dynamic> get _displayedServices {
    final list = _searchQuery.trim().isNotEmpty ? _allServices : _services;
    final filteredByLocation = list.where((s) => s['is_available'] == true || (s['available_pros_count'] != null && (s['available_pros_count'] as num) > 0)).toList();
    final finalList = filteredByLocation.isNotEmpty ? filteredByLocation : list;

    if (_searchQuery.trim().isEmpty) return finalList;
    final q = _searchQuery.toLowerCase();
    return finalList.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final desc = (s['description'] ?? '').toString().toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  void _openBooking(Map<String, dynamic> service) {
    final isAvailable = service['is_available'] ?? true;
    final prosCount = (service['available_pros_count'] as num?)?.toInt() ?? 1;

    if (!isAvailable || prosCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No verified professionals available within 50km radius for this service right now.'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
      return;
    }

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
            // Interactive Location Bar Header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: GestureDetector(
                onTap: _openLocationPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.emergencyRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SERVICE LOCATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8)),
                            const SizedBox(height: 2),
                            Text(
                              _activeAddress,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                        onPressed: () async {
                          await _loadCategories();
                          await _loadAllServices();
                          if (_selectedCategoryId != null) await _selectCategory(_selectedCategoryId!);
                        },
                        tooltip: 'Refresh Services',
                      ),
                    ],
                  ),
                ),
              ),
            ),

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
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.76,
              ),
              itemCount: _displayedServices.length,
              itemBuilder: (_, i) {
                final svc = _displayedServices[i];
                final rawImg = svc['image_url']?.toString();
                final imgUrl = (rawImg != null && rawImg.isNotEmpty)
                    ? (rawImg.startsWith('http') ? rawImg : '${ApiClient.baseUrl}$rawImg')
                    : null;
                final duration = svc['duration_minutes']?.toString() ?? '60';

                return GestureDetector(
                  onTap: () => _openBooking(svc),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top 1:1 AspectRatio Image Container (Blinkit Square Style)
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                color: const Color(0xFF1E293B),
                                width: double.infinity,
                                height: double.infinity,
                                child: imgUrl != null
                                    ? Image.network(
                                        imgUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Center(
                                          child: Icon(Icons.build_rounded, color: AppColors.primary, size: 36),
                                        ),
                                        loadingBuilder: (_, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                            ),
                                          );
                                        },
                                      )
                                    : const Center(
                                        child: Icon(Icons.build_rounded, color: AppColors.primary, size: 36),
                                      ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(160),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${duration}m',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bottom Content
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                svc['name']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13, height: 1.2),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${svc['base_price']}',
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.successGreen.withAlpha(30),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.successGreen, width: 1.5),
                                    ),
                                    child: const Text(
                                      'ADD +',
                                      style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
}


