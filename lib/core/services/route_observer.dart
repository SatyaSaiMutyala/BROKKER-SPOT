import 'package:flutter/material.dart';

/// App-wide route observer.
///
/// Lets a screen know when it is uncovered again after a pushed route pops —
/// something `initState` cannot report, since a screen kept alive under a
/// pushed route (or parked in the dashboard's IndexedStack) is never rebuilt
/// from scratch. Screens opt in with `RouteAware` + `didPopNext`.
///
/// Registered once in [GetMaterialApp.navigatorObservers].
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
