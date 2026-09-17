import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/active_dashboard.dart';
import 'package:brokkerspot/views/user/account/account_view.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/views/user/home/home_view.dart';
import 'package:brokkerspot/views/user/meeting/meeting_view.dart';
import 'package:brokkerspot/views/user/wishlist/controller/wishlist_controller.dart';
import 'package:brokkerspot/views/user/wishlist/wishlist_view.dart';
import 'package:brokkerspot/widgets/common/bottom_nav/bottom_nav.dart';
// import 'package:brokkerspot/widgets/common/location_picker_popup.dart';
import 'package:brokkerspot/core/controllers/indicator_controller.dart';
import 'package:brokkerspot/core/services/device_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardView extends StatefulWidget {
  final int initialIndex;
  final bool showLocationPicker;
  const DashboardView(
      {super.key, this.initialIndex = 0, this.showLocationPicker = false});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // Tab order: Home, Meetings, Wishlist, Account. The create button sits
  // between Meetings and Wishlist but is an action, not a tab.
  static const int _accountTab = 3;
  static const int _wishlistTab = 2;
  static const int _meetingsTab = 1;

  /// Tabs a guest cannot open.
  static const Set<int> _loginRequiredTabs = {1, 2};

  late int _currentIndex = widget.initialIndex;

  /// Read through [ActiveDashboard] — by the login prompt, and by guest
  /// requests that need to name the side they are browsing.
  int _activeTab() => _currentIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    ActiveDashboard.register(isBroker: false, currentTab: _activeTab);
    _screens = [
      HomeView(onAccountTap: () => _onNavTap(_accountTab)),
      const MeetingView(),
      const WishlistView(),
      const AccountView(),
    ];
    // Nav badges: one shared controller, live for as long as a dashboard is.
    if (LocalStorageService.isLoggedIn()) {
      IndicatorController.to
        ..startListening()
        ..refresh();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Location picker popup — disabled on request.
      // if (widget.showLocationPicker) {
      //   showDialog(
      //     context: context,
      //     barrierDismissible: false,
      //     builder: (_) => const LocationPickerPopup(),
      //   );
      //   return;
      // }
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      // Prompts only until the user has actually answered it.
      await DeviceService.ensureNotificationPermission();
    });
  }

  @override
  void dispose() {
    ActiveDashboard.unregister(_activeTab);
    super.dispose();
  }

  void _onNavTap(int index) {
    // Meetings and Wishlist require login — guests see the login prompt.
    if (_loginRequiredTabs.contains(index) &&
        !LocalStorageService.isLoggedIn()) {
      showLoginRequiredDialog(context);
      return;
    }
    // Tabs live in an IndexedStack, so their initState runs once at startup
    // and never again on switch — the wishlist has to be re-asked on every
    // open, or it keeps showing whatever it fetched at launch.
    if (index == _wishlistTab) WishlistController.to.reload();
    setState(() => _currentIndex = index);
    // Opening a conversation marks its messages read on the server, so the
    // count is stale the moment the user comes back out of Meetings.
    if (LocalStorageService.isLoggedIn()) IndicatorController.to.refreshSoon();
  }

  void _onCreateTap() {
    if (!LocalStorageService.isLoggedIn()) {
      showLoginRequiredDialog(context);
      return;
    }
    Get.to(() => const CreateAnnouncementView());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Obx(() => AppBottomNavBar(
        destinations: _destinationsWithBadges(
          IndicatorController.to.messagesUnseen.value,
        ),
        currentIndex: _currentIndex,
        onDestinationSelected: _onNavTap,
        centerAction: AppNavCenterAction(
          onTap: _onCreateTap,
          semanticLabel: 'Create announcement',
        ),
      )),
    );
  }

  /// The nav set with the unread count attached to Meetings — the only tab
  /// that carries conversations.
  List<AppNavDestination> _destinationsWithBadges(int messages) => [
        for (var i = 0; i < _navDestinations.length; i++)
          i == _meetingsTab
              ? _navDestinations[i].withBadge(messages)
              : _navDestinations[i],
      ];

  static const _navDestinations = [
    AppNavDestination(
      iconAsset: 'assets/images/home_icon.png',
      activeIconAsset: 'assets/images/home_active.png',
      semanticLabel: 'Home',
    ),
    AppNavDestination(
      iconAsset: 'assets/images/meeting_icon.png',
      activeIconAsset: 'assets/images/meeting_active_icon.png',
      semanticLabel: 'Meetings',
    ),
    AppNavDestination(
      iconAsset: 'assets/images/broker_wishlist_icon.png',
      activeIconAsset: 'assets/images/broker_wishlist_icon1.png',
      semanticLabel: 'Wishlist',
    ),
    AppNavDestination(
      iconAsset: 'assets/images/account_icon.png',
      activeIconAsset: 'assets/images/account_active_icon.png',
      semanticLabel: 'Account',
    ),
  ];
}
