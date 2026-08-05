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
  Map<String, dynamic>? _activeSuspension;

  @override
  void initState() {
    super.initState();
    _activeAddress = SessionStorage.activeAddress;
    _activeLat = SessionStorage.activeLat;
    _activeLng = SessionStorage.activeLng;
    _loadCategories();
    _loadAllServices();
    _checkSuspension();
    final customerSex = SessionStorage.sex.toUpperCase();
    _femaleProPreferred = (customerSex == 'FEMALE');
  }

  Future<void> _checkSuspension() async {
    final suspension = await ApiClient.checkServiceSuspension(
      latitude: _activeLat,
      longitude: _activeLng,
    );
    if (mounted) {
      setState(() => _activeSuspension = suspension);
    }
  }

  String _formatExpiry(dynamic expiresAt) {
    if (expiresAt == null || expiresAt.toString().isEmpty) return 'Indefinite (Until further notice)';
    try {
      final dt = DateTime.parse(expiresAt.toString()).toLocal();
      final hourStr = dt.hour > 12 ? (dt.hour - 12) : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day}/${dt.month}/${dt.year} at $hourStr:${dt.minute.toString().padLeft(2, '0')} $amPm';
    } catch (_) {
      return expiresAt.toString();
    }
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
            _checkSuspension();
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
    if (_activeSuspension != null && _activeSuspension!['severity'] == 'FULL_BLACKOUT') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Service Temporarily Closed',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            _activeSuspension!['message'] ?? 'Service is currently paused in your area due to emergency conditions.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Understand', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

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
        await _checkSuspension();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Interactive Location Bar Header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: AppGlassCard(
                onTap: _openLocationPicker,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                borderRadius: 18,
                borderColor: AppColors.glassBorderBright,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRedSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.emergencyRed, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SERVICE LOCATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primaryLight, letterSpacing: 0.8)),
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
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
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

            if (_activeSuspension != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: AppGlassCard(
                  padding: const EdgeInsets.all(14),
                  gradientColors: const [Color(0x33EF4444), Color(0x10EF4444)],
                  borderColor: AppColors.emergencyRedBorder,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activeSuspension!['title'] ?? 'Emergency Service Closure',
                                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _activeSuspension!['message'] ?? 'Service paused in this region.',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFF34D399), size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Location: ${_activeSuspension!['areaName'] ?? 'Fenced Area'}',
                                style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: Colors.amberAccent, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Service Resumption: ${_formatExpiry(_activeSuspension!['expiresAt'])}',
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                decoration: lumoInputDecoration(
                  hint: 'Search home services (e.g. Plumbing, Cleaning)',
                  prefix: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                  suffix: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Safety preference
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: AppGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: 18,
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Female Pro Preferred', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13)),
                              const Spacer(),
                              Switch(
                                value: _femaleProPreferred,
                                activeTrackColor: AppColors.primary,
                                activeThumbColor: const Color(0xFF0F172A),
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
                      return AppGlassChip(
                        label: cat['name']?.toString() ?? '',
                        isSelected: isSelected,
                        onTap: () => _selectCategory(cat['id']?.toString() ?? ''),
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

                    return AppGlassCard(
                      padding: EdgeInsets.zero,
                      borderRadius: 18,
                      onTap: () => _openBooking(svc),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(180),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.glassBorder),
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
                                        color: AppColors.primarySoft,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.primary, width: 1.2),
                                      ),
                                      child: const Text(
                                        'BOOK',
                                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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


