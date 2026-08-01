import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';
import '../location/location_picker_modal.dart';
import '../tracking/tracking_screen.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool femaleProPreferred;

  const BookingScreen({
    super.key,
    required this.service,
    this.femaleProPreferred = false,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late final TextEditingController _addressController = TextEditingController(text: SessionStorage.activeAddress);
  late double _lat = SessionStorage.activeLat;
  late double _lng = SessionStorage.activeLng;
  bool _femaleProPreferred = false;
  bool _isBooking = false;
  bool _fetchingLocation = false;
  bool _checkingAvailability = false;
  bool _hasAvailablePros = true;
  GoogleMapController? _mapController;

  // Update 3: Professional selection
  List<Map<String, dynamic>> _availablePros = [];
  String? _selectedProId;
  String _sortBy = 'distance';
  bool _loadingPros = false;

  // Update 1: Charge breakdown
  double? _distanceKm;
  double? _travelCharge;
  double? _basePrice;
  double? _totalAmount;
  double? _kmCharge;

  @override
  void initState() {
    super.initState();
    _femaleProPreferred = widget.femaleProPreferred;
    _basePrice = double.tryParse(widget.service['base_price']?.toString() ?? '0');
    _loadProsForLocation();
    _useLiveLocation(silent: true);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _showLocationServiceDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Text('Turn On Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Location services (GPS) are turned off on your device. Please turn on location to discover nearby professionals and check service availability in your area.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Turn On GPS', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openLocationSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showPermissionSettingsDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Location Permission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Location permission is permanently denied. Please enable location permission in app settings to proceed with booking.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  void _openLocationPickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPickerModal(
        initialAddress: _addressController.text,
        initialLat: _lat,
        initialLng: _lng,
        onLocationSelected: (address, lat, lng) {
          setState(() {
            _lat = lat;
            _lng = lng;
            _addressController.text = address;
          });
          SessionStorage.setLocation(address, lat, lng);
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15));
          _loadProsForLocation();
        },
      ),
    );
  }

  // Update 7: Real GPS using geolocator with Location Services check
  Future<void> _useLiveLocation({bool silent = false}) async {
    if (!silent) setState(() => _fetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _fetchingLocation = false);
        if (!silent) {
          await _showLocationServiceDialog();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _fetchingLocation = false);
        if (!silent) {
          await _showPermissionSettingsDialog();
        }
        return;
      }
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _fetchingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted) {
        final latLng = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _addressController.text = 'Live GPS: (${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})';
          _fetchingLocation = false;
        });
        SessionStorage.setLocation(_addressController.text, pos.latitude, pos.longitude);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        await _loadProsForLocation();
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📍 Live GPS location captured'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _fetchingLocation = false);
        if (!silent) {
          if (e is LocationServiceDisabledException) {
            await _showLocationServiceDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not get GPS location: ${e.toString()}')),
            );
          }
        }
      }
    }
  }

  void _onMapTapped(LatLng pos) {
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _addressController.text = 'Selected: (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    _loadProsForLocation();
  }

  // Update 3 & 6: Load available professionals for this service and location
  Future<void> _loadProsForLocation() async {
    setState(() { _loadingPros = true; _checkingAvailability = true; });
    try {
      final serviceId = widget.service['id']?.toString() ?? '';
      final pros = await ApiClient.getProsForService(
        serviceId: serviceId,
        lat: _lat,
        lng: _lng,
        femaleOnly: _femaleProPreferred,
        sortBy: _sortBy,
      );
      if (mounted) {
        setState(() {
          _availablePros = pros.map((p) => Map<String, dynamic>.from(p)).toList();
          _hasAvailablePros = _availablePros.isNotEmpty;
          _loadingPros = false;
          _checkingAvailability = false;
          // Auto-select first pro if none selected
          if (_selectedProId == null && _availablePros.isNotEmpty) {
            _selectedProId = _availablePros.first['proId']?.toString();
            _updateEstimate();
          } else if (_availablePros.isEmpty) {
            _selectedProId = null;
            _distanceKm = null; _travelCharge = null; _totalAmount = null;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loadingPros = false; _checkingAvailability = false; });
    }
  }

  // Update 1: Update charge estimate when pro is selected
  void _updateEstimate() {
    if (_selectedProId == null) return;
    try {
      final pro = _availablePros.firstWhere((p) => p['proId']?.toString() == _selectedProId);
      setState(() {
        _distanceKm = (pro['distanceKm'] as num?)?.toDouble();
        _travelCharge = (pro['travelCharge'] as num?)?.toDouble();
        _basePrice = (pro['serviceBasePrice'] as num?)?.toDouble() ?? double.tryParse(widget.service['base_price']?.toString() ?? '0');
        _totalAmount = (pro['estimatedTotal'] as num?)?.toDouble();
        _kmCharge = (pro['kmCharge'] as num?)?.toDouble();
      });
    } catch (_) {}
  }

  Future<void> _confirmBooking() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service location')));
      return;
    }
    if (!_hasAvailablePros) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No professionals available in your area'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isBooking = true);
    try {
      final res = await ApiClient.createBooking(
        serviceId: widget.service['id']?.toString() ?? '',
        scheduledAt: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        addressText: _addressController.text.trim(),
        latitude: _lat,
        longitude: _lng,
        femaleProPreferred: _femaleProPreferred,
        selectedProId: _selectedProId,
      );
      final booking = res['data'] ?? res;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrackingScreen(
            bookingId: booking['id']?.toString() ?? 'bk-9921',
            serviceName: widget.service['name']?.toString() ?? 'Service',
            status: booking['status']?.toString() ?? 'REQUESTED',
            startOtp: booking['start_otp']?.toString() ?? '4920',
            endOtp: booking['end_otp']?.toString() ?? '8103',
            totalAmount: booking['total_amount']?.toString() ?? _totalAmount?.toString() ?? widget.service['base_price']?.toString() ?? '499',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.service['name']?.toString() ?? 'Service';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Book Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProsForLocation,
            tooltip: 'Refresh Professionals & Pricing',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProsForLocation,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Service Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.service['icon']?.toString() ?? '🔧', style: const TextStyle(fontSize: 32)),
                      const Spacer(),
                      if (_distanceKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                          child: Text('${_distanceKm!.toStringAsFixed(1)} km · ₹${_kmCharge?.toStringAsFixed(0) ?? '15'}/km',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                          child: const Text('Travel charge varies by pro', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(name, style: AppText.heading2),
                  const SizedBox(height: 8),

                  // Update 1: Dynamic charge breakdown
                  if (_totalAmount != null) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.successGreen.withAlpha(60)),
                      ),
                      child: Column(
                        children: [
                          _chargeRow('Professional Fee', '₹${_basePrice?.toStringAsFixed(0) ?? '0'}', Colors.white),
                          const SizedBox(height: 4),
                          _chargeRow('Travel Fee (${_distanceKm?.toStringAsFixed(1) ?? '0'} km)', '₹${_travelCharge?.toStringAsFixed(0) ?? '0'}', AppColors.textMuted),
                          const SizedBox(height: 4),
                          _chargeRow('Platform Fee (Service Platform Fee)', '₹50', AppColors.warningAmber),
                          const Divider(color: AppColors.border, height: 16),
                          _chargeRow('Total', '₹${((_totalAmount ?? 0) + 50).toStringAsFixed(0)}', AppColors.successGreen, bold: true),
                        ],
                      ),
                    ),
                  ] else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Base Fee: ₹${widget.service['base_price'] ?? '0'}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        const Text('+ Travel Fee', style: TextStyle(fontSize: 12, color: AppColors.successGreen, fontWeight: FontWeight.w700)),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SERVICE LOCATION', style: AppText.label),
                TextButton.icon(
                  onPressed: _fetchingLocation ? null : () => _useLiveLocation(),
                  icon: _fetchingLocation
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : const Icon(Icons.my_location, size: 16, color: AppColors.primary),
                  label: const Text('Live GPS', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: lumoInputDecoration(hint: 'Enter or tap map to set location', prefix: const Icon(Icons.location_on, color: AppColors.emergencyRed, size: 20)),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: LatLng(_lat, _lng), zoom: 13),
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  onTap: _onMapTapped,
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected_point'),
                      position: LatLng(_lat, _lng),
                      infoWindow: const InfoWindow(title: 'Service Location'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Update 3: Professional Picker
            _buildProPicker(),
            const SizedBox(height: 16),

            // Female Pro Preference toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Female Professional Only', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                  Switch(
                    value: _femaleProPreferred,
                    activeTrackColor: const Color(0xFFEC4899),
                    activeThumbColor: Colors.white,
                    onChanged: (v) {
                      setState(() { _femaleProPreferred = v; _selectedProId = null; });
                      _loadProsForLocation();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: (_isBooking || !_hasAvailablePros || _checkingAvailability || _loadingPros) ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasAvailablePros ? AppColors.successGreen : Colors.grey.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isBooking || _checkingAvailability
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        _hasAvailablePros
                            ? (_totalAmount != null ? 'CONFIRM BOOKING · ₹${_totalAmount!.toStringAsFixed(0)}' : 'CONFIRM BOOKING')
                            : 'NO PROFESSIONALS IN YOUR AREA',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.8,
                          color: _hasAvailablePros ? Colors.white : AppColors.textMuted,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // Update 3: Professional picker section
  Widget _buildProPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + Sort filters
        Row(
          children: [
            const Text('CHOOSE PROFESSIONAL', style: AppText.label),
            const Spacer(),
            if (_loadingPros) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        // Sort filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('Nearest', 'distance'),
              const SizedBox(width: 8),
              _filterChip('Top Rated', 'rating'),
              const SizedBox(width: 8),
              _filterChip('Lowest Price', 'price'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // No pros banner with interactive options
        if (!_hasAvailablePros && !_loadingPros)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.emergencyRed.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.emergencyRed.withAlpha(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_off_outlined, color: AppColors.emergencyRed, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No Professionals Available Nearby', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('No approved professionals are currently active in your area for this service.', style: TextStyle(color: AppColors.emergencyRed, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.my_location, size: 14),
                        label: const Text('Turn On GPS / Retry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _useLiveLocation(silent: false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.map_outlined, size: 14),
                        label: const Text('Pick Location', style: TextStyle(fontSize: 11)),
                        onPressed: _openLocationPickerModal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )

        // Pro cards
        else if (_availablePros.isNotEmpty)
          SizedBox(
            height: 154,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availablePros.length,
              itemBuilder: (ctx, i) {
                final pro = _availablePros[i];
                final proId = pro['proId']?.toString();
                final isSelected = _selectedProId == proId;
                final isFemale = (pro['gender']?.toString() ?? '').toUpperCase() == 'FEMALE';
                final isVerified = pro['isVerified'] == true || pro['verificationStatus'] == 'APPROVED';
                final rawAvatar = pro['avatarUrl']?.toString();
                final imgUrl = (rawAvatar != null && rawAvatar.isNotEmpty)
                    ? (rawAvatar.startsWith('http') ? rawAvatar : '${ApiClient.baseUrl}$rawAvatar')
                    : null;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedProId = proId);
                    _updateEstimate();
                  },
                  onLongPress: () => _showProProfileModal(pro),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 145,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primarySoft : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isFemale ? const Color(0x33EC4899) : AppColors.primarySoft,
                                  backgroundImage: imgUrl != null ? NetworkImage(imgUrl) : null,
                                  child: imgUrl == null ? Text(isFemale ? '👩' : '👨', style: const TextStyle(fontSize: 16)) : null,
                                ),
                                if (isVerified)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: const BoxDecoration(color: AppColors.cardBg, shape: BoxShape.circle),
                                      child: const Icon(Icons.verified, color: AppColors.primary, size: 12),
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 16),
                              tooltip: 'View Profile',
                              onPressed: () => _showProProfileModal(pro),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                pro['name']?.toString() ?? 'Professional',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 3),
                              const Icon(Icons.verified, color: AppColors.primary, size: 12),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
                            const SizedBox(width: 2),
                            Text(
                              ((pro['ratingAvg'] as num?)?.toDouble() ?? 5.0).toStringAsFixed(1),
                              style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${pro['totalJobsCompleted'] ?? 0})',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${((pro['distanceKm'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} km away',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        ),
                        const Spacer(),
                        Text(
                          '≈ ₹${((pro['estimatedTotal'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )

        else if (_loadingPros)
          const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
      ],
    );
  }

  void _showProProfileModal(Map<String, dynamic> pro) {
    final proId = pro['proId']?.toString();
    final name = pro['name']?.toString() ?? 'Professional';
    final rawAvatar = pro['avatarUrl']?.toString();
    final imgUrl = (rawAvatar != null && rawAvatar.isNotEmpty)
        ? (rawAvatar.startsWith('http') ? rawAvatar : '${ApiClient.baseUrl}$rawAvatar')
        : null;
    final isFemale = (pro['gender']?.toString() ?? '').toUpperCase() == 'FEMALE';
    final isVerified = pro['isVerified'] == true || pro['verificationStatus'] == 'APPROVED';
    final ratingAvg = (pro['ratingAvg'] as num?)?.toDouble() ?? 5.0;
    final jobsCount = pro['totalJobsCompleted'] ?? 0;
    final distance = (pro['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final estTotal = (pro['estimatedTotal'] as num?)?.toDouble() ?? 0.0;
    final basePrice = (pro['serviceBasePrice'] as num?)?.toDouble() ?? 0.0;
    final travelCharge = (pro['travelCharge'] as num?)?.toDouble() ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.glassBorderBright, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: isFemale ? const Color(0x33EC4899) : AppColors.primarySoft,
                      backgroundImage: imgUrl != null ? NetworkImage(imgUrl) : null,
                      child: imgUrl == null ? Text(isFemale ? '👩' : '👨', style: const TextStyle(fontSize: 28)) : null,
                    ),
                    if (isVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                          child: const Icon(Icons.verified, color: AppColors.primary, size: 18),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AppColors.primary, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isFemale ? const Color(0x33EC4899) : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isFemale ? '👩 Female Professional' : '👨 LUMO Verified Pro',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isFemale ? const Color(0xFFF472B6) : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                            SizedBox(width: 4),
                            Text('RATING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ratingAvg.toStringAsFixed(1)} ★',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.work_history, color: AppColors.primary, size: 16),
                            SizedBox(width: 4),
                            Text('JOBS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$jobsCount Done',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.near_me, color: AppColors.successGreen, size: 16),
                            SizedBox(width: 4),
                            Text('DISTANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.successGreen),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.successGreenSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.successGreen.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: AppColors.successGreen, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Identity, Face Verification & Police Background Check Completed.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.successGreen),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  _chargeRow('Base Service Rate', '₹${basePrice.toStringAsFixed(0)}', Colors.white),
                  const SizedBox(height: 6),
                  _chargeRow('Travel Charge (${distance.toStringAsFixed(1)} km)', '₹${travelCharge.toStringAsFixed(0)}', AppColors.primary),
                  const Divider(color: AppColors.border, height: 16),
                  _chargeRow('Estimated Total', '₹${estTotal.toStringAsFixed(0)}', AppColors.successGreen, bold: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('SELECT THIS PROFESSIONAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedProId = proId);
                  _updateEstimate();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isActive = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() { _sortBy = value; _selectedProId = null; });
        _loadProsForLocation();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
          boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isActive ? const Color(0xFF0F172A) : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _chargeRow(String label, String value, Color valueColor, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 12, color: valueColor, fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
      ],
    );
  }
}
