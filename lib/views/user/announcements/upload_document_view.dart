import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class UploadDocumentView extends StatefulWidget {
  final String? propertyFor;
  const UploadDocumentView({super.key, this.propertyFor});

  @override
  State<UploadDocumentView> createState() => _UploadDocumentViewState();
}

class _UploadDocumentViewState extends State<UploadDocumentView> {
  // Shared – ID type
  String _selectedIdType = 'Upload UAE ID Card';
  bool _idDropdownOpen = false;
  final _idTypes = ['Upload UAE ID Card', 'Upload Your Passport'];

  // Sell only – Deed type
  String _selectedDeedType = 'Upload Title Deed';
  bool _deedDropdownOpen = false;
  final _deedTypes = ['Upload Title Deed', 'Upload Oqood'];

  bool get _isSell => widget.propertyFor == 'Sell';

  bool get _isValid {
    if (_isSell) {
      return _idFrontUploaded && _idBackUploaded && _deedUploaded;
    }
    return _rentIdFrontUploaded && _rentIdBackUploaded && _rentDeedUploaded;
  }

  // Upload states
  bool _idFrontUploaded = false;
  bool _idBackUploaded = false;
  bool _deedUploaded = false;
  bool _nocUploaded = false;
  bool _rentIdFrontUploaded = false;
  bool _rentIdBackUploaded = false;
  bool _rentDeedUploaded = false;

  final _picker = ImagePicker();

  Future<bool> _pickFile() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      return picked != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(title: 'Upload Document', showBackButton: true),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Important Note
                    Text(
                      'Important Note:',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'We will only share your documents with brokers you choose and Allow (Authorize) through our application. If you want to delete your personal data, you can send us a request, and we will start the deletion process.',
                      style: GoogleFonts.inter(
                          fontSize: 13.sp, color: Colors.black87, height: 1.5),
                    ),
                    SizedBox(height: 24.h),
                    Divider(height: 1, color: Colors.grey.shade200),
                    SizedBox(height: 24.h),

                    if (_isSell) ..._sellLayout() else ..._rentLayout(),

                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isValid ? () => Navigator.pop(context, true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid ? AppColors.primary : Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r)),
                  ),
                  child: Text(
                    'SAVE',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: _isValid ? Colors.white : Colors.black54,
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

  // ── Sell layout ──────────────────────────────────────────────
  List<Widget> _sellLayout() {
    return [
      // ID type dropdown (golden border)
      _goldDropdown(
        selected: _selectedIdType,
        isOpen: _idDropdownOpen,
        options: _idTypes,
        onToggle: () => setState(() {
          _idDropdownOpen = !_idDropdownOpen;
          if (_idDropdownOpen) _deedDropdownOpen = false;
        }),
        onSelect: (v) => setState(() {
          _selectedIdType = v;
          _idDropdownOpen = false;
        }),
      ),
      SizedBox(height: 16.h),
      Text(
        '${_selectedIdType.replaceFirst('Upload ', '')} Doc',
        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600),
      ),
      SizedBox(height: 12.h),
      Row(
        children: [
          Expanded(
            child: _uploadButton(
              label: 'Front Side',
              isUploaded: _idFrontUploaded,
              onTap: () async {
                if (await _pickFile()) setState(() => _idFrontUploaded = true);
              },
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _uploadButton(
              label: 'Back Side',
              isUploaded: _idBackUploaded,
              onTap: () async {
                if (await _pickFile()) setState(() => _idBackUploaded = true);
              },
            ),
          ),
        ],
      ),
      SizedBox(height: 24.h),
      Divider(height: 1, color: Colors.grey.shade200),
      SizedBox(height: 24.h),

      // Deed type dropdown (golden border)
      _goldDropdown(
        selected: _selectedDeedType,
        isOpen: _deedDropdownOpen,
        options: _deedTypes,
        onToggle: () => setState(() {
          _deedDropdownOpen = !_deedDropdownOpen;
          if (_deedDropdownOpen) _idDropdownOpen = false;
        }),
        onSelect: (v) => setState(() {
          _selectedDeedType = v;
          _deedDropdownOpen = false;
        }),
      ),
      SizedBox(height: 16.h),
      Text(
        '${_selectedDeedType.replaceFirst('Upload ', '')} Doc',
        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600),
      ),
      SizedBox(height: 12.h),
      _uploadButton(
        label: 'Upload',
        fullWidth: true,
        isUploaded: _deedUploaded,
        onTap: () async {
          if (await _pickFile()) setState(() => _deedUploaded = true);
        },
      ),
      SizedBox(height: 24.h),
      Divider(height: 1, color: Colors.grey.shade200),
      SizedBox(height: 24.h),

      // NOC Doc — only when UAE ID Card is selected
      if (_selectedIdType == 'Upload UAE ID Card') ...[
        Text(
          'NOC Doc',
          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),
        _uploadButton(
          label: 'Upload',
          fullWidth: true,
          isUploaded: _nocUploaded,
          onTap: () async {
            if (await _pickFile()) setState(() => _nocUploaded = true);
          },
        ),
      ],
    ];
  }

  // ── Rent layout ──────────────────────────────────────────────
  List<Widget> _rentLayout() {
    return [
      // ID type inline grey dropdown
      _greyDropdown(
        selected: _selectedIdType,
        isOpen: _idDropdownOpen,
        options: _idTypes,
        onToggle: () => setState(() => _idDropdownOpen = !_idDropdownOpen),
        onSelect: (v) => setState(() {
          _selectedIdType = v;
          _idDropdownOpen = false;
        }),
      ),
      SizedBox(height: 16.h),
      Text(
        '${_selectedIdType.replaceFirst('Upload ', '')} Doc',
        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600),
      ),
      SizedBox(height: 12.h),
      Row(
        children: [
          Expanded(
            child: _uploadButton(
              label: 'Front Side',
              isUploaded: _rentIdFrontUploaded,
              onTap: () async {
                if (await _pickFile()) setState(() => _rentIdFrontUploaded = true);
              },
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _uploadButton(
              label: 'Back Side',
              isUploaded: _rentIdBackUploaded,
              onTap: () async {
                if (await _pickFile()) setState(() => _rentIdBackUploaded = true);
              },
            ),
          ),
        ],
      ),
      SizedBox(height: 24.h),
      Divider(height: 1, color: Colors.grey.shade200),
      SizedBox(height: 24.h),

      // Title Deed Doc
      RichText(
        text: TextSpan(
          text: 'Upload Title Deed Doc',
          style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87),
          children: [
            TextSpan(
                text: ' *', style: GoogleFonts.inter(color: Colors.red)),
          ],
        ),
      ),
      SizedBox(height: 12.h),
      _uploadButton(
        label: 'Upload',
        fullWidth: true,
        isUploaded: _rentDeedUploaded,
        onTap: () async {
          if (await _pickFile()) setState(() => _rentDeedUploaded = true);
        },
      ),
    ];
  }

  // ── Golden border dropdown (Sell) ────────────────────────────
  Widget _goldDropdown({
    required String selected,
    required bool isOpen,
    required List<String> options,
    required VoidCallback onToggle,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.primary, width: 1.5),
              borderRadius: isOpen
                  ? BorderRadius.vertical(top: Radius.circular(8.r))
                  : BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: '$selected ',
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, color: Colors.black87),
                      children: [
                        TextSpan(
                            text: '*',
                            style: GoogleFonts.inter(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
                Icon(
                  isOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                  size: 20.sp,
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
                left: BorderSide(color: AppColors.primary, width: 1.5),
                right: BorderSide(color: AppColors.primary, width: 1.5),
                bottom: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(8.r)),
            ),
            child: Column(
              children: options.map((item) {
                final isSelected = selected == item;
                final isLast = options.last == item;
                return InkWell(
                  onTap: () => onSelect(item),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 14.h),
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : null,
                        child: Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                            indent: 16.w,
                            endIndent: 16.w),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Grey border dropdown (Rent) ──────────────────────────────
  Widget _greyDropdown({
    required String selected,
    required bool isOpen,
    required List<String> options,
    required VoidCallback onToggle,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
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
                  child: Text(selected,
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, color: Colors.black87)),
                ),
                Icon(
                  isOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade500,
                  size: 20.sp,
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
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(6.r)),
            ),
            child: Column(
              children: options.map((item) {
                final isSelected = selected == item;
                return InkWell(
                  onTap: () => onSelect(item),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 13.h),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : null,
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color:
                            isSelected ? AppColors.primary : Colors.black87,
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

  Widget _uploadButton({
    required String label,
    bool fullWidth = false,
    bool isUploaded = false,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isUploaded ? Colors.green.shade400 : Colors.grey.shade300,
          ),
          backgroundColor:
              isUploaded ? Colors.green.shade50 : Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.r)),
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        ),
        onPressed: isUploaded ? null : onTap,
        icon: Icon(
          isUploaded ? Icons.check : Icons.cloud_upload_outlined,
          color: isUploaded ? Colors.green.shade600 : AppColors.primary,
          size: 20.sp,
        ),
        label: Text(
          isUploaded ? 'Successfully Upload' : label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: isUploaded ? Colors.green.shade600 : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
