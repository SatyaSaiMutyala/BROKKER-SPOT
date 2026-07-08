import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class PropertyPriceBrokerageView extends StatefulWidget {
  final String? propertyFor;
  const PropertyPriceBrokerageView({super.key, this.propertyFor});

  @override
  State<PropertyPriceBrokerageView> createState() =>
      _PropertyPriceBrokerageViewState();
}

class _PropertyPriceBrokerageViewState
    extends State<PropertyPriceBrokerageView> {
  final _priceCtrl = TextEditingController();
  int _brokeragePercent = 2;

  String? _priceType;
  DateTime? _availableDate;

  bool get _isSell => widget.propertyFor == 'Sell';

  bool get _isValid {
    if (_isSell) return _priceCtrl.text.trim().isNotEmpty;
    return _priceCtrl.text.trim().isNotEmpty &&
        _priceType != null &&
        _availableDate != null;
  }

  double get _price => double.tryParse(_priceCtrl.text.trim()) ?? 0;
  double get _brokerageAmount => _price * _brokeragePercent / 100;
  double get _receiveAmount => _price - _brokerageAmount;

  double get _oneMonthRent => _priceType == 'Yearly' ? _price / 12 : _price;
  double get _rentBrokerageAmount => _oneMonthRent * _brokeragePercent / 100;

  @override
  void initState() {
    super.initState();
    final c = Get.find<AnnouncementController>();
    if (c.price != null) _priceCtrl.text = c.price!.toStringAsFixed(0);
    _brokeragePercent = c.brokeragePercent;
    if (c.rentPeriod != null) {
      final rp = c.rentPeriod!;
      _priceType = rp[0].toUpperCase() + rp.substring(1);
    }
    _availableDate = c.availableDate;
    _priceCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  void _showPicker(
      List<String> options, String? current, ValueChanged<String> onSelect) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: options
              .map((opt) => ListTile(
                    title: Text(
                      opt,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: current == opt
                        ? Icon(Icons.check,
                            color: AppColors.primary, size: 18.sp)
                        : null,
                    onTap: () {
                      onSelect(opt);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isDark) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.primary,
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.white,
            surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            onSurface: isDark ? Colors.white : Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _availableDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                child: _isSell ? _sellLayout(isDark) : _rentLayout(isDark),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: GestureDetector(
                onTap: _isValid
                    ? () {
                        Get.find<AnnouncementController>().setPrice(
                          price: _price,
                          brokeragePercent: _brokeragePercent,
                          rentPeriod: _isSell ? null : _priceType,
                          availableDate: _isSell ? null : _availableDate,
                        );
                        Navigator.pop(context, true);
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: _isValid
                        ? AppColors.primary
                        : (isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(38.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: _isValid
                          ? Colors.white
                          : (isDark ? Colors.grey.shade600 : Colors.black45),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 8.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Text(
            'Price & Availability',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sell layout ───────────────────────────────────────────────────────────

  Widget _sellLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Set Property Price', required: true, isDark: isDark),
        SizedBox(height: 8.h),
        _priceField(isDark),
        SizedBox(height: 24.h),
        _label('Set Brokerage', isDark: isDark),
        SizedBox(height: 8.h),
        _brokerageStepperRow(isDark),
        SizedBox(height: 20.h),
        _readOnlyAmountField(
          label: 'You will receive Brokerage',
          amount: _brokerageAmount,
          isDark: isDark,
        ),
        SizedBox(height: 16.h),
        _readOnlyAmountField(
          label: 'You have to pay owner',
          amount: _receiveAmount,
          isDark: isDark,
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  // ── Rent layout ───────────────────────────────────────────────────────────

  Widget _rentLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Set Property Rent Price',
                      required: true, isDark: isDark),
                  SizedBox(height: 8.h),
                  _priceField(isDark),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Monthly/Yearly', required: true, isDark: isDark),
                  SizedBox(height: 8.h),
                  _dropdownTile(
                    hint: 'Select Now',
                    value: _priceType,
                    isDark: isDark,
                    onTap: () => _showPicker(
                      ['Monthly', 'Yearly'],
                      _priceType,
                      (v) => setState(() => _priceType = v),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        _label('Property is Available For Rent',
            required: true, isDark: isDark),
        SizedBox(height: 8.h),
        _datePicker(isDark),
        SizedBox(height: 24.h),
        Text(
          'Are You want to share brokerage with broker?',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        SizedBox(height: 14.h),
        _label('Set Brokerage', isDark: isDark),
        SizedBox(height: 8.h),
        _brokerageStepperRow(isDark),
        SizedBox(height: 20.h),
        _readOnlyAmountField(
          label: 'You will receive one Month Brokerage',
          amount: _rentBrokerageAmount,
          isDark: isDark,
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _label(String text, {bool required = false, required bool isDark}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          color: isDark ? Colors.grey.shade300 : Colors.black87,
        ),
        children: required
            ? [
                TextSpan(
                    text: ' *', style: GoogleFonts.inter(color: Colors.red))
              ]
            : null,
      ),
    );
  }

  Widget _priceField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Text(
              '€ ',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brokerageStepperRow(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(
            icon: Icons.remove,
            isDark: isDark,
            onTap: () {
              if (_brokeragePercent > 0) setState(() => _brokeragePercent--);
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              '$_brokeragePercent %',
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          _stepperButton(
            icon: Icons.add,
            isDark: isDark,
            onTap: () => setState(() => _brokeragePercent++),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        ),
        child: Icon(icon, color: AppColors.primary, size: 18.sp),
      ),
    );
  }

  Widget _readOnlyAmountField({
    required String label,
    required double amount,
    required bool isDark,
  }) {
    final hasPrice = _priceCtrl.text.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            hasPrice ? '€ ${amount.toStringAsFixed(0)}' : '€ 0',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownTile({
    required String hint,
    required String? value,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: value != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePicker(bool isDark) {
    final text = _availableDate != null
        ? '${_availableDate!.month.toString().padLeft(2, '0')}/${_availableDate!.day.toString().padLeft(2, '0')}/${_availableDate!.year}'
        : 'mm/dd/yyyy';
    return GestureDetector(
      onTap: () => _pickDate(isDark),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: _availableDate != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                ),
              ),
            ),
            Icon(Icons.calendar_today_outlined,
                color: AppColors.primary, size: 18.sp),
          ],
        ),
      ),
    );
  }
}
