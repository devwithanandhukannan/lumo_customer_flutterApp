import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';

class LocationPickerModal extends StatefulWidget {
  final String initialAddress;
  final double initialLat;
  final double initialLng;
  final Function(String address, double lat, double lng) onLocationSelected;

  const LocationPickerModal({
    super.key,
    required this.initialAddress,
    required this.initialLat,
    required this.initialLng,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  GoogleMapController? _mapController;

  late double _selectedLat;
  late double _selectedLng;
  late String _selectedAddress;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLat;
    _selectedLng = widget.initialLng;
    _selectedAddress = widget.initialAddress;
    _searchCtrl.text = widget.initialAddress;
    _fetchLiveGpsLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
          'Location services (GPS) are turned off on your device. Please turn on location to pick your live GPS address.',
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

  Future<void> _fetchLiveGpsLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locating = false);
        await _showLocationServiceDialog();
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mounted) {
          setState(() {
            _selectedLat = pos.latitude;
            _selectedLng = pos.longitude;
            _selectedAddress = 'Live GPS Point (${pos.latitude.toStringAsFixed(4)}° N, ${pos.longitude.toStringAsFixed(4)}° E)';
            _searchCtrl.text = _selectedAddress;
            _locating = false;
          });
          _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
        }
        return;
      }
    } catch (e) {
      if (e is LocationServiceDisabledException) {
        await _showLocationServiceDialog();
      }
    }
    if (mounted) setState(() => _locating = false);
  }

  void _onMapTapped(LatLng pos) {
    setState(() {
      _selectedLat = pos.latitude;
      _selectedLng = pos.longitude;
      _selectedAddress = 'Selected Address (${pos.latitude.toStringAsFixed(4)}° N, ${pos.longitude.toStringAsFixed(4)}° E)';
      _searchCtrl.text = _selectedAddress;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                const Text('Select Service Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Quick Use Live Location Pill
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _locating ? null : _fetchLiveGpsLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _locating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.my_location, size: 18, color: AppColors.primary),
                    label: const Text('Use My Current GPS Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 12),
                // Search Input Field
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) => _selectedAddress = val,
                  decoration: lumoInputDecoration(
                    hint: 'Search & Pick Address on Map',
                    prefix: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Interactive Google Map
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_selectedLat, _selectedLng),
                    zoom: 14,
                  ),
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  onTap: _onMapTapped,
                  markers: {
                    Marker(
                      markerId: const MarkerId('picked_location'),
                      position: LatLng(_selectedLat, _selectedLng),
                      infoWindow: InfoWindow(title: 'Service Point', snippet: _selectedAddress),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
          ),

          // Confirm Location Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onLocationSelected(_selectedAddress, _selectedLat, _selectedLng);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('CONFIRM SERVICE LOCATION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
