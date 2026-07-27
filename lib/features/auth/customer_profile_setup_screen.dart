import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/theme/app_theme.dart';
import '../location/location_picker_modal.dart';

class CustomerProfileSetupScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const CustomerProfileSetupScreen({super.key, required this.onCompleted});

  @override
  State<CustomerProfileSetupScreen> createState() => _CustomerProfileSetupScreenState();
}

class _CustomerProfileSetupScreenState extends State<CustomerProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _selectedSex = 'MALE';
  String _address = 'Kochi, Kerala, India';
  double _lat = 9.9312;
  double _lng = 76.2673;
  bool _isLoading = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _sexOptions = [
    {'value': 'MALE', 'label': 'Male', 'icon': Icons.male_rounded, 'color': const Color(0xFF3B82F6)},
    {'value': 'FEMALE', 'label': 'Female', 'icon': Icons.female_rounded, 'color': const Color(0xFFEC4899)},
    {'value': 'OTHER', 'label': 'Other', 'icon': Icons.person_outline_rounded, 'color': const Color(0xFF8B5CF6)},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final age = int.tryParse(_ageCtrl.text.trim());
    final email = _emailCtrl.text.trim();

    if (name.isEmpty) { setState(() => _error = 'Please enter your name'); return; }
    if (age == null || age < 10 || age > 100) { setState(() => _error = 'Please enter a valid age'); return; }
    if (email.isNotEmpty && !RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email'); return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      // Call backend to store profile
      await ApiClient.completeProfile(name: name, age: age, sex: _selectedSex, email: email.isEmpty ? null : email);
    } catch (_) {
      // Store locally even if backend call fails
    }

    await SessionStorage.completeProfile(
      name: name,
      age: age,
      sex: _selectedSex,
      email: email.isEmpty ? null : email,
    );

    await SessionStorage.setLocation(_address, _lat, _lng);

    if (mounted) widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background blobs
          Positioned(top: -100, right: -80, child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.primary.withAlpha(35), Colors.transparent])),
          )),
          Positioned(bottom: 60, left: -100, child: Container(
            width: 250, height: 250,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.secondary.withAlpha(25), Colors.transparent])),
          )),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Header
                    Center(
                      child: Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(80), blurRadius: 30, offset: const Offset(0, 12))],
                        ),
                        child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Complete Your Profile', textAlign: TextAlign.center, style: AppText.heading1),
                    const SizedBox(height: 6),
                    const Text('Just a few details so we can personalize your experience and ensure your safety.', textAlign: TextAlign.center, style: AppText.caption),
                    const SizedBox(height: 32),

                    if (_error != null) Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.emergencyRedSoft, border: Border.all(color: AppColors.emergencyRedBorder), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.emergencyRed, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.emergencyRed, fontSize: 13))),
                        ],
                      ),
                    ),

                    AppGlassCard(
                      borderRadius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('YOUR NAME *', style: AppText.label),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                            decoration: lumoInputDecoration(
                              hint: 'Full Name',
                              prefix: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('AGE *', style: AppText.label),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _ageCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                maxLength: 3,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                                decoration: lumoInputDecoration(hint: '25').copyWith(counterText: ''),
                              ),
                            ])),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('EMAIL', style: AppText.label),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                decoration: lumoInputDecoration(hint: 'Optional'),
                              ),
                            ])),
                          ]),
                          const SizedBox(height: 16),

                          const Text('GENDER', style: AppText.label),
                          const SizedBox(height: 8),
                          Row(children: _sexOptions.map((g) {
                            final selected = _selectedSex == g['value'];
                            final color = g['color'] as Color;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedSex = g['value']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: selected ? color.withAlpha(30) : const Color(0x0AFFFFFF),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: selected ? color : AppColors.glassBorder, width: selected ? 1.5 : 1),
                                  ),
                                  child: Column(children: [
                                    Icon(g['icon'] as IconData, color: selected ? color : AppColors.textMuted, size: 20),
                                    const SizedBox(height: 4),
                                    Text(g['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? color : AppColors.textMuted)),
                                  ]),
                                ),
                              ),
                            );
                          }).toList()),
                          const SizedBox(height: 16),
                          const Text('DEFAULT HOME SERVICE LOCATION *', style: AppText.label),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => LocationPickerModal(
                                  initialAddress: _address,
                                  initialLat: _lat,
                                  initialLng: _lng,
                                  onLocationSelected: (addr, lat, lng) {
                                    setState(() {
                                      _address = addr;
                                      _lat = lat;
                                      _lng = lng;
                                    });
                                  },
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withAlpha(80))),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, color: AppColors.emergencyRed, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(_address, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  const Icon(Icons.edit_location_alt_rounded, color: AppColors.primary, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    AppGradientButton(
                      label: 'GET STARTED',
                      onTap: _save,
                      isLoading: _isLoading,
                      icon: Icons.arrow_forward_rounded,
                    ),

                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        await SessionStorage.completeProfile(name: 'Customer', age: 0, sex: 'PREFER_NOT_TO_SAY');
                        if (mounted) widget.onCompleted();
                      },
                      child: const Text('Skip for now', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
