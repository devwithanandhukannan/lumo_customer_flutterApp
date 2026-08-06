import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';
import '../booking/booking_screen.dart';
import '../location/location_picker_modal.dart';
import 'widgets/service_card_horizontal.dart';

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
  bool _femaleProPreferred = false;
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
      locationName: _activeAddress,
    );
    if (mounted) {
      setState(() => _activeSuspension = suspension);
    }
  }

  String _formatExpiry(dynamic expiresAt) {
    if (expiresAt == null || expiresAt.toString().isEmpty) {
      return 'Indefinite (Until further notice)';
    }
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
        if (cats.isNotEmpty && _selectedCategoryId == null) {
          _selectCategory(cats[0]['id']?.toString() ?? '');
        }
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
      final svcs = await ApiClient.getServices(
        categoryId: categoryId.isEmpty ? null : categoryId,
        latitude: _activeLat,
        longitude: _activeLng,
      );
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

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('all')) return Icons.grid_view_rounded;
    if (name.contains('electric')) return Icons.electrical_services_rounded;
    if (name.contains('clean')) return Icons.cleaning_services_rounded;
    if (name.contains('plumb')) return Icons.plumbing_rounded;
    if (name.contains('ac') || name.contains('appliance')) return Icons.ac_unit_rounded;
    if (name.contains('beauty') || name.contains('salon')) return Icons.face_retouching_natural_rounded;
    if (name.contains('security') || name.contains('safe')) return Icons.shield_rounded;
    if (name.contains('paint')) return Icons.format_paint_rounded;
    if (name.contains('carpenter')) return Icons.carpenter_rounded;
    return Icons.build_rounded;
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
          content: Text('No verified professionals available within 50km radius for this service right now.'),
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
        await _loadAllServices();
        await _checkSuspension();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top SLA Arrival & Location Header
                    _buildTopHeader(),

                    // Emergency Suspension Alert (if active)
                    if (_activeSuspension != null) _buildSuspensionBanner(),

                    // Search Bar
                    _buildSearchBar(),

                    const SizedBox(height: 14),

                    // Horizontal Icon-based Category Filter Tabs
                    _buildCategoryFilterTabs(),

                    const SizedBox(height: 18),

                    // Services Listing Header
                    _buildSectionHeader(
                      title: _searchQuery.isNotEmpty
                          ? 'Search Results (${_displayedServices.length})'
                          : 'Available Services',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'Services matching "$_searchQuery"'
                          : 'Select a service to book verified pros',
                      icon: Icons.home_repair_service_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Main Services Grid
                    _buildServicesGrid(),

                    // Bottom Padding to clear floating hover SOS button
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Location Header with Women Safety Toggle
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AppGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: 16,
        child: Row(
          children: [
            // Location Picker Button
            Expanded(
              child: GestureDetector(
                onTap: _openLocationPicker,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRedSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.emergencyRed, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LOCATION', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.primaryLight, letterSpacing: 0.8)),
                          const SizedBox(height: 1),
                          Text(
                            _activeAddress,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Women Safety Toggle Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _femaleProPreferred ? AppColors.successGreenSoft : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _femaleProPreferred ? AppColors.successGreen.withAlpha(120) : AppColors.glassBorder,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: _femaleProPreferred ? AppColors.successGreen : AppColors.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'SAFE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: _femaleProPreferred ? AppColors.successGreen : AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: _femaleProPreferred,
                      activeTrackColor: AppColors.successGreen,
                      activeThumbColor: const Color(0xFF0F172A),
                      inactiveTrackColor: Colors.black38,
                      inactiveThumbColor: AppColors.textMuted,
                      onChanged: (v) {
                        setState(() => _femaleProPreferred = v);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  v ? Icons.verified_user_rounded : Icons.info_outline_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    v
                                        ? 'Female Pro Preferred mode ON (Women Safety)'
                                        : 'Female Pro Preferred mode OFF',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: v ? AppColors.successGreen : AppColors.surface,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Emergency Suspension Banner
  Widget _buildSuspensionBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: AppGlassCard(
        padding: const EdgeInsets.all(14),
        gradientColors: const [Color(0x33EF4444), Color(0x10EF4444)],
        borderColor: AppColors.emergencyRedBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                const SizedBox(width: 10),
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
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Colors.amberAccent, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Resumption: ${_formatExpiry(_activeSuspension!['expiresAt'])}',
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
    );
  }

  // 3. Search Bar
  Widget _buildSearchBar() {
    return Container(
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
              : const Icon(Icons.mic_none_rounded, color: AppColors.textMuted, size: 20),
        ),
      ),
    );
  }

  // 4. Horizontal Icon-based Category Filter Bar
  Widget _buildCategoryFilterTabs() {
    if (_loadingCategories) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      );
    }

    final allCategories = [
      {'id': '', 'name': 'All Services'},
      ..._categories,
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = allCategories[i];
          final catId = cat['id']?.toString() ?? '';
          final catName = cat['name']?.toString() ?? '';
          final isSelected = (_selectedCategoryId ?? '') == catId;
          final catIcon = _getCategoryIcon(catName);

          return GestureDetector(
            onTap: () => _selectCategory(catId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primaryLight : AppColors.glassBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    catIcon,
                    size: 16,
                    color: isSelected ? const Color(0xFF0F172A) : AppColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    catName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Section Header Widget
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Main Grid of Services
  Widget _buildServicesGrid() {
    if (_loadingServices) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_displayedServices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 36),
              SizedBox(height: 8),
              Text('No services found in this category.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.74,
        ),
        itemCount: _displayedServices.length,
        itemBuilder: (_, i) {
          final svc = _displayedServices[i];
          return ServiceCardHorizontal(
            service: svc,
            isSuspended: _activeSuspension != null,
            onTap: () => _openBooking(svc),
          );
        },
      ),
    );
  }
}
