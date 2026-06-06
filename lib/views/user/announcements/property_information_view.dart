import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_controller.dart';
import 'package:brokkerspot/views/user/announcements/controller/amenity_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:brokkerspot/widgets/common/overlay_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class PropertyInformationView extends StatefulWidget {
  const PropertyInformationView({super.key});

  @override
  State<PropertyInformationView> createState() =>
      _PropertyInformationViewState();
}

class _PropertyInformationViewState extends State<PropertyInformationView> {
  bool _isCommercial = false;
  String? _propertyType;
  String? _bedroom;
  String? _bathroom;
  String? _floor;
  String? _totalFloor;
  String? _isProperty;
  final _nameCtrl = TextEditingController();
  final _sqftCtrl = TextEditingController();
  final _spmCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  // Stores the selected amenity ObjectIds (what the API expects).
  final Set<String> _selectedAmenityIds = {};
  final _amenityCtrl = AmenityController.to;

  final _propertyTypes = ['Apartment', 'Villa', 'Townhouse', 'Penthouse', 'Studio'];
  final _bedroomBathroomCounts = ['1', '2', '3', '4', '5+'];
  final _floorCounts = ['G', '1', '2', '3', '4', '5+'];
  final _isPropertyOptions = ['Ready', 'Off Plan'];
  DateTime? _completionDate;

  bool get _isValid =>
      _propertyType != null &&
      _sqftCtrl.text.trim().isNotEmpty &&
      _spmCtrl.text.trim().isNotEmpty &&
      _bedroom != null &&
      _bathroom != null &&
      _floor != null &&
      _totalFloor != null &&
      _descCtrl.text.trim().isNotEmpty &&
      _isProperty != null &&
      (_isProperty != 'Off Plan' || _completionDate != null);

  @override
  void initState() {
    super.initState();
    final c = Get.find<AnnouncementController>();
    _propertyType = c.propertyType;
    if (c.propertyName != null) _nameCtrl.text = c.propertyName!;
    if (c.sqft != null) _sqftCtrl.text = c.sqft!.toStringAsFixed(0);
    if (c.sqm != null) _spmCtrl.text = c.sqm!.toStringAsFixed(0);
    _bedroom = _intToCountStr(c.bedrooms);
    _bathroom = _intToCountStr(c.bathrooms);
    _floor = _intToFloorStr(c.floor);
    _totalFloor = _intToFloorStr(c.totalFloors);
    if (c.description != null) _descCtrl.text = c.description!;
    if (c.amenities.isNotEmpty) _selectedAmenityIds.addAll(c.amenities);
    // Load the amenities reference list (cached after first fetch).
    _amenityCtrl.loadAmenities();
    if (c.propertyStatus == 1) _isProperty = 'Ready';
    if (c.propertyStatus == 2) _isProperty = 'Off Plan';
    _completionDate = c.completionDate;
    _isCommercial = c.isCommercialProperty == 1;
    _descCtrl.addListener(() => setState(() {}));
    _sqftCtrl.addListener(() => setState(() {}));
    _spmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sqftCtrl.dispose();
    _spmCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  int _parseFloor(String? val) {
    if (val == null) return 0;
    if (val == 'G') return 0;
    if (val == '5+') return 5;
    return int.tryParse(val) ?? 0;
  }

  String? _intToFloorStr(int? val) {
    if (val == null) return null;
    if (val == 0) return 'G';
    if (val >= 5) return '5+';
    return val.toString();
  }

  String? _intToCountStr(int? val) {
    if (val == null || val == 0) return null;
    if (val >= 5) return '5+';
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(title: 'INFORMATION', showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Commercial toggle
                    Row(
                      children: [
                        Text('Commercial Property',
                            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black87)),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.6,
                          child: Switch(
                            value: _isCommercial,
                            onChanged: (v) => setState(() => _isCommercial = v),
                            activeTrackColor: AppColors.primary,
                            thumbColor: WidgetStatePropertyAll(Colors.white),
                            inactiveTrackColor: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Property Type
                    _label('Property Type', required: true),
                    SizedBox(height: 8.h),
                    OverlayDropdownField(
                      hint: 'Select Now',
                      value: _propertyType,
                      items: _propertyTypes,
                      onSelect: (v) => setState(() => _propertyType = v),
                    ),
                    SizedBox(height: 16.h),

                    // Property Name
                    _label('Property Name'),
                    SizedBox(height: 8.h),
                    _textField(controller: _nameCtrl, hint: 'Write Here...'),
                    SizedBox(height: 16.h),

                    // Property Size
                    _label('Property Size', required: true),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(child: _textFieldSuffix(controller: _sqftCtrl, hint: '0', suffix: 'Sqft')),
                        SizedBox(width: 12.w),
                        Expanded(child: _textFieldSuffix(controller: _spmCtrl, hint: '0', suffix: 'Spm')),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Bedroom + Bathroom
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Bedroom', required: true),
                              SizedBox(height: 8.h),
                              OverlayDropdownField(
                                hint: '0',
                                value: _bedroom,
                                items: _bedroomBathroomCounts,
                                onSelect: (v) =>
                                    setState(() => _bedroom = v),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Bathroom', required: true),
                              SizedBox(height: 8.h),
                              OverlayDropdownField(
                                hint: '0',
                                value: _bathroom,
                                items: _bedroomBathroomCounts,
                                onSelect: (v) =>
                                    setState(() => _bathroom = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Floor + Total Floor
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Floor', required: true),
                              SizedBox(height: 8.h),
                              OverlayDropdownField(
                                hint: 'Select Floor',
                                value: _floor,
                                items: _floorCounts,
                                onSelect: (v) =>
                                    setState(() => _floor = v),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Total Floor', required: true),
                              SizedBox(height: 8.h),
                              OverlayDropdownField(
                                hint: 'Select Floor',
                                value: _totalFloor,
                                items: _floorCounts,
                                onSelect: (v) =>
                                    setState(() => _totalFloor = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Property Description
                    _label('Property Description', required: true),
                    SizedBox(height: 8.h),
                    _descriptionField(),
                    SizedBox(height: 16.h),

                    // Is Property
                    _label('Is Property', required: true),
                    SizedBox(height: 8.h),
                    OverlayDropdownField(
                      hint: 'Select Now',
                      value: _isProperty,
                      items: _isPropertyOptions,
                      onSelect: (v) => setState(() {
                        _isProperty = v;
                        if (v != 'Off Plan') _completionDate = null;
                      }),
                    ),
                    if (_isProperty == 'Off Plan') ...[
                      SizedBox(height: 16.h),
                      _label('Completion Date of Property', required: true),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                    primary: AppColors.primary),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setState(() => _completionDate = picked);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _completionDate != null
                                      ? '${_completionDate!.month.toString().padLeft(2, '0')}/${_completionDate!.day.toString().padLeft(2, '0')}/${_completionDate!.year}'
                                      : 'mm/dd/yyyy',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: _completionDate != null
                                        ? Colors.black87
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              Icon(Icons.calendar_today_outlined,
                                  color: AppColors.primary, size: 18.sp),
                            ],
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 20.h),

                    // Amenities
                    Text('Amenities',
                        style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87)),
                    SizedBox(height: 12.h),
                    _buildAmenities(),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: CustomPrimaryButton(
                title: 'Done',
                backgroundColor: _isValid ? AppColors.primary : Colors.grey.shade300,
                defaultColor: _isValid ? Colors.white : Colors.black45,
                onPressed: _isValid
                    ? () {
                        Get.find<AnnouncementController>().setInformation(
                          propertyType: _propertyType!,
                          propertyName: _nameCtrl.text.trim().isEmpty
                              ? null
                              : _nameCtrl.text.trim(),
                          sqft: double.tryParse(_sqftCtrl.text.trim()) ?? 0,
                          sqm: double.tryParse(_spmCtrl.text.trim()) ?? 0,
                          bedrooms: int.tryParse(_bedroom!) ?? 0,
                          bathrooms: int.tryParse(_bathroom!) ?? 0,
                          floor: _parseFloor(_floor),
                          totalFloors: _parseFloor(_totalFloor),
                          description: _descCtrl.text.trim(),
                          amenities: _selectedAmenityIds.toList(),
                          propertyStatus: _isProperty == 'Off Plan' ? 2 : 1,
                          isCommercialProperty: _isCommercial ? 1 : 0,
                          completionDate: _completionDate,
                        );
                        Navigator.pop(context, true);
                      }
                    : () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenities() {
    return Obx(() {
      if (_amenityCtrl.isLoading.value && _amenityCtrl.amenities.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      if (_amenityCtrl.error.value != null && _amenityCtrl.amenities.isEmpty) {
        return Row(
          children: [
            Expanded(
              child: Text(
                "Couldn't load amenities.",
                style:
                    GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500),
              ),
            ),
            TextButton(
              onPressed: () => _amenityCtrl.loadAmenities(force: true),
              child: Text('Retry',
                  style:
                      GoogleFonts.inter(fontSize: 12.sp, color: AppColors.primary)),
            ),
          ],
        );
      }
      if (_amenityCtrl.amenities.isEmpty) {
        return Text('No amenities available',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade400));
      }
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 4,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        children: _amenityCtrl.amenities.map((item) {
          final selected = _selectedAmenityIds.contains(item.id);
          return GestureDetector(
            onTap: () => setState(() {
              selected
                  ? _selectedAmenityIds.remove(item.id)
                  : _selectedAmenityIds.add(item.id);
            }),
            child: Row(
              children: [
                Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(3.r),
                    color: selected ? AppColors.primary : Colors.white,
                  ),
                  child: selected
                      ? Icon(Icons.check, size: 12.sp, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(item.name,
                      style: GoogleFonts.inter(
                          fontSize: 12.sp, color: Colors.black87),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black87),
        children: required
            ? [TextSpan(text: ' *', style: GoogleFonts.inter(color: Colors.red))]
            : null,
      ),
    );
  }

  Widget _textField({required TextEditingController controller, required String hint}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(fontSize: 13.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade400),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _textFieldSuffix({
    required TextEditingController controller,
    required String hint,
    required String suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade400),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                border: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: Text(suffix,
                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500)),
          ),
        ],
      ),
    );
  }

  Widget _descriptionField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        children: [
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            maxLength: 300,
            style: GoogleFonts.inter(fontSize: 13.sp),
            decoration: InputDecoration(
              hintText: 'Write Here...',
              hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade400),
              contentPadding: EdgeInsets.all(12.w),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 10.w, bottom: 6.h),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('${_descCtrl.text.length}/300',
                  style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400)),
            ),
          ),
        ],
      ),
    );
  }
}
