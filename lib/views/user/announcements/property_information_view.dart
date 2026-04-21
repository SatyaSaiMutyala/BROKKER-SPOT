import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final Set<String> _amenities = {};

  // Which dropdown is open
  String _openDropdown = '';

  final _propertyTypes = ['Apartment', 'Villa', 'Townhouse', 'Penthouse', 'Studio'];
  final _bedroomBathroomCounts = ['1', '2', '3', '4', '5+'];
  final _floorCounts = ['G', '1', '2', '3', '4', '5+'];
  final _isPropertyOptions = ['Ready', 'Off Plan'];
  DateTime? _completionDate;
  final _amenityList = [
    'Partly furnished', 'Balcony',
    'Built in Wardrobes', 'Central A/C',
    'Concierge', 'Covered Parking',
    'Security', 'Shared Gym',
    'Shared Pool', 'View of Water',
  ];

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

  void _toggle(String key) {
    setState(() => _openDropdown = _openDropdown == key ? '' : key);
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
                            activeThumbColor: Colors.white,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Property Type
                    _label('Property Type', required: true),
                    SizedBox(height: 8.h),
                    _inlineDropdown(
                      key: 'type',
                      hint: 'Select Now',
                      value: _propertyType,
                      items: _propertyTypes,
                      onSelect: (v) => setState(() {
                        _propertyType = v;
                        _openDropdown = '';
                      }),
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
                              _inlineDropdown(
                                key: 'bedroom',
                                hint: '0',
                                value: _bedroom,
                                items: _bedroomBathroomCounts,
                                onSelect: (v) => setState(() {
                                  _bedroom = v;
                                  _openDropdown = '';
                                }),
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
                              _inlineDropdown(
                                key: 'bathroom',
                                hint: '0',
                                value: _bathroom,
                                items: _bedroomBathroomCounts,
                                onSelect: (v) => setState(() {
                                  _bathroom = v;
                                  _openDropdown = '';
                                }),
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
                              _inlineDropdown(
                                key: 'floor',
                                hint: 'Select Floor',
                                value: _floor,
                                items: _floorCounts,
                                onSelect: (v) => setState(() {
                                  _floor = v;
                                  _openDropdown = '';
                                }),
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
                              _inlineDropdown(
                                key: 'totalFloor',
                                hint: 'Select Floor',
                                value: _totalFloor,
                                items: _floorCounts,
                                onSelect: (v) => setState(() {
                                  _totalFloor = v;
                                  _openDropdown = '';
                                }),
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
                    _inlineDropdown(
                      key: 'isProperty',
                      hint: 'Select Now',
                      value: _isProperty,
                      items: _isPropertyOptions,
                      onSelect: (v) => setState(() {
                        _isProperty = v;
                        _openDropdown = '';
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
                onPressed: _isValid ? () => Navigator.pop(context, true) : () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineDropdown({
    required String key,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String> onSelect,
  }) {
    final isOpen = _openDropdown == key;
    return Column(
      children: [
        GestureDetector(
          onTap: () => _toggle(key),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: isOpen
                  ? BorderRadius.vertical(top: Radius.circular(6.r))
                  : BorderRadius.circular(6.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: value != null ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                ),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade500,
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
                right: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.r)),
            ),
            child: Column(
              children: items.map((item) {
                final isSelected = value == item;
                return InkWell(
                  onTap: () => onSelect(item),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.primary : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildAmenities() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 4,
      mainAxisSpacing: 8.h,
      crossAxisSpacing: 8.w,
      children: _amenityList.map((item) {
        final selected = _amenities.contains(item);
        return GestureDetector(
          onTap: () => setState(() {
            selected ? _amenities.remove(item) : _amenities.add(item);
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
                child: Text(item,
                    style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.black87),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
