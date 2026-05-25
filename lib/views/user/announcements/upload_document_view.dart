import 'dart:io';
import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class UploadDocumentView extends StatefulWidget {
  final String? propertyFor;
  const UploadDocumentView({super.key, this.propertyFor});

  @override
  State<UploadDocumentView> createState() => _UploadDocumentViewState();
}

class _UploadDocumentViewState extends State<UploadDocumentView> {
  String _selectedIdType = 'Upload UAE ID Card';
  bool _idDropdownOpen = false;
  final _idTypes = ['Upload UAE ID Card', 'Upload Your Passport'];

  String _selectedDeedType = 'Upload Title Deed';
  bool _deedDropdownOpen = false;
  final _deedTypes = ['Upload Title Deed', 'Upload Oqood'];

  bool get _isSell => widget.propertyFor == 'Sell';
  bool _isUploading = false;
  int _uploadedCount = 0;
  int _totalToUpload = 0;
  double get _uploadProgress =>
      _totalToUpload == 0 ? 0 : _uploadedCount / _totalToUpload;

  // Sell
  XFile? _idFrontFile, _idBackFile, _deedFile, _nocFile;
  // Rent
  XFile? _rentIdFrontFile, _rentIdBackFile, _rentDeedFile;
  // Existing URLs from edit mode
  String? _existingFrontUrl, _existingBackUrl, _existingDeedUrl, _existingNocUrl;

  bool get _isValid {
    if (_isSell) {
      return (_idFrontFile != null || _existingFrontUrl != null) &&
          (_idBackFile != null || _existingBackUrl != null) &&
          (_deedFile != null || _existingDeedUrl != null);
    }
    return (_rentIdFrontFile != null || _existingFrontUrl != null) &&
        (_rentIdBackFile != null || _existingBackUrl != null) &&
        (_rentDeedFile != null || _existingDeedUrl != null);
  }

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final c = Get.find<AnnouncementController>();
    _existingFrontUrl = c.passportFrontUrl;
    _existingBackUrl = c.passportBackUrl;
    _existingDeedUrl = c.titleDeedUrl;
    _existingNocUrl = c.nocUrl;
  }

  Future<XFile?> _pickFile() async {
    try {
      return await _picker.pickImage(source: ImageSource.gallery);
    } catch (_) {
      return null;
    }
  }

  Future<void> _uploadAndSave() async {
    int total = 0;
    if (_isSell) {
      if (_idFrontFile != null) total++;
      if (_idBackFile != null) total++;
      if (_deedFile != null) total++;
      if (_nocFile != null) total++;
    } else {
      if (_rentIdFrontFile != null) total++;
      if (_rentIdBackFile != null) total++;
      if (_rentDeedFile != null) total++;
    }
    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
      _totalToUpload = total;
    });
    try {
      Future<String?> uploadIfNew(XFile? file, String? existingUrl) async {
        if (file == null) return existingUrl;
        final url = await api.uploadImage(
            file: File(file.path), fileType: 'announcements');
        if (mounted) setState(() => _uploadedCount++);
        return url;
      }

      String? titleDeedUrl, passportFrontUrl, passportBackUrl, nocUrl;
      if (_isSell) {
        passportFrontUrl = await uploadIfNew(_idFrontFile, _existingFrontUrl);
        passportBackUrl = await uploadIfNew(_idBackFile, _existingBackUrl);
        titleDeedUrl = await uploadIfNew(_deedFile, _existingDeedUrl);
        nocUrl = await uploadIfNew(_nocFile, _existingNocUrl);
      } else {
        passportFrontUrl =
            await uploadIfNew(_rentIdFrontFile, _existingFrontUrl);
        passportBackUrl =
            await uploadIfNew(_rentIdBackFile, _existingBackUrl);
        titleDeedUrl = await uploadIfNew(_rentDeedFile, _existingDeedUrl);
      }

      Get.find<AnnouncementController>().setDocuments(
        titleDeedUrl: titleDeedUrl,
        passportFrontUrl: passportFrontUrl,
        passportBackUrl: passportBackUrl,
        nocUrl: nocUrl,
      );

      // Hold at 100% briefly so user sees completion before navigating back.
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Upload failed. Please try again.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
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
                  onPressed: _isValid && !_isUploading ? _uploadAndSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isValid ? AppColors.primary : Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r)),
                  ),
                  child: Text(
                    _isUploading ? 'Uploading...' : 'SAVE',
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
          ), // SafeArea
          if (_isUploading) _buildUploadOverlay(),
        ],
      ),
    );
  }

  Widget _buildUploadOverlay() {
    final percent = (_uploadProgress * 100).toInt();
    final isDone =
        _totalToUpload == 0 || _uploadedCount >= _totalToUpload;
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: Center(
            child: Container(
              width: 200.w,
              padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 72.w,
                    height: 72.w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72.w,
                          height: 72.w,
                          child: CircularProgressIndicator(
                            value: _totalToUpload == 0 ? null : _uploadProgress,
                            strokeWidth: 7,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                        Text(
                          _totalToUpload == 0 ? '...' : '$percent%',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _totalToUpload == 0
                        ? 'Saving...'
                        : isDone
                            ? 'Upload complete!'
                            : 'Uploading ${_uploadedCount + 1} of $_totalToUpload...',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sell layout ──────────────────────────────────────────────
  List<Widget> _sellLayout() {
    return [
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
              isUploaded: _idFrontFile != null || _existingFrontUrl != null,
              onTap: () async {
                final f = await _pickFile();
                if (f != null) setState(() => _idFrontFile = f);
              },
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _uploadButton(
              label: 'Back Side',
              isUploaded: _idBackFile != null || _existingBackUrl != null,
              onTap: () async {
                final f = await _pickFile();
                if (f != null) setState(() => _idBackFile = f);
              },
            ),
          ),
        ],
      ),
      SizedBox(height: 24.h),
      Divider(height: 1, color: Colors.grey.shade200),
      SizedBox(height: 24.h),

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
        isUploaded: _deedFile != null || _existingDeedUrl != null,
        onTap: () async {
          final f = await _pickFile();
          if (f != null) setState(() => _deedFile = f);
        },
      ),
      SizedBox(height: 24.h),
      Divider(height: 1, color: Colors.grey.shade200),
      SizedBox(height: 24.h),

      if (_selectedIdType == 'Upload UAE ID Card') ...[
        Text(
          'NOC Doc',
          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),
        _uploadButton(
          label: 'Upload',
          fullWidth: true,
          isUploaded: _nocFile != null || _existingNocUrl != null,
          onTap: () async {
            final f = await _pickFile();
            if (f != null) setState(() => _nocFile = f);
          },
        ),
      ],
    ];
  }

  // ── Rent layout ──────────────────────────────────────────────
  List<Widget> _rentLayout() {
    return [
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
              isUploaded: _rentIdFrontFile != null || _existingFrontUrl != null,
              onTap: () async {
                final f = await _pickFile();
                if (f != null) setState(() => _rentIdFrontFile = f);
              },
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _uploadButton(
              label: 'Back Side',
              isUploaded: _rentIdBackFile != null || _existingBackUrl != null,
              onTap: () async {
                final f = await _pickFile();
                if (f != null) setState(() => _rentIdBackFile = f);
              },
            ),
          ),
        ],
      ),
      SizedBox(height: 24.h),
      Divider(height: 1, color: Colors.grey.shade200),
      SizedBox(height: 24.h),

      RichText(
        text: TextSpan(
          text: 'Upload Title Deed Doc',
          style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87),
          children: [
            TextSpan(text: ' *', style: GoogleFonts.inter(color: Colors.red)),
          ],
        ),
      ),
      SizedBox(height: 12.h),
      _uploadButton(
        label: 'Upload',
        fullWidth: true,
        isUploaded: _rentDeedFile != null || _existingDeedUrl != null,
        onTap: () async {
          final f = await _pickFile();
          if (f != null) setState(() => _rentDeedFile = f);
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
                      style:
                          GoogleFonts.inter(fontSize: 14.sp, color: Colors.black87),
                      children: [
                        TextSpan(
                            text: '*',
                            style: GoogleFonts.inter(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8.r)),
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
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color:
                                isSelected ? AppColors.primary : Colors.black87,
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
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : null,
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
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
        onPressed: onTap,
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
