import 'dart:async';
import 'dart:convert';

import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/widgets/common/custom_back_button.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart' show EagerGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
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

  /// Surfaced under the search bar. Without this a denied API key looks
  /// identical to "no places matched" — which is exactly how the legacy-API
  /// rejection stayed invisible.
  String? _searchError;

  Timer? _debounce;

  /// Set while [_selectSuggestion] writes the chosen place into the field.
  /// Assigning `_searchCtrl.text` fires the listener, which would otherwise
  /// kick off a fresh search and pop the suggestion list straight back open.
  bool _suppressSearch = false;

  MapType _mapType = MapType.normal;

  /// True between `onCameraMoveStarted` and `onCameraIdle` — lifts the pin so a
  /// drag visibly does something.
  bool _isMapMoving = false;

  /// True while resolving the device's GPS fix for the my-location button.
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition ?? _defaultPosition;
    _reverseGeocode(_center);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_suppressSearch) return;
    final q = _searchCtrl.text.trim();
    _debounce?.cancel();
    if (q.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _searchError = null;
      });
      return;
    }
    // Autocomplete is billed per request, so coalesce keystrokes instead of
    // firing one call per character.
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _fetchSuggestions(q);
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    setState(() {
      _searchLoading = true;
      _searchError = null;
    });
    try {
      // Places API (New). The legacy `maps/api/place/autocomplete` endpoint
      // answers REQUEST_DENIED on this project ("You're calling a legacy API,
      // which is not enabled") while still returning HTTP 200 and an empty
      // prediction list — which is why searching looked like it simply found
      // nothing. Google no longer enables the legacy API for new projects.
      final res = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
        headers: const {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
        },
        body: jsonEncode({'input': input}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode != 200) {
        final message =
            (data['error'] as Map<String, dynamic>?)?['message'] as String?;
        if (mounted) {
          setState(() {
            _suggestions = [];
            _showSuggestions = false;
            _searchError = message ?? 'Search unavailable (${res.statusCode})';
          });
        }
        return;
      }

      final suggestions = (data['suggestions'] as List?) ?? [];
      final parsed = <_PlaceSuggestion>[];
      for (final s in suggestions) {
        final p = (s as Map<String, dynamic>)['placePrediction']
            as Map<String, dynamic>?;
        // Query predictions ("pizza near me") carry no placeId — skip them,
        // there is nothing to resolve to coordinates.
        if (p == null) continue;
        final id = p['placeId'] as String?;
        final text = (p['text'] as Map<String, dynamic>?)?['text'] as String?;
        if (id == null || text == null) continue;
        parsed.add(_PlaceSuggestion(placeId: id, description: text));
      }

      if (!mounted) return;
      setState(() {
        _suggestions = parsed;
        _showSuggestions = parsed.isNotEmpty;
        _searchError = parsed.isEmpty ? 'No places found for "$input"' : null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
          _searchError = 'Could not reach the location service.';
        });
      }
    } finally {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  Future<void> _selectSuggestion(_PlaceSuggestion s) async {
    _debounce?.cancel();
    _suppressSearch = true;
    _searchCtrl.text = s.description;
    _suppressSearch = false;
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
      _searchError = null;
    });
    FocusScope.of(context).unfocus();
    try {
      // Place Details (New) — the legacy `place/details` endpoint is denied on
      // this project for the same reason as autocomplete. `X-Goog-FieldMask` is
      // mandatory here; omitting it is a 400.
      final res = await http.get(
        Uri.parse('https://places.googleapis.com/v1/places/${s.placeId}'),
        headers: const {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'location',
        },
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        if (mounted) {
          setState(() => _searchError =
              (data['error'] as Map<String, dynamic>?)?['message'] as String? ??
                  'Could not open that place.');
        }
        return;
      }
      final loc = data['location'] as Map<String, dynamic>?;
      if (loc == null) return;
      final pos = LatLng(
        (loc['latitude'] as num).toDouble(),
        (loc['longitude'] as num).toDouble(),
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
      if (!mounted) return;
      setState(() => _center = pos);
      await _reverseGeocode(pos);
    } catch (_) {
      if (mounted) {
        setState(() => _searchError = 'Could not reach the location service.');
      }
    }
  }

  /// Handles the keyboard's search/enter key. Previously the field had no
  /// [TextField.onSubmitted], so pressing it only dismissed the keypad.
  Future<void> _onSearchSubmitted(String value) async {
    final q = value.trim();
    if (q.length < 3) return;
    _debounce?.cancel();
    // Already have matches → take the top one, which is what the keyboard
    // action implies.
    if (_suggestions.isNotEmpty) {
      await _selectSuggestion(_suggestions.first);
      return;
    }
    await _fetchSuggestions(q);
    if (mounted && _suggestions.isNotEmpty) {
      await _selectSuggestion(_suggestions.first);
    }
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
    // Deliberately no setState — this fires every frame of a drag.
    _center = pos.target;
  }

  void _onCameraMoveStarted() {
    if (!_isMapMoving) setState(() => _isMapMoving = true);
  }

  void _onCameraIdle() {
    if (_isMapMoving) setState(() => _isMapMoving = false);
    // Not debounced on purpose: the Confirm button gates on `_isGeocoding`, so
    // delaying the lookup would leave a window where a stale address looks
    // ready to submit.
    _reverseGeocode(_center);
  }

  /// Tap (or long-press) anywhere to move the pin there. Recentres rather than
  /// dropping a separate marker, so the pin the user reads and the coordinate
  /// that gets submitted can never disagree.
  void _onMapTap(LatLng pos) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    _center = pos;
    // `animateCamera` ends in onCameraIdle, which does the reverse geocode.
  }

  Future<void> _zoomBy(double delta) async {
    await _mapController?.animateCamera(CameraUpdate.zoomBy(delta));
  }

  void _cycleMapType() {
    setState(() {
      _mapType = switch (_mapType) {
        MapType.normal => MapType.hybrid,
        MapType.hybrid => MapType.terrain,
        _ => MapType.normal,
      };
    });
  }

  /// Centres the map on the device's current position. Mirrors the permission
  /// flow used by PropertyLocationView's "use current location".
  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMapMessage('Location services are disabled');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMapMessage('Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final target = LatLng(pos.latitude, pos.longitude);
      _center = target;
      await _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    } catch (_) {
      _showMapMessage('Could not get your location');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showMapMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final hintText = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final dividerColor =
        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200;
    final shadowColor = isDark ? Colors.black54 : Colors.black12;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Map ──────────────────────────────────────────────────────────
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 14),
              onMapCreated: (c) => _mapController = c,
              onCameraMove: _onCameraMove,
              onCameraMoveStarted: _onCameraMoveStarted,
              onCameraIdle: _onCameraIdle,
              onTap: _onMapTap,
              onLongPress: _onMapTap,
              mapType: _mapType,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              // The map is an Android/iOS platform view, so its touches have to
              // win Flutter's gesture arena before they reach the native view.
              // Claiming them eagerly is what makes panning and pinch-zoom work
              // — without this the arena can hand the drag to an ancestor and
              // the map reads as frozen.
              gestureRecognizers: {
                Factory<EagerGestureRecognizer>(
                    () => EagerGestureRecognizer()),
              },
            ),

            // ── Center pin ───────────────────────────────────────────────────
            // IgnorePointer is load-bearing: this Center fills the whole Stack,
            // so without it the pin sits between the user's finger and the map.
            IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lifts while the map moves, so a drag has visible feedback.
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      transform: Matrix4.translationValues(
                          0, _isMapMoving ? -10.h : 0, 0),
                      child: Icon(Icons.location_pin,
                          color: Colors.red, size: 48.sp),
                    ),
                    // Marks the exact coordinate the pin's tip refers to.
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
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
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: CustomBackButton(
                            isDark: isDark,
                            iconColor: primaryText,
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            textInputAction: TextInputAction.search,
                            onSubmitted: _onSearchSubmitted,
                            style: GoogleFonts.inter(
                                fontSize: 14.sp, color: primaryText),
                            decoration: InputDecoration(
                              hintText: 'Search location...',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 14.sp, color: hintText),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: true,
                              fillColor: Colors.transparent,
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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
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
                                  size: 20.sp, color: iconColor),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_searchError != null)
                    Container(
                      margin: EdgeInsets.only(top: 4.h),
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 16.sp, color: Colors.red.shade400),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _searchError!,
                              style: GoogleFonts.inter(
                                  fontSize: 12.sp, color: primaryText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_showSuggestions && _suggestions.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 4.h),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
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
                            Divider(height: 1, color: dividerColor),
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
                                      size: 18.sp, color: iconColor),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      s.description,
                                      style: GoogleFonts.inter(
                                          fontSize: 13.sp, color: primaryText),
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

            // ── Map controls ─────────────────────────────────────────────────
            Positioned(
              right: 16.w,
              bottom: 210.h,
              child: Column(
                children: [
                  _mapControlButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'My location',
                    busy: _locating,
                    cardBg: cardBg,
                    iconColor: primaryText,
                    shadowColor: shadowColor,
                    onTap: _goToMyLocation,
                  ),
                  SizedBox(height: 10.h),
                  _mapControlButton(
                    icon: _mapType == MapType.normal
                        ? Icons.layers_outlined
                        : Icons.layers,
                    tooltip: 'Map type',
                    cardBg: cardBg,
                    iconColor: primaryText,
                    shadowColor: shadowColor,
                    onTap: _cycleMapType,
                  ),
                  SizedBox(height: 10.h),
                  _mapControlButton(
                    icon: Icons.add,
                    tooltip: 'Zoom in',
                    cardBg: cardBg,
                    iconColor: primaryText,
                    shadowColor: shadowColor,
                    onTap: () => _zoomBy(1),
                  ),
                  SizedBox(height: 10.h),
                  _mapControlButton(
                    icon: Icons.remove,
                    tooltip: 'Zoom out',
                    cardBg: cardBg,
                    iconColor: primaryText,
                    shadowColor: shadowColor,
                    onTap: () => _zoomBy(-1),
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
                  color: cardBg,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16.r)),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
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
                        Icon(Icons.location_on,
                            color: AppColors.primary, size: 18.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'Selected Location',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                        const Spacer(),
                        if (_isGeocoding)
                          SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
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
                        color: _address.isNotEmpty ? primaryText : hintText,
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
                          color: iconColor,
                        ),
                      ),
                    ],
                    SizedBox(height: 16.h),
                    GestureDetector(
                      onTap: _address.isNotEmpty && !_isGeocoding
                          ? _confirm
                          : null,
                      child: Container(
                        width: double.infinity,
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: _address.isNotEmpty && !_isGeocoding
                              ? AppColors.primary
                              : (isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(38.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Confirm Location',
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: _address.isNotEmpty && !_isGeocoding
                                ? Colors.white
                                : (isDark
                                    ? Colors.grey.shade600
                                    : Colors.black45),
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

  Widget _mapControlButton({
    required IconData icon,
    required String tooltip,
    required Color cardBg,
    required Color iconColor,
    required Color shadowColor,
    required VoidCallback onTap,
    bool busy = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: cardBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: busy
              ? Padding(
                  padding: EdgeInsets.all(11.w),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              : Icon(icon, size: 20.sp, color: iconColor),
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
