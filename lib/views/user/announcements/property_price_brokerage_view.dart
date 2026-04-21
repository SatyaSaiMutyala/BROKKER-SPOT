import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  // Rent fields
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

  @override
  void initState() {
    super.initState();
    _priceCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  void _showPicker(List<String> options, String? current, ValueChanged<String> onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: options.map((opt) => ListTile(
            title: Text(opt, style: GoogleFonts.inter(fontSize: 14.sp)),
            trailing: current == opt
                ? Icon(Icons.check, color: AppColors.primary, size: 18.sp)
                : null,
            onTap: () {
              onSelect(opt);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _availableDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(title: 'PRICE & BROKERAGE', showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: _isSell ? _sellLayout() : _rentLayout(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: CustomPrimaryButton(
                title: 'Save',
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

  // ── Sell layout ──────────────────────────────────────────────
  Widget _sellLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Set Property Price', required: true),
        SizedBox(height: 8.h),
        _priceField(),
        SizedBox(height: 24.h),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Set Brokerage'),
                SizedBox(height: 8.h),
                _brokerageStepperRow(),
              ],
            ),
          ],
        ),
        SizedBox(height: 20.h),

        _readOnlyAmountField(
          label: 'You have to pay Brokerage',
          amount: _brokerageAmount,
        ),
        SizedBox(height: 16.h),

        _readOnlyAmountField(
          label: 'You will receive Amount',
          amount: _receiveAmount,
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  // ── Rent layout ──────────────────────────────────────────────
  Widget _rentLayout() {
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
                  _label('Set Property Rent Price', required: true),
                  SizedBox(height: 8.h),
                  _priceField(),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Monthly/Yearly', required: true),
                  SizedBox(height: 8.h),
                  _dropdownTile(
                    hint: 'Select Now',
                    value: _priceType,
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
        _label('Property is Available For Rent', required: true),
        SizedBox(height: 8.h),
        _datePicker(),
        SizedBox(height: 32.h),
      ],
    );
  }

  // ── Widgets ──────────────────────────────────────────────────

  Widget _brokerageStepperRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(
            icon: Icons.remove,
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
                color: Colors.black87,
              ),
            ),
          ),
          _stepperButton(
            icon: Icons.add,
            onTap: () => setState(() => _brokeragePercent++),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Icon(icon, color: AppColors.primary, size: 18.sp),
      ),
    );
  }

  Widget _readOnlyAmountField({required String label, required double amount}) {
    final hasPrice = _priceCtrl.text.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.black54)),
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

  Widget _priceField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Text('€ ',
                style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle:
                    GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade400),
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownTile(
      {required String hint, required String? value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(value ?? hint,
                  style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: value != null ? Colors.black87 : Colors.grey.shade400)),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500, size: 18.sp),
          ],
        ),
      ),
    );
  }

  Widget _datePicker() {
    final text = _availableDate != null
        ? '${_availableDate!.month.toString().padLeft(2, '0')}/${_availableDate!.day.toString().padLeft(2, '0')}/${_availableDate!.year}'
        : 'mm/dd/yyyy';
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color:
                        _availableDate != null ? Colors.black87 : Colors.grey.shade400),
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
