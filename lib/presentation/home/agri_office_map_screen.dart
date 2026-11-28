import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/auth_service.dart';
import '../../global_popup/global_popup.dart';
import '../../providers/auth_provider.dart';
import '../../services/bd_geo_api_service.dart';

/// কৃষি অফিস – Bangladesh Verified Agriculture Office Interactive Map Screen
class AgriOfficeMapScreen extends StatefulWidget {
  const AgriOfficeMapScreen({super.key});

  @override
  State<AgriOfficeMapScreen> createState() => _AgriOfficeMapScreenState();
}

class _AgriOfficeMapScreenState extends State<AgriOfficeMapScreen> {
  final MapController _mapController = MapController();

  List<BdGeoItem> _divisions = [];
  List<BdGeoItem> _districts = [];
  List<BdGeoItem> _upazilas = [];

  String? _selectedDivisionId;
  String? _selectedDistrictId;
  String _selectedUpazilaId = 'all';

  bool _isLoadingGeo = true;
  String? _geoError;

  LatLng? _userLatLng;
  double _currentZoom = 7.0;

  // Cached Firestore Stream (updated ONLY when _selectedDistrictId changes)
  Stream<QuerySnapshot<Map<String, dynamic>>>? _officesStream;

  @override
  void initState() {
    super.initState();
    _initGeoAndProfile();
  }

  Future<void> _initGeoAndProfile({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _isLoadingGeo = true;
        _geoError = null;
      });
    }

    try {
      final results = await Future.wait([
        BdGeoApiService.getDivisions(forceRefresh: forceRefresh),
        BdGeoApiService.getAllDistricts(forceRefresh: forceRefresh),
      ]);

      final divs = results[0];
      final allDists = results[1];

      // Auto-detect user's profile district & upazila
      String? profDist;
      String? profUpa;
      try {
        final authProv = Provider.of<AuthProvider>(context, listen: false);
        var user = authProv.user;
        if (user == null || user.uid.startsWith('guest_')) {
          user = await AuthService().loadCachedUser();
        }
        if (user != null) {
          profDist = user.district;
          profUpa = user.upazila;
        } else {
          final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
          if (fbUser != null && !fbUser.isAnonymous) {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(fbUser.uid)
                .get();
            if (doc.exists && doc.data() != null) {
              profDist = doc.data()!['district']?.toString();
              profUpa = doc.data()!['upazila']?.toString();
            }
          }
        }
      } catch (_) {}

      BdGeoItem? matchedDist;
      if (profDist != null && profDist.trim().isNotEmpty) {
        matchedDist = await BdGeoApiService.findDistrictByName(profDist);
      }
      matchedDist ??= allDists.firstWhere(
        (d) => d.name.toLowerCase() == 'dhaka',
        orElse: () => allDists.isNotEmpty
            ? allDists.first
            : const BdGeoItem(id: '1', name: 'Dhaka', bnName: 'ঢাকা'),
      );

      final upas = await BdGeoApiService.getUpazilasByDistrict(
        matchedDist.id,
        forceRefresh: forceRefresh,
      );

      String matchedUpaId = 'all';
      if (profUpa != null && profUpa.trim().isNotEmpty) {
        final foundUpa =
            await BdGeoApiService.findUpazilaByName(matchedDist.id, profUpa);
        if (foundUpa != null) matchedUpaId = foundUpa.id;
      }

      if (!mounted) return;
      setState(() {
        _divisions = divs;
        _districts = allDists;
        _upazilas = upas;
        _selectedDistrictId = matchedDist!.id;
        _selectedUpazilaId = matchedUpaId;
        _isLoadingGeo = false;
        _updateDistrictStream(matchedDist.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingGeo = false;
        _geoError = e.toString().replaceFirst('Exception: ', '');
      });
      GlobalPopup.showNotice(
        context,
        title: 'নেটওয়ার্ক ত্রুটি',
        message: _geoError ?? 'জিও ডেটা লোড করা যায়নি।',
      );
    }
  }

  void _updateDistrictStream(String districtId) {
    _officesStream = FirebaseFirestore.instance
        .collection('agriculture_offices')
        .where('districtId', isEqualTo: districtId)
        .limit(50)
        .snapshots();
  }

  Future<void> _onDivisionChanged(String? divId) async {
    setState(() {
      _selectedDivisionId = divId;
      _selectedUpazilaId = 'all';
    });
    try {
      final dists = (divId == null || divId.isEmpty)
          ? await BdGeoApiService.getAllDistricts()
          : await BdGeoApiService.getDistrictsByDivision(divId);
      if (!mounted) return;
      setState(() {
        _districts = dists;
      });
      if (dists.isNotEmpty) {
        await _onDistrictChanged(dists.first.id);
      }
    } catch (e) {
      if (!mounted) return;
      GlobalPopup.showNotice(
        context,
        title: 'ত্রুটি',
        message: 'জেলা তালিকা লোড করা যায়নি।',
      );
    }
  }

  Future<void> _onDistrictChanged(String? distId) async {
    if (distId == null || distId.isEmpty) return;
    setState(() {
      _selectedDistrictId = distId;
      _selectedUpazilaId = 'all';
      _updateDistrictStream(distId);
    });
    try {
      final upas = await BdGeoApiService.getUpazilasByDistrict(distId);
      if (!mounted) return;
      setState(() => _upazilas = upas);
    } catch (_) {}
  }

  Future<void> _locateCurrentUser() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        await GlobalPopup.showNotice(
          context,
          title: 'GPS বন্ধ আছে',
          message: 'আপনার বর্তমান অবস্থান দেখতে ফোনের লোকেশন (GPS) চালু করুন।',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        await GlobalPopup.showNotice(
          context,
          title: 'লোকেশন অনুমতি প্রয়োজন',
          message:
              'নিকটস্থ কৃষি অফিসের দূরত্ব দেখতে অ্যাপটিকে লোকেশন ব্যবহারের অনুমতি দিন।',
        );
        return;
      }

      if (!mounted) return;
      GlobalPopup.showLoading(context, message: 'আপনার অবস্থান শনাক্ত হচ্ছে...');
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      GlobalPopup.hideLoading(context);

      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLatLng = latLng;
        _currentZoom = 12.5;
      });
      _mapController.move(latLng, 12.5);
    } catch (e) {
      if (mounted) GlobalPopup.hideLoading(context);
      if (!mounted) return;
      GlobalPopup.showNotice(
        context,
        title: 'অবস্থান পাওয়া যায়নি',
        message: 'বর্তমান অবস্থান নির্ণয় করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
      );
    }
  }

  Future<void> _launchPhone(String phone) async {
    final clean = phone.trim();
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      GlobalPopup.showNotice(
        context,
        title: 'কল করা যায়নি',
        message: 'ফোন ডায়ালার চালু করা সম্ভব হয়নি ($clean)।',
      );
    }
  }

  Future<void> _launchDirections(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      GlobalPopup.showNotice(
        context,
        title: 'ম্যাপ খোলা যায়নি',
        message: 'ডিরেকশনের জন্য Google Maps চালু করা সম্ভব হয়নি।',
      );
    }
  }

  void _showOfficeDetailsSheet(Map<String, dynamic> office) {
    final lat = (office['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (office['longitude'] as num?)?.toDouble() ?? 0.0;
    final phone = office['phoneNumber']?.toString() ?? '';
    final officeName = office['officeName']?.toString() ?? 'কৃষি অফিস';
    final officeType = office['officeType']?.toString() ?? 'কৃষি অফিস';
    final fullAddress = office['fullAddress']?.toString() ?? '';
    final upazilaBn = office['upazilaBnName']?.toString() ?? '';
    final districtBn = office['districtBnName']?.toString() ?? '';

    String? distanceText;
    if (_userLatLng != null && lat != 0 && lng != 0) {
      final meters = Geolocator.distanceBetween(
        _userLatLng!.latitude,
        _userLatLng!.longitude,
        lat,
        lng,
      );
      distanceText = '${(meters / 1000).toStringAsFixed(1)} km দূরে';
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              officeName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    officeType,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                if (distanceText != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      distanceText,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0288D1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF2E7D32), size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$fullAddress${upazilaBn.isNotEmpty ? ', $upazilaBn' : ''}${districtBn.isNotEmpty ? ', $districtBn' : ''}',
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF37474F), height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F5E9),
                      foregroundColor: const Color(0xFF1B5E20),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: phone.isEmpty ? null : () => _launchPhone(phone),
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: Text(
                      phone.isEmpty ? 'নম্বর নেই' : phone,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _launchDirections(lat, lng),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text(
                      'Get Directions',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: Column(
        children: [
          _buildTopBar(),
          if (_isLoadingGeo)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              ),
            )
          else if (_geoError != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFE53935)),
                      const SizedBox(height: 12),
                      Text(
                        _geoError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF37474F)),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _initGeoAndProfile(forceRefresh: true),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('পুনরায় চেষ্টা করুন'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _officesStream,
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  final allDistrictOffices = docs
                      .map((d) => {'id': d.id, ...d.data()})
                      .where((o) => o['isActive'] != false)
                      .toList();

                  final filteredOffices = _selectedUpazilaId == 'all'
                      ? allDistrictOffices
                      : allDistrictOffices
                          .where((o) => o['upazilaId']?.toString() == _selectedUpazilaId)
                          .toList();

                  return Column(
                    children: [
                      _buildMapSection(filteredOffices),
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting &&
                                !snapshot.hasData
                            ? const Center(
                                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                              )
                            : _buildOfficesList(filteredOffices),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        bottom: 14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x401B5E20),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
              const Expanded(
                child: Column(
                  children: [
                    Text(
                      'কৃষি অফিস',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'আপনার এলাকার যাচাইকৃত কৃষি অফিসের মানচিত্র',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _initGeoAndProfile(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDropdownChip(
                  value: _selectedDivisionId,
                  hint: 'বিভাগ',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('সকল বিভাগ', overflow: TextOverflow.ellipsis)),
                    ..._divisions.map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.bnName, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: _onDivisionChanged,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildDropdownChip(
                  value: _selectedDistrictId,
                  hint: 'জেলা',
                  items: _districts
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.bnName, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: _onDistrictChanged,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildDropdownChip(
                  value: _selectedUpazilaId,
                  hint: 'উপজেলা',
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('সব উপজেলা', overflow: TextOverflow.ellipsis)),
                    ..._upazilas.map(
                      (u) => DropdownMenuItem(
                        value: u.id,
                        child: Text(u.bnName, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedUpazilaId = val ?? 'all');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownChip({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final hasValue = items.any((item) => item.value == value);
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: hasValue ? value : null,
          hint: Text(hint, style: const TextStyle(fontSize: 11.5, color: Color(0xFF1B5E20))),
          isExpanded: true,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildMapSection(List<Map<String, dynamic>> offices) {
    final markers = <Marker>[];
    LatLng initialCenter = const LatLng(23.685, 90.3563);

    for (final o in offices) {
      final lat = (o['latitude'] as num?)?.toDouble();
      final lng = (o['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        final point = LatLng(lat, lng);
        initialCenter = point;
        markers.add(
          Marker(
            point: point,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showOfficeDetailsSheet(o),
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF1B5E20),
                size: 38,
              ),
            ),
          ),
        );
      }
    }

    if (_userLatLng != null) {
      markers.add(
        Marker(
          point: _userLatLng!,
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0288D1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: markers.isNotEmpty ? 11.0 : 7.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.krishikotha.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                _buildMapFab(
                  icon: Icons.add,
                  onTap: () {
                    _currentZoom = (_currentZoom + 1).clamp(4.0, 18.0);
                    _mapController.move(_mapController.camera.center, _currentZoom);
                  },
                ),
                const SizedBox(height: 6),
                _buildMapFab(
                  icon: Icons.remove,
                  onTap: () {
                    _currentZoom = (_currentZoom - 1).clamp(4.0, 18.0);
                    _mapController.move(_mapController.camera.center, _currentZoom);
                  },
                ),
                const SizedBox(height: 6),
                _buildMapFab(
                  icon: Icons.my_location_rounded,
                  bgColor: const Color(0xFF0288D1),
                  iconColor: Colors.white,
                  onTap: _locateCurrentUser,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFab({
    required IconData icon,
    required VoidCallback onTap,
    Color bgColor = Colors.white,
    Color iconColor = const Color(0xFF1B5E20),
  }) {
    return Material(
      color: bgColor,
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildOfficesList(List<Map<String, dynamic>> offices) {
    if (offices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_city_rounded, size: 46, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              const Text(
                'এই জেলা/উপজেলায় এখনো কোনো যাচাইকৃত কৃষি অফিসের তথ্য যুক্ত করা হয়নি',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF546E7A)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: offices.length,
      itemBuilder: (ctx, i) {
        final o = offices[i];
        final lat = (o['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (o['longitude'] as num?)?.toDouble() ?? 0.0;
        final phone = o['phoneNumber']?.toString() ?? '';
        String? distText;
        if (_userLatLng != null && lat != 0 && lng != 0) {
          final meters = Geolocator.distanceBetween(
            _userLatLng!.latitude,
            _userLatLng!.longitude,
            lat,
            lng,
          );
          distText = '${(meters / 1000).toStringAsFixed(1)} km দূরে';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1.5,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (lat != 0 && lng != 0) {
                _currentZoom = 14.5;
                _mapController.move(LatLng(lat, lng), 14.5);
              }
              _showOfficeDetailsSheet(o);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          o['officeName']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      if (distText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            distText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0288D1),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${o['fullAddress'] ?? ''}, ${o['upazilaBnName'] ?? ''}, ${o['districtBnName'] ?? ''}',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF546E7A)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: phone.isEmpty ? null : () => _launchPhone(phone),
                          icon: const Icon(Icons.phone_rounded, size: 15),
                          label: Text(phone.isEmpty ? 'নম্বর নেই' : phone, style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00897B),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _launchDirections(lat, lng),
                          icon: const Icon(Icons.directions_rounded, size: 15),
                          label: const Text('ডিরেকশন', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
