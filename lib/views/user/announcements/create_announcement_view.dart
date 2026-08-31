import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/verification_screen.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_controller.dart';
import 'package:brokkerspot/views/user/announcements/property_information_view.dart';
import 'package:brokkerspot/views/user/announcements/property_location_view.dart';
import 'package:brokkerspot/views/user/announcements/property_price_brokerage_view.dart';
import 'package:brokkerspot/widgets/announcements/form_section_tile.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateAnnouncementView extends StatefulWidget {
  final AnnouncementModel? announcement;
  final bool fromBroker;

  const CreateAnnouncementView({
    super.key,
    this.announcement,
    this.fromBroker = false,
  });

  bool get isEditing => announcement != null;

  @override
  State<CreateAnnouncementView> createState() => _CreateAnnouncementViewState();
}

class _CreateAnnouncementViewState extends State<CreateAnnouncementView> {
  late final AnnouncementController _ctrl;

  String? _brokerProposalLimit;
  String? _propertyFor;
  bool _locationSaved = false;
  bool _informationSaved = false;
  bool _videoImagesSaved = false;
  bool _priceSaved = false;
  bool _documentsSaved = false;
  bool _isSubmitting = false;
  bool _isSavingDraft = false;

  // All three steps are required. The broker-proposal limit is no longer a
  // step — it's asked for on the Announce Now tap.
  bool get _allSectionsDone =>
      _informationSaved &&
      _videoImagesSaved &&
      _locationSaved &&
      _documentsSaved &&
      _priceSaved;

  // 3-step flags.
  List<bool> get _stepFlags => [
        _informationSaved && _videoImagesSaved,
        _locationSaved && _documentsSaved,
        _priceSaved,
      ];

  int get _stepCount => _stepFlags.length;

  int get _completedCount => _stepFlags.where((b) => b).length;

  // 1-indexed display step for "Step X of 3".
  int get _currentStepDisplay => (_completedCount + 1).clamp(1, _stepCount);

  // 0-indexed currently active step (first incomplete).
  int get _activeIndex {
    for (int i = 0; i < _stepFlags.length; i++) {
      if (!_stepFlags[i]) return i;
    }
    return _stepFlags.length - 1; // all done
  }

  @override
  void initState() {
    super.initState();
    _ctrl = Get.isRegistered<AnnouncementController>()
        ? Get.find<AnnouncementController>()
        : Get.put(AnnouncementController());

    if (widget.isEditing) {
      _ctrl.loadFromAnnouncement(widget.announcement!);
      final a = widget.announcement!;
      _propertyFor =
          (a.listingType ?? '').toLowerCase() == 'sell' ? 'Sell' : 'Rent';
      _brokerProposalLimit = a.proposalsLimit?.toString();
      _deriveStepFlags();
    } else {
      _ctrl.loadDraft().then((flags) {
        if (flags != null && mounted) {
          setState(() {
            _propertyFor = flags['propertyFor'] as String?;
            _locationSaved = flags['locationSaved'] as bool? ?? false;
            _informationSaved = flags['informationSaved'] as bool? ?? false;
            _videoImagesSaved = flags['videoImagesSaved'] as bool? ?? false;
            _priceSaved = flags['priceSaved'] as bool? ?? false;
            _documentsSaved = flags['documentsSaved'] as bool? ?? false;
            _brokerProposalLimit = flags['brokerProposalLimit'] as String?;
          });
        }
      });
    }
  }

  /// Marks each step done only if the loaded announcement actually satisfies
  /// that step's own rules.
  ///
  /// Editing used to set all five flags to true unconditionally. That holds
  /// for a published listing — it could not have gone live incomplete — but
  /// not for a draft: one saved after only the first step reopened with all
  /// three steps showing green, and Announce Now enabled over missing data.
  /// Each check below mirrors the matching step screen's own validity getter
  /// against what was actually saved.
  void _deriveStepFlags() {
    final c = _ctrl;
    final isSell = c.listingType == 1;

    // Step 1 — PropertyInformationView covers the details *and* the gallery,
    // and only reports itself valid with at least 8 images (its _isValid and
    // _filledSlotCount). It sets both flags together, so they match here too.
    final step1 = c.listingType != null &&
        (c.propertyType?.trim().isNotEmpty ?? false) &&
        (c.sqft != null || c.sqm != null) &&
        c.bedrooms != null &&
        c.bathrooms != null &&
        c.floor != null &&
        c.totalFloors != null &&
        (c.description?.trim().isNotEmpty ?? false) &&
        // Sell must carry Ready/Off Plan; Off Plan must carry its date.
        (!isSell || c.propertyStatus != null) &&
        (c.propertyStatus != 2 || c.completionDate != null) &&
        c.imageUrls.length >= 8;
    _informationSaved = step1;
    _videoImagesSaved = step1;

    // Step 2 — PropertyLocationView. Documents sit behind the same _isUAE
    // gate it uses, so a non-UAE property is complete on location alone.
    _locationSaved = c.latitude != null &&
        c.longitude != null &&
        (c.country?.trim().isNotEmpty ?? false) &&
        (c.city?.trim().isNotEmpty ?? false) &&
        (c.area?.trim().isNotEmpty ?? false);

    final country = (c.country ?? '').toLowerCase();
    final isUAE = country.contains('uae') ||
        country.contains('united arab emirates') ||
        country.contains('u.a.e');
    _documentsSaved = !isUAE ||
        (c.titleDeedUrl != null &&
            c.passportFrontUrl != null &&
            c.passportBackUrl != null);

    // Step 3 — PropertyPriceBrokerageView: rent also needs a period and an
    // availability date.
    _priceSaved = c.price != null &&
        (isSell || (c.rentPeriod != null && c.availableDate != null));
  }

  @override
  void dispose() {
    if (!widget.isEditing && Get.isRegistered<AnnouncementController>()) {
      Get.delete<AnnouncementController>();
    }
    super.dispose();
  }

  // Local-only save — called after each step completes, no API involved.
  void _saveLocally() {
    if (widget.isEditing) return;
    _ctrl.saveDraft(
      propertyFor: _propertyFor,
      locationSaved: _locationSaved,
      informationSaved: _informationSaved,
      videoImagesSaved: _videoImagesSaved,
      priceSaved: _priceSaved,
      documentsSaved: _documentsSaved,
      brokerProposalLimit: _brokerProposalLimit,
    );
  }

  // Button handler — calls API (status=0 draft, or full announcement if all done).
  Future<void> _saveDraft() async {
    if (widget.isEditing) return;

    final step1Done = _informationSaved && _videoImagesSaved;
    final step2Done = _locationSaved && _documentsSaved;

    // All 3 main steps complete → create full announcement (asking for the
    // proposal limit first, same as Announce Now).
    if (step1Done && step2Done && _priceSaved) {
      _onAnnounceTap();
      return;
    }

    // Always call API with status=0 for draft.
    setState(() => _isSavingDraft = true);
    _ctrl.setProposalsLimit(_proposalLimitValue);
    final success = await _ctrl.createDraftAnnouncement();
    if (!mounted) return;
    setState(() => _isSavingDraft = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Draft saved successfully'
          : (_ctrl.errorMessage.value ?? 'Failed to save draft')),
      backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
    ));
  }

  // ── Leaving mid-creation ──────────────────────────────────────────────────

  /// Anything the user has actually completed and would lose by walking away.
  bool get _hasProgress => _stepFlags.any((done) => done);

  /// Backing out of a half-filled form.
  ///
  /// The form used to keep its own state quietly and hand it back on the next
  /// open, which meant nobody was ever asked what should happen to it. Now the
  /// choice is explicit: keep the work as a real draft, or drop it.
  Future<void> _handleBack() async {
    if (widget.isEditing || !_hasProgress) {
      Get.back();
      return;
    }

    final keep = await _askSaveOrDiscard();
    if (keep == null || !mounted) return; // dismissed — stay on the form

    if (keep) {
      await _saveDraft();
      if (!mounted) return;
    } else {
      // Nothing kept: wipe the in-progress state so it can't reappear here or
      // on the other side.
      _ctrl.resetDraft();
    }
    Get.back();
  }

  /// Returns true to save, false to discard, null if dismissed.
  Future<bool?> _askSaveOrDiscard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Step 1 gates the header's Save Draft too — the server won't take a draft
    // without it, so the choice here is between discarding and staying.
    final canSave = _stepFlags[0];

    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF15181F) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leave this announcement?',
                style: GoogleFonts.poppins(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                canSave
                    ? 'Keep what you have filled in as a draft, or discard it '
                        'and start over next time.'
                    : 'Complete "Property Info" before this can be kept as a '
                        'draft. Leaving now discards what you have filled in.',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w300,
                  height: 1.5,
                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                ),
              ),
              SizedBox(height: 22.h),
              if (canSave) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      'Save in Draft',
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade400 : Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    _ctrl.setProposalsLimit(_proposalLimitValue);

    bool success;
    if (widget.isEditing) {
      success = await _ctrl.editAnnouncement(widget.announcement!.id!);
    } else {
      success = await _ctrl.createAnnouncement();
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      if (widget.isEditing) {
        Get.back(result: true);
      } else {
        Get.to(() => VerificationScreen(
              isAnnouncement: true,
              fromBroker: widget.fromBroker,
            ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ctrl.errorMessage.value ??
            (widget.isEditing
                ? 'Failed to update announcement'
                : 'Failed to create announcement')),
        backgroundColor: Colors.red.shade600,
      ));
    }
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────

  /// Label for the "don't cap proposals" row.
  static const String _noProposalLimit = 'No limit';

  /// What "No limit" actually sends.
  ///
  /// The field used to be omitted entirely, which was the opposite of no
  /// limit: `proposals_limit` defaults to 0 on the announcement, and the
  /// backend rejects a proposal once `totalProposals > proposals_limit` — so
  /// an uncapped listing accepted exactly one. A high ceiling is sent instead.
  static const int _unlimitedProposals = 1000;

  /// The value to send for the current selection — the parsed number, or the
  /// ceiling when the user chose "No limit".
  int? get _proposalLimitValue => _brokerProposalLimit == null
      ? _unlimitedProposals
      : int.tryParse(_brokerProposalLimit!);

  /// Asks for the broker-proposal limit, then runs [onChosen].
  ///
  /// Dismissing without choosing leaves the current value alone and does not
  /// continue, so a stray tap outside the dialog can't publish.
  void _showBrokerProposalLimitDialog({VoidCallback? onChosen}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _showPickerDialog(
      isDark: isDark,
      title: 'Set Broker Proposal Limit',
      subtitle: 'How many brokers may pitch for this listing. '
          'Pick No limit to leave it open.',
      options: [_noProposalLimit, '10', '20', '50', '100', '500'],
      selected: _brokerProposalLimit ?? _noProposalLimit,
      onSelect: (option) {
        final noLimit = option == _noProposalLimit;
        setState(() {
          _brokerProposalLimit = noLimit ? null : option;
        });
        _saveLocally();
        onChosen?.call();
      },
    );
  }

  /// Announce Now / Update: pick the proposal limit first, then submit.
  void _onAnnounceTap() {
    _showBrokerProposalLimitDialog(onChosen: _submit);
  }

  /// Option picker, styled like the My Information edit dialogs so the app
  /// speaks with one voice: titled header, hairline rule, then the choices —
  /// the one already in force carried in gold rather than left to guess at.
  void _showPickerDialog({
    required bool isDark,
    required String title,
    required String subtitle,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    final surface = isDark ? const Color(0xFF15171F) : Colors.white;
    final hairline = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);
    final titleColor = isDark ? Colors.white : const Color(0xFF16181F);
    final subtitleColor =
        isDark ? Colors.grey.shade500 : const Color(0xFF7A7D87);
    final optionColor = isDark ? Colors.white : const Color(0xFF23262E);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 26.w),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: hairline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.14),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w300,
                        height: 1.4,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: hairline),
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((option) {
                    final isActive = option == selected;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () {
                          Navigator.pop(ctx);
                          onSelect(option);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withValues(alpha: 0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.07)
                                      : Colors.black.withValues(alpha: 0.06)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isActive
                                        ? AppColors.primary
                                        : optionColor,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Icon(Icons.check_rounded,
                                    size: 17.sp, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Subtitle helpers ─────────────────────────────────────────────────────────

  String get _locationSubtitle {
    if (!_locationSaved) return '';
    final parts = [_ctrl.city, _ctrl.area]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');
    return parts.isNotEmpty ? parts : 'Location saved';
  }

  String get _step1Subtitle {
    if (!_informationSaved) return '';
    final parts = [
      if (_propertyFor != null) 'For $_propertyFor',
      if (_ctrl.propertyType != null) _ctrl.propertyType!,
      if (_ctrl.sqft != null) '${_ctrl.sqft!.toInt()} sqft',
    ];
    return parts.isNotEmpty ? parts.join('  •  ') : 'Details saved';
  }

  String get _priceSubtitle {
    if (!_priceSaved) return '';
    final price = _ctrl.price;
    if (price == null) return 'Price set';
    final formatted = price
        .toInt()
        .toString()
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return _propertyFor == 'Rent' ? 'AED $formatted / month' : 'AED $formatted';
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final active = _activeIndex;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            CustomHeader(
              title: widget.isEditing
                  ? 'Edit Announcement'
                  : 'Create Announcement',
              showBackButton: true,
              onBack: _handleBack,
              trailing: Builder(builder: (ctx) {
                // Once every section is done there is nothing left to keep as
                // a draft — Announce Now takes over, so Save Draft disappears
                // on exactly the same _allSectionsDone gate that enables it.
                if (_allSectionsDone) return const SizedBox.shrink();
                // Save Draft is only available once step 1 is complete.
                final step1Done = _stepFlags[0];
                final enabled = step1Done && !_isSavingDraft && !_isSubmitting;
                return GestureDetector(
                  onTap: enabled ? _saveDraft : null,
                  child: _isSavingDraft
                      ? SizedBox(
                          width: 14.sp,
                          height: 14.sp,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Text(
                          'Save Draft',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: enabled
                                ? AppColors.primary
                                : Colors.grey.shade400,
                            height: 1.0,
                          ),
                        ),
                );
              }),
            ),

            // ── Step progress ─────────────────────────────────────────────────
            _buildStepProgress(theme, isDark),

            // ── Step tiles ────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    FormSectionTile(
                      stepNumber: 1,
                      title: 'Property Info',
                      subtitle: _step1Subtitle,
                      icon: Icons.home_outlined,
                      isComplete: _informationSaved && _videoImagesSaved,
                      isEnabled: true,
                      isCurrent: active == 0,
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const PropertyInformationView()));
                        if (result == true) {
                          final c = Get.find<AnnouncementController>();
                          setState(() {
                            _informationSaved = true;
                            _videoImagesSaved = true;
                            _propertyFor = c.listingType == 1
                                ? 'Sell'
                                : c.listingType == 2
                                    ? 'Rent'
                                    : null;
                          });
                          _saveLocally();
                        }
                      },
                    ),
                    FormSectionTile(
                      stepNumber: 2,
                      title: 'Property Location and Doc*',
                      subtitle: _locationSubtitle,
                      icon: Icons.location_on_outlined,
                      isComplete: _locationSaved && _documentsSaved,
                      isEnabled: _informationSaved && _videoImagesSaved,
                      isCurrent: active == 1,
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PropertyLocationView()));
                        if (result == true) {
                          setState(() {
                            _locationSaved = true;
                            _documentsSaved = true;
                          });
                          _saveLocally();
                        }
                      },
                    ),
                    FormSectionTile(
                      stepNumber: 3,
                      title: 'Price & Availability',
                      subtitle: _priceSubtitle,
                      icon: Icons.paid_outlined,
                      isComplete: _priceSaved,
                      isEnabled: _locationSaved && _documentsSaved,
                      isCurrent: active == 2,
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PropertyPriceBrokerageView(
                                      propertyFor: _propertyFor,
                                      fromBroker: widget.fromBroker,
                                    )));
                        if (result == true) {
                          setState(() => _priceSaved = true);
                          _saveLocally();
                        }
                      },
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // ── Announce Now button ───────────────────────────────────────────
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  // ── Step progress bar ─────────────────────────────────────────────────────

  Widget _buildStepProgress(ThemeData theme, bool isDark) {
    final greenCount = _completedCount;
    return Container(
      padding: EdgeInsets.fromLTRB(19.w, 12.h, 19.w, 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $_currentStepDisplay of $_stepCount',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              height: 1.0,
            ),
          ),
          SizedBox(height: 8.h),
          // One progress capsule per step
          Row(
            children: List.generate(_stepCount, (i) {
              return Expanded(
                child: Container(
                  height: 3.h,
                  margin: EdgeInsets.only(right: i < _stepCount - 1 ? 4.w : 0),
                  decoration: BoxDecoration(
                    color: i < greenCount
                        ? const Color(0xFF149A35)
                        : const Color(0xFF757575),
                    borderRadius: BorderRadius.circular(26.r),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 6.h),
          Text(
            'Fill in all the details to publish your property',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6F6F6F),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom section: button + note ────────────────────────────────────────

  Widget _buildBottomSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSubmit = _allSectionsDone && !_isSubmitting;
    final disabledColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5);
    final disabledFg = isDark ? Colors.grey.shade600 : Colors.grey.shade500;
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 12.h, 0, 24.h),
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: canSubmit ? _onAnnounceTap : null,
              child: Container(
                width: 286.w,
                height: 51.h,
                decoration: BoxDecoration(
                  color: canSubmit ? AppColors.primary : disabledColor,
                  borderRadius: BorderRadius.circular(38.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      size: 20.sp,
                      color: canSubmit ? Colors.white : disabledFg,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _isSubmitting
                          ? (widget.isEditing ? 'Updating...' : 'Creating...')
                          : (widget.isEditing
                              ? 'Update Announcement'
                              : 'Announce Now'),
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: canSubmit ? Colors.white : disabledFg,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 12.sp, color: Colors.grey.shade400),
              SizedBox(width: 4.w),
              Text(
                'You can review everything before publishing',
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: Colors.grey.shade400,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
