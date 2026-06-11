import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

const _apiKey = 'AIzaSyCSQdMM4dbaj1ECCbftDVZCIcca8usqQVs';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String address;
  final String country;
  final String city;
  final String area;

  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.country,
    required this.city,
    required this.area,
  });
}

class MapPickerView extends StatefulWidget {
  final LatLng? initialPosition;

  const MapPickerView({super.key, this.initialPosition});

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  static const _defaultPosition = LatLng(25.2048, 55.2708); // Dubai

  GoogleMapController? _mapController;
  late LatLng _center;
  bool _isGeocoding = false;
  String _address = '';
  String _country = '';
  String _city = '';
  String _area = '';

  final _searchCtrl = TextEditingController();
  List<_PlaceSuggestion> _suggestions = [];
  bool _searchLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition ?? _defaultPosition;
    _reverseGeocode(_center);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _fetchSuggestions(q);
  }

  Future<void> _fetchSuggestions(String input) async {
    setState(() => _searchLoading = true);
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}&key=$_apiKey&types=geocode',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final predictions = (data['predictions'] as List?) ?? [];
        setState(() {
          _suggestions = predictions.map((p) {
            return _PlaceSuggestion(
              placeId: p['place_id'] as String,
              description: p['description'] as String,
            );
          }).toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  Future<void> _selectSuggestion(_PlaceSuggestion s) async {
    _searchCtrl.text = s.description;
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    FocusScope.of(context).unfocus();
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${s.placeId}&fields=geometry&key=$_apiKey',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final loc =
            data['result']?['geometry']?['location'] as Map<String, dynamic>?;
        if (loc != null) {
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          final pos = LatLng(lat, lng);
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
          setState(() => _center = pos);
          await _reverseGeocode(pos);
        }
      }
    } catch (_) {}
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isGeocoding = true);
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${pos.latitude},${pos.longitude}&key=$_apiKey',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (data['results'] as List?) ?? [];
        if (results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final formattedAddress = first['formatted_address'] as String? ?? '';
          final components = (first['address_components'] as List?) ?? [];

          String country = '', city = '', area = '';
          for (final comp in components) {
            final types = (comp['types'] as List).cast<String>();
            if (types.contains('country')) {
              country = comp['long_name'] as String;
            } else if (types.contains('locality') ||
                types.contains('administrative_area_level_2')) {
              if (city.isEmpty) city = comp['long_name'] as String;
            } else if (types.contains('sublocality') ||
                types.contains('sublocality_level_1') ||
                types.contains('neighborhood')) {
              if (area.isEmpty) area = comp['long_name'] as String;
            } else if (types.contains('administrative_area_level_1') &&
                city.isEmpty) {
              city = comp['long_name'] as String;
            }
          }

          if (mounted) {
            setState(() {
              _address = formattedAddress;
              _country = country;
              _city = city;
              _area = area;
            });
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _onCameraMove(CameraPosition pos) {
    _center = pos.target;
  }

  void _onCameraIdle() {
    _reverseGeocode(_center);
  }

  void _confirm() {
    Navigator.pop(
      context,
      LocationPickerResult(
        latitude: _center.latitude,
        longitude: _center.longitude,
        address: _address,
        country: _country,
        city: _city,
        area: _area,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Map ──────────────────────────────────────────────────────────
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 14),
              onMapCreated: (c) => _mapController = c,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),

            // ── Center pin ───────────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_pin, color: Colors.red, size: 48.sp),
                  SizedBox(height: 24.h),
                ],
              ),
            ),

            // ── Search bar ───────────────────────────────────────────────────
            Positioned(
              top: 12.h,
              left: 16.w,
              right: 16.w,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.arrow_back,
                                size: 22.sp, color: Colors.black87),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: GoogleFonts.inter(fontSize: 14.sp),
                            decoration: InputDecoration(
                              hintText: 'Search location...',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 14.sp, color: Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 14.h),
                            ),
                          ),
                        ),
                        if (_searchLoading)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          )
                        else if (_searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() {
                                _suggestions = [];
                                _showSuggestions = false;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              child: Icon(Icons.close,
                                  size: 20.sp, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_showSuggestions && _suggestions.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (_, i) {
                          final s = _suggestions[i];
                          return InkWell(
                            onTap: () => _selectSuggestion(s),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 12.h),
                              child: Row(
                                children: [
                                  Icon(Icons.place_outlined,
                                      size: 18.sp, color: Colors.grey.shade500),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      s.description,
                                      style: GoogleFonts.inter(fontSize: 13.sp),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // ── Bottom address card + confirm ────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16.r)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 18.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'Selected Location',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (_isGeocoding)
                          SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child:
                                const CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _address.isNotEmpty
                          ? _address
                          : 'Move the map to select a location',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: _address.isNotEmpty
                            ? Colors.black87
                            : Colors.grey.shade400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_country.isNotEmpty || _city.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        [_area, _city, _country]
                            .where((s) => s.isNotEmpty)
                            .join(', '),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _address.isNotEmpty && !_isGeocoding
                            ? _confirm
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A2E),
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          'Confirm Location',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceSuggestion {
  final String placeId;
  final String description;

  const _PlaceSuggestion({required this.placeId, required this.description});
}
