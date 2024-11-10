// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:google_navigation_flutter/google_navigation_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';

// void main() {
//   runApp(const MaterialApp(home: NavigationPage()));
// }

// /// Google Maps Navigation demo page.
// ///
// /// This demo page shows how to use the Google Maps Navigation SDK plugin,
// /// setting navigation destinations, starting and stopping navigation.
// class NavigationPage extends ExamplePage {
//   /// Creates a new navigation demo page widget.
//   const NavigationPage({super.key})
//       : super(leading: const Icon(Icons.navigation), title: 'Navigation');

//   @override
//   ExamplePageState<NavigationPage> createState() => _NavigationPageState();
// }

// /// Local simulation state options.
// enum SimulationState {
//   /// Unknown simulation state. This state is used when navigation is restored,
//   /// and the simulation state is not known.
//   unknown,

//   /// Simulation running.
//   running,

//   /// Simulation running with outdated route.
//   runningOutdated,

//   /// Simulation paused.
//   paused,

//   /// Simulation not running.
//   notRunning,
// }

// /// Navigation demo page state.
// class _NavigationPageState extends ExamplePageState<NavigationPage> {
//   /// If navigation ui is disabled right after navigation session is initialized,
//   /// the routes are not always cleared from the map. This variable is used to
//   /// delay navigation ui disablement to make sure that routes are cleared.
//   static const int _disableNavigationUIDelay = 500;

//   /// Camera location used to initialize the map view on simulator if location
//   /// is not available by the given timeout [_userLocationTimeoutMS].
//   static const LatLng cameraLocationMIT =
//       LatLng(latitude: 42.3601, longitude: -71.094013);
//   static const int _userLocationTimeoutMS = 1500;

//   /// Speed multiplier used for simulation.
//   static const double simulationSpeedMultiplier = 5;

//   /// Navigation view controller used to interact with the navigation view.
//   GoogleNavigationViewController? _navigationViewController;

//   /// Latest user location received from the navigator.
//   LatLng? _userLocation;

//   int _remainingTime = 0;
//   int _remainingDistance = 0;
//   int _onRouteChangedEventCallCount = 0;
//   int _onRoadSnappedLocationUpdatedEventCallCount = 0;
//   int _onRoadSnappedRawLocationUpdatedEventCallCount = 0;
//   int _onTrafficUpdatedEventCallCount = 0;
//   int _onReroutingEventCallCount = 0;
//   int _onGpsAvailabilityEventCallCount = 0;
//   int _onArrivalEventCallCount = 0;
//   int _onSpeedingUpdatedEventCallCount = 0;
//   int _onRecenterButtonClickedEventCallCount = 0;
//   int _onRemainingTimeOrDistanceChangedEventCallCount = 0;
//   int _onNavigationUIEnabledChangedEventCallCount = 0;

//   bool _navigationHeaderEnabled = true;
//   bool _navigationFooterEnabled = true;
//   bool _navigationTripProgressBarEnabled = true;
//   bool _navigationUIEnabled = true;
//   bool _recenterButtonEnabled = true;
//   bool _speedometerEnabled = false;
//   bool _speedLimitIconEnabled = false;
//   bool _trafficIndicentCardsEnabled = false;

//   bool _termsAndConditionsAccepted = false;
//   bool _locationPermissionsAccepted = false;

//   bool _validRoute = false;
//   bool _errorOnSetDestinations = false;
//   bool _navigatorInitialized = false;
//   bool _guidanceRunning = false;
//   bool _showRemainingTimeAndDistanceLabels = false;
//   SimulationState _simulationState = SimulationState.notRunning;

//   // Set the default travel mode to driving (car) and remove options to change it.
//   final NavigationTravelMode _travelMode = NavigationTravelMode.driving;
//   final List<NavigationWaypoint> _waypoints = <NavigationWaypoint>[];

//   /// If true, route tokens and Routes API are used to calculate the route.
//   bool _routeTokensEnabled = false;

//   /// Used to track if navigator has been initialized at least once.
//   /// In this example app navigator can be cleaned up and re-initialized.
//   /// This variable is used to make sure that navigator is initialized before
//   /// showing the navigation view.
//   bool _navigatorInitializedAtLeastOnce = false;

//   /// Event subscriptions need to be stored to be able to cancel them.
//   StreamSubscription<SpeedingUpdatedEvent>? _speedUpdatedSubscription;
//   StreamSubscription<OnArrivalEvent>? _onArrivalSubscription;
//   StreamSubscription<void>? _onReRoutingSubscription;
//   StreamSubscription<void>? _onGpsAvailabilitySubscription;
//   StreamSubscription<void>? _trafficUpdatedSubscription;
//   StreamSubscription<void>? _onRouteChangedSubscription;
//   StreamSubscription<RemainingTimeOrDistanceChangedEvent>?
//       _remainingTimeOrDistanceChangedSubscription;
//   StreamSubscription<RoadSnappedLocationUpdatedEvent>?
//       _roadSnappedLocationUpdatedSubscription;
//   StreamSubscription<RoadSnappedRawLocationUpdatedEvent>?
//       _roadSnappedRawLocationUpdatedSubscription;

//   int _nextWaypointIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     unawaited(_initialize());
//   }

//   @override
//   void dispose() {
//     _clearListeners();
//     GoogleMapsNavigator.cleanup();
//     clearRegisteredImages();
//     super.dispose();
//   }

//   Future<void> _initialize() async {
//     // Check if terms and conditions have been accepted and show dialog if not.
//     await _showTermsAndConditionsDialogIfNeeded();

//     // Check if location permissions have been accepted and show dialog if not.
//     await _askLocationPermissionsIfNeeded();

//     // Initilize navigator if terms and conditions and location permissions
//     // have been accepted.
//     if (_termsAndConditionsAccepted && _locationPermissionsAccepted) {
//       await _initializeNavigator();
//     }
//   }

//   Future<void> _setRouteTokensEnabled(bool value) async {
//     setState(() {
//       // Route tokens are only supported for the driving mode in this example app.
//       _validRoute = false;
//       _routeTokensEnabled = value;
//     });
//     final bool success = await _updateNavigationDestinations();
//     if (success) {
//       setState(() {
//         _validRoute = true;
//       });
//     }
//   }

//   Future<void> _initializeNavigator() async {
//     assert(_termsAndConditionsAccepted, 'Terms must be accepted');
//     assert(
//         _locationPermissionsAccepted, 'Location permissions must be granted');

//     if (!_navigatorInitialized) {
//       debugPrint('Initializing new navigation session...');
//       await GoogleMapsNavigator.initializeNavigationSession();
//       await _setupListeners();
//       await _updateNavigatorInitializationState();
//       await _restorePossibleNavigatorState();
//       unawaited(_setDefaultUserLocationAfterDelay());
//       debugPrint('Navigator has been initialized: $_navigatorInitialized');
//     }
//     setState(() {});
//   }

//   /// iOS emulator does not update location and does not fire roadsnapping
//   /// events. Initialize user location to [cameraLocationMIT] if user
//   /// location is not available after timeout.
//   Future<void> _setDefaultUserLocationAfterDelay() async {
//     Future<void>.delayed(const Duration(milliseconds: _userLocationTimeoutMS),
//         () async {
//       if (mounted && _userLocation == null) {
//         _userLocation = await _navigationViewController?.getMyLocation() ??
//             cameraLocationMIT;
//         if (mounted) {
//           setState(() {});
//         }
//       }
//     });
//   }

//   // Navigator state is not persisted between app restarts, so we need to check
//   // if there is a valid route and guidance running, and restore the state.
//   Future<void> _restorePossibleNavigatorState() async {
//     if (_navigatorInitialized) {
//       final List<NavigationWaypoint> waypoints = await _getWaypoints();

//       // Restore local waypoint index
//       if (waypoints.isNotEmpty) {
//         final List<String> parts = waypoints.last.title.split(' ');
//         if (parts.length == 2) {
//           _nextWaypointIndex = int.tryParse(parts.last) ?? 0;
//         }

//         _validRoute = true;
//         _waypoints.clear();
//         _waypoints.addAll(waypoints);
//       }

//       _guidanceRunning = await GoogleMapsNavigator.isGuidanceRunning();
//       if (_guidanceRunning) {
//         // Guidance is running, but there is currently no way to check if
//         // simulation is running as well, so we set it's state as unknown.
//         _simulationState = SimulationState.unknown;
//       }

//       setState(() {});
//     }
//   }

//   // Helper function to update local waypoint data from the navigation session.
//   Future<List<NavigationWaypoint>> _getWaypoints() async {
//     assert(_navigatorInitialized);
//     final List<RouteSegment> routeSegments =
//         await GoogleMapsNavigator.getRouteSegments();
//     return routeSegments
//         .where((RouteSegment e) => e.destinationWaypoint != null)
//         .map((RouteSegment e) => e.destinationWaypoint!)
//         .toList();
//   }

//   Future<void> _showTermsAndConditionsDialogIfNeeded() async {
//     _termsAndConditionsAccepted = await requestTermsAndConditionsAcceptance();
//     setState(() {});
//   }

//   Future<void> _askLocationPermissionsIfNeeded() async {
//     _locationPermissionsAccepted = await requestLocationDialogAcceptance();
//     setState(() {});
//   }

//   Future<void> _updateNavigatorInitializationState() async {
//     _navigatorInitialized = await GoogleMapsNavigator.isInitialized();
//     if (_navigatorInitialized) {
//       _navigatorInitializedAtLeastOnce = true;
//     }
//     setState(() {});
//   }

//   Future<void> _updateTermsAcceptedState() async {
//     _termsAndConditionsAccepted = await GoogleMapsNavigator.areTermsAccepted();
//     setState(() {});
//   }

//   Future<void> _setupListeners() async {
//     // Clear old listeners to make sure we subscribe to each event only once.
//     _clearListeners();
//     _speedUpdatedSubscription =
//         GoogleMapsNavigator.setSpeedingUpdatedListener(_onSpeedingUpdatedEvent);
//     _onArrivalSubscription =
//         GoogleMapsNavigator.setOnArrivalListener(_onArrivalEvent);
//     _onReRoutingSubscription =
//         GoogleMapsNavigator.setOnReroutingListener(_onReroutingEvent);
//     _onGpsAvailabilitySubscription =
//         await GoogleMapsNavigator.setOnGpsAvailabilityListener(
//             _onGpsAvailabilityEvent);
//     _trafficUpdatedSubscription =
//         GoogleMapsNavigator.setTrafficUpdatedListener(_onTrafficUpdatedEvent);
//     _onRouteChangedSubscription =
//         GoogleMapsNavigator.setOnRouteChangedListener(_onRouteChangedEvent);
//     _remainingTimeOrDistanceChangedSubscription =
//         GoogleMapsNavigator.setOnRemainingTimeOrDistanceChangedListener(
//             _onRemainingTimeOrDistanceChangedEvent,
//             remainingTimeThresholdSeconds: 60,
//             remainingDistanceThresholdMeters: 100);
//     _roadSnappedLocationUpdatedSubscription =
//         await GoogleMapsNavigator.setRoadSnappedLocationUpdatedListener(
//             _onRoadSnappedLocationUpdatedEvent);
//     _roadSnappedRawLocationUpdatedSubscription =
//         await GoogleMapsNavigator.setRoadSnappedRawLocationUpdatedListener(
//             _onRoadSnappedRawLocationUpdatedEvent);
//   }

//   void _clearListeners() {
//     _speedUpdatedSubscription?.cancel();
//     _speedUpdatedSubscription = null;

//     _onArrivalSubscription?.cancel();
//     _onArrivalSubscription = null;

//     _onReRoutingSubscription?.cancel();
//     _onReRoutingSubscription = null;

//     _onGpsAvailabilitySubscription?.cancel();
//     _onGpsAvailabilitySubscription = null;

//     _trafficUpdatedSubscription?.cancel();
//     _trafficUpdatedSubscription = null;

//     _onRouteChangedSubscription?.cancel();
//     _onRouteChangedSubscription = null;

//     _remainingTimeOrDistanceChangedSubscription?.cancel();
//     _remainingTimeOrDistanceChangedSubscription = null;

//     _roadSnappedLocationUpdatedSubscription?.cancel();
//     _roadSnappedLocationUpdatedSubscription = null;

//     _roadSnappedRawLocationUpdatedSubscription?.cancel();
//     _roadSnappedRawLocationUpdatedSubscription = null;
//   }

//   void _onRoadSnappedLocationUpdatedEvent(
//       RoadSnappedLocationUpdatedEvent event) {
//     if (!mounted) {
//       return;
//     }

//     setState(() {
//       _userLocation = event.location;
//       _onRoadSnappedLocationUpdatedEventCallCount += 1;
//     });
//   }

//   // Note: Raw location updates are not available on iOS.
//   void _onRoadSnappedRawLocationUpdatedEvent(
//       RoadSnappedRawLocationUpdatedEvent event) {
//     if (!mounted) {
//       return;
//     }

//     setState(() {
//       _userLocation = event.location;
//       _onRoadSnappedRawLocationUpdatedEventCallCount += 1;
//     });
//   }

//   void _onRemainingTimeOrDistanceChangedEvent(
//       RemainingTimeOrDistanceChangedEvent event) {
//     if (!mounted) {
//       return;
//     }
//     setState(() {
//       _remainingDistance = event.remainingDistance.toInt();
//       _remainingTime = event.remainingTime.toInt();
//       _onRemainingTimeOrDistanceChangedEventCallCount += 1;
//     });
//   }

//   void _onRouteChangedEvent() {
//     if (!mounted) {
//       return;
//     }
//     if (_simulationState == SimulationState.running) {
//       _simulationState = SimulationState.runningOutdated;
//     }
//     setState(() {
//       _onRouteChangedEventCallCount += 1;
//     });
//   }

//   void _onTrafficUpdatedEvent() {
//     setState(() {
//       _onTrafficUpdatedEventCallCount += 1;
//     });
//   }

//   void _onReroutingEvent() {
//     setState(() {
//       _onReroutingEventCallCount += 1;
//     });
//   }

//   void _onGpsAvailabilityEvent(GpsAvailabilityUpdatedEvent event) {
//     setState(() {
//       _onGpsAvailabilityEventCallCount += 1;
//     });
//   }

//   void _onArrivalEvent(
//     OnArrivalEvent event,
//   ) {
//     if (!mounted) {
//       return;
//     }
//     _arrivedToWaypoint(event.waypoint);
//     setState(() {
//       _onArrivalEventCallCount += 1;
//     });
//   }

//   void _onSpeedingUpdatedEvent(
//     SpeedingUpdatedEvent event,
//   ) {
//     if (!mounted) {
//       return;
//     }
//     setState(() {
//       _onSpeedingUpdatedEventCallCount += 1;
//     });
//   }

//   Future<void> _onViewCreated(GoogleNavigationViewController controller) async {
//     setState(() {
//       _navigationViewController = controller;
//     });
//     await controller.setMyLocationEnabled(true);

//     if (_guidanceRunning) {
//       // Guidance is running, enable navigation UI.
//       await _startGuidedNavigation();
//     }

//     await _getInitialViewStates();
//   }

//   Future<void> _getInitialViewStates() async {
//     assert(_navigationViewController != null);
//     if (_navigationViewController != null) {
//       final bool navigationHeaderEnabled =
//           await _navigationViewController!.isNavigationHeaderEnabled();
//       final bool navigationFooterEnabled =
//           await _navigationViewController!.isNavigationFooterEnabled();
//       final bool navigationTripProgressBarEnabled =
//           await _navigationViewController!.isNavigationTripProgressBarEnabled();
//       final bool navigationUIEnabled =
//           await _navigationViewController!.isNavigationUIEnabled();
//       final bool recenterButtonEnabled =
//           await _navigationViewController!.isRecenterButtonEnabled();
//       final bool speedometerEnabled =
//           await _navigationViewController!.isSpeedometerEnabled();
//       final bool speedLimitIconEnabled =
//           await _navigationViewController!.isSpeedLimitIconEnabled();
//       final bool trafficIndicentCardsEnabled =
//           await _navigationViewController!.isTrafficIncidentCardsEnabled();

//       setState(() {
//         _navigationHeaderEnabled = navigationHeaderEnabled;
//         _navigationFooterEnabled = navigationFooterEnabled;
//         _navigationTripProgressBarEnabled = navigationTripProgressBarEnabled;
//         _navigationUIEnabled = navigationUIEnabled;
//         _recenterButtonEnabled = recenterButtonEnabled;
//         _speedometerEnabled = speedometerEnabled;
//         _speedLimitIconEnabled = speedLimitIconEnabled;
//         _trafficIndicentCardsEnabled = trafficIndicentCardsEnabled;
//       });
//     }
//   }

//   void _onRecenterButtonClickedEvent(
//       NavigationViewRecenterButtonClickedEvent msg) {
//     setState(() {
//       _onRecenterButtonClickedEventCallCount += 1;
//     });
//   }

//   void _onNavigationUIEnabledChanged(bool enabled) {
//     if (mounted) {
//       setState(() {
//         _navigationUIEnabled = enabled;
//         _onNavigationUIEnabledChangedEventCallCount += 1;
//       });
//     }
//   }

//   Future<void> _startGuidedNavigation() async {
//     assert(_navigationViewController != null);
//     if (!_navigatorInitialized) {
//       await _initializeNavigator();
//     }
//     await _navigationViewController?.setNavigationUIEnabled(true);
//     await _startGuidance();
//     await _navigationViewController?.followMyLocation(CameraPerspective.tilted);
//   }

//   Future<void> _stopGuidedNavigation() async {
//     assert(_navigationViewController != null);

//     // Cleanup navigation session.
//     // This will also clear destinations, stop simulation, stop guidance
//     await GoogleMapsNavigator.cleanup();
//     await _removeNewWaypointMarker();
//     await _removeDestinationWaypointMarkers();
//     _waypoints.clear();

//     // Reset navigation perspective to top down north up.
//     await _navigationViewController!
//         .followMyLocation(CameraPerspective.topDownNorthUp);

//     // Disable navigation UI after small delay to make sure routes are cleared.
//     // On Android routes are not always created on the map, if navigation UI is
//     // disabled right after cleanup.
//     unawaited(Future<void>.delayed(
//         const Duration(milliseconds: _disableNavigationUIDelay), () async {
//       await _navigationViewController!.setNavigationUIEnabled(false);
//     }));

//     // Make sure that navigation initialization state is up-to-date.
//     await _updateNavigatorInitializationState();

//     // On navigator cleanup simulation is stopped as well, update the state.
//     setState(() {
//       _validRoute = false;
//       _guidanceRunning = false;
//       _simulationState = SimulationState.notRunning;
//       _nextWaypointIndex = 0;
//       _remainingDistance = 0;
//       _remainingTime = 0;
//     });
//   }

//   Marker? _newWaypointMarker;
//   final List<Marker> _destinationWaypointMarkers = <Marker>[];

//   MarkerOptions _buildNewWaypointMarkerOptions(LatLng target) {
//     return MarkerOptions(
//         infoWindow: const InfoWindow(title: 'Destination'),
//         position:
//             LatLng(latitude: target.latitude, longitude: target.longitude));
//   }

//   Future<void> _updateNewWaypointMarker(LatLng target) async {
//     final MarkerOptions markerOptions = _buildNewWaypointMarkerOptions(target);
//     if (_newWaypointMarker == null) {
//       // Add new marker.
//       final List<Marker?> addedMarkers = await _navigationViewController!
//           .addMarkers(<MarkerOptions>[markerOptions]);
//       if (addedMarkers.first != null) {
//         _newWaypointMarker = addedMarkers.first;
//       } else {
//         showMessage('Error while adding destination marker');
//       }
//     } else {
//       // Update existing marker.
//       final Marker updatedWaypointMarker =
//           _newWaypointMarker!.copyWith(options: markerOptions);
//       final List<Marker?> updatedMarkers = await _navigationViewController!
//           .updateMarkers(<Marker>[updatedWaypointMarker]);
//       if (updatedMarkers.first != null) {
//         _newWaypointMarker = updatedMarkers.first;
//       } else {
//         showMessage('Error while updating destination marker');
//       }
//     }
//     setState(() {});
//   }

//   Future<void> _removeNewWaypointMarker() async {
//     if (_newWaypointMarker != null) {
//       await _navigationViewController!
//           .removeMarkers(<Marker>[_newWaypointMarker!]);
//       _newWaypointMarker = null;
//       setState(() {});
//     }
//   }

//   Future<void> _removeDestinationWaypointMarkers() async {
//     if (_destinationWaypointMarkers.isNotEmpty) {
//       await _navigationViewController!
//           .removeMarkers(_destinationWaypointMarkers);
//       _destinationWaypointMarkers.clear();

//       // Unregister custom marker images
//       await clearRegisteredImages();
//       setState(() {});
//     }
//   }

//   Future<void> _onMapClicked(LatLng location) async {
//     await _updateNewWaypointMarker(location);
//   }

//   Future<void> _addWaypoint() async {
//     if (_newWaypointMarker != null) {
//       setState(() {
//         _validRoute = false;
//       });
//       _nextWaypointIndex += 1;
//       _waypoints.add(NavigationWaypoint.withLatLngTarget(
//         title: 'Waypoint $_nextWaypointIndex',
//         target: LatLng(
//           latitude: _newWaypointMarker!.options.position.latitude,
//           longitude: _newWaypointMarker!.options.position.longitude,
//         ),
//       ));

//       // Convert new waypoint marker to destination marker.
//       await _convertNewWaypointMarkerToDestinationMarker(_nextWaypointIndex);
//       await _updateNavigationDestinationsAndNavigationViewState();
//     }
//     setState(() {});
//   }

//   /// Helper method that first updates destinations and then
//   /// updates navigation view state to show the route overview.
//   Future<void> _updateNavigationDestinationsAndNavigationViewState() async {
//     final bool success = await _updateNavigationDestinations();
//     if (success) {
//       await _navigationViewController!.setNavigationUIEnabled(true);

//       if (!_guidanceRunning) {
//         await _navigationViewController!.showRouteOverview();
//       }
//       setState(() {
//         _validRoute = true;
//       });
//     }
//   }

//   Future<void> _convertNewWaypointMarkerToDestinationMarker(
//       final int index) async {
//     final String title = 'Waypoint $index';
//     final ImageDescriptor waypointMarkerImage =
//         await registerWaypointMarkerImage(
//             index, MediaQuery.of(context).devicePixelRatio);
//     final List<Marker?> destinationMarkers =
//         await _navigationViewController!.updateMarkers(<Marker>[
//       _newWaypointMarker!.copyWith(
//         options: _newWaypointMarker!.options.copyWith(
//           infoWindow: InfoWindow(title: title),
//           anchor: const MarkerAnchor(u: 0.5, v: 1.2),
//           icon: waypointMarkerImage,
//         ),
//       )
//     ]);
//     _destinationWaypointMarkers.add(destinationMarkers.first!);
//     _newWaypointMarker = null;
//   }

//   Future<void> showCalculatingRouteMessage() async {
//     await Future<void>.delayed(const Duration(seconds: 1));
//     if (!_validRoute) {
//       showMessage('Calculating the route.');
//     }
//   }

//   /// This method is called by the _onArrivalEvent event handler when the user
//   /// has arrived to a waypoint.
//   Future<void> _arrivedToWaypoint(NavigationWaypoint waypoint) async {
//     debugPrint('Arrived to waypoint: ${waypoint.title}');

//     // Remove the first waypoint from the list.
//     if (_waypoints.isNotEmpty) {
//       _waypoints.removeAt(0);
//     }
//     // Remove the first destination marker from the list.
//     if (_destinationWaypointMarkers.isNotEmpty) {
//       final Marker markerToRemove = _destinationWaypointMarkers.first;
//       await _navigationViewController!.removeMarkers(<Marker>[markerToRemove]);

//       // Unregister custom marker image.
//       await unregisterImage(markerToRemove.options.icon);

//       _destinationWaypointMarkers.removeAt(0);
//     }

//     await GoogleMapsNavigator.continueToNextDestination();

//     if (_waypoints.isEmpty) {
//       debugPrint('Arrived to last waypoint, stopping navigation.');

//       // If there is no next waypoint, it means we have arrived at the last
//       // destination. Hence, stop navigation.
//       await _stopGuidedNavigation();
//     }

//     setState(() {});
//   }

//   Future<void> _clearNavigationWaypoints() async {
//     // Stopping guided navigation will also clear the waypoints.
//     await _stopGuidedNavigation();
//     setState(() {
//       _waypoints.clear();
//     });
//   }

//   Future<bool> _updateNavigationDestinations() async {
//     if (_navigationViewController == null || _waypoints.isEmpty) {
//       return false;
//     }

//     if (!_navigatorInitialized) {
//       await _initializeNavigator();
//     }

//     // If route tokens are enabled, build destinations with route tokens.
//     final Destinations? destinations = _routeTokensEnabled
//         ? (await _buildDestinationsWithRoutesApi())
//         : _buildDestinations();

//     if (destinations == null) {
//       // Failed to build destinations.
//       // This can happen if route tokens are enabled and route token could
//       // not be fetched.
//       setState(() {
//         _errorOnSetDestinations = true;
//       });
//       return false;
//     }

//     try {
//       final NavigationRouteStatus navRouteStatus =
//           await GoogleMapsNavigator.setDestinations(destinations);

//       switch (navRouteStatus) {
//         case NavigationRouteStatus.statusOk:
//           // Route is valid. Return true as success.
//           setState(() {
//             _errorOnSetDestinations = false;
//           });
//           return true;
//         case NavigationRouteStatus.internalError:
//           showMessage(
//               'Unexpected internal error occured. Please restart the app.');
//         case NavigationRouteStatus.routeNotFound:
//           showMessage('The route could not be calculated.');
//         case NavigationRouteStatus.networkError:
//           showMessage(
//               'Working network connection is required to calculate the route.');
//         case NavigationRouteStatus.quotaExceeded:
//           showMessage('Insufficient API quota to use the navigation.');
//         case NavigationRouteStatus.quotaCheckFailed:
//           showMessage(
//               'API quota check failed, cannot authorize the navigation.');
//         case NavigationRouteStatus.apiKeyNotAuthorized:
//           showMessage('A valid API key is required to use the navigation.');
//         case NavigationRouteStatus.statusCanceled:
//           showMessage(
//               'The route calculation was canceled in favor of a newer one.');
//         case NavigationRouteStatus.duplicateWaypointsError:
//           showMessage(
//               'The route could not be calculated because of duplicate waypoints.');
//         case NavigationRouteStatus.noWaypointsError:
//           showMessage(
//               'The route could not be calculated because no waypoints were provided.');
//         case NavigationRouteStatus.locationUnavailable:
//           showMessage(
//               'No user location is available. Did you allow location permission?');
//         case NavigationRouteStatus.waypointError:
//           showMessage('Invalid waypoints provided.');
//         case NavigationRouteStatus.travelModeUnsupported:
//           showMessage(
//               'The route could not calculated for the given travel mode.');
//         case NavigationRouteStatus.unknown:
//           showMessage(
//               'The route could not be calculated due to an unknown error.');
//         case NavigationRouteStatus.locationUnknown:
//           showMessage(
//               'The route could not be calculated, because the user location is unknown.');
//       }
//     } on RouteTokenMalformedException catch (_) {
//       showMessage('Malformed route token');
//     } on SessionNotInitializedException catch (_) {
//       showMessage('Cannot set destinations, session not initialized');
//     }
//     setState(() {
//       _errorOnSetDestinations = true;
//     });
//     return false;
//   }

//   /// Helper function to retry setting navigation settings if there was an error
//   /// on the previous attempt. Sometimes the error is transient and retrying
//   /// the operation can succeed, for example in situations where device location
//   /// is not yet available.
//   Future<void> _retryToUpdateNavigationDestinations() async {
//     setState(() {
//       _errorOnSetDestinations = false;
//     });
//     await _updateNavigationDestinationsAndNavigationViewState();
//   }

//   Destinations? _buildDestinations() {
//     // Show delayed calculating route message.
//     unawaited(showCalculatingRouteMessage());

//     return Destinations(
//       waypoints: _waypoints,
//       displayOptions: NavigationDisplayOptions(
//         showDestinationMarkers: false,
//         showStopSigns: true,
//         showTrafficLights: true,
//       ),
//       routingOptions: RoutingOptions(travelMode: _travelMode),
//     );
//   }

//   Future<Destinations?> _buildDestinationsWithRoutesApi() async {
//     assert(_routeTokensEnabled);

//     showMessage('Using route token from Routes API.');

//     List<String> routeTokens = <String>[];
//     try {
//       routeTokens = await getRouteToken(
//         <NavigationWaypoint>[
//           // Add users location as start location for getting routetoken.
//           NavigationWaypoint.withLatLngTarget(
//               title: 'Origin', target: _userLocation),
//           ..._waypoints,
//         ],
//       );
//     } catch (e) {
//       showMessage('Failed to get route tokens from Routes API. $e');
//       return null;
//     }

//     if (routeTokens.isEmpty) {
//       showMessage('Failed to get route tokens from Routes API.');
//       return null;
//     } else if (routeTokens.length > 1) {
//       showMessage(
//           'More than one route token received from Routes API. Using the first one.');
//     }

//     return Destinations(
//         waypoints: _waypoints,
//         displayOptions: NavigationDisplayOptions(showDestinationMarkers: false),
//         routeTokenOptions: RouteTokenOptions(
//           routeToken: routeTokens.first, // Uses first fetched route token.
//           travelMode: _travelMode,
//         ));
//   }

//   Future<void> _startGuidance() async {
//     await GoogleMapsNavigator.startGuidance();
//     setState(() {
//       _guidanceRunning = true;
//     });
//   }

//   Future<void> _stopGuidance() async {
//     await GoogleMapsNavigator.stopGuidance();
//     setState(() {
//       _guidanceRunning = false;
//     });
//   }

//   Future<void> _showNativeNavigatorState() async {
//     if (await GoogleMapsNavigator.isInitialized()) {
//       showMessage('Navigator initialized');
//     } else {
//       showMessage('Navigator not inititalized');
//     }
//   }

//   Future<void> _startSimulation() async {
//     if (_waypoints.isNotEmpty) {
//       final LatLng? myLocation =
//           _userLocation ?? await _navigationViewController!.getMyLocation();
//       if (myLocation != null) {
//         await GoogleMapsNavigator.simulator.setUserLocation(myLocation);
//       }

//       await GoogleMapsNavigator.simulator
//           .simulateLocationsAlongExistingRouteWithOptions(
//         SimulationOptions(speedMultiplier: simulationSpeedMultiplier),
//       );

//       setState(() {
//         _simulationState = SimulationState.running;
//       });
//     }
//   }

//   Future<void> _stopSimulation() async {
//     await GoogleMapsNavigator.simulator.removeUserLocation();
//     setState(() {
//       _simulationState = SimulationState.notRunning;
//     });
//   }

//   Future<void> _pauseSimulation() async {
//     await GoogleMapsNavigator.simulator.pauseSimulation();
//     setState(() {
//       _simulationState = SimulationState.paused;
//     });
//   }

//   Future<void> _resumeSimulation() async {
//     assert(_simulationState == SimulationState.paused);
//     await GoogleMapsNavigator.simulator.resumeSimulation();
//     setState(() {
//       _simulationState = SimulationState.running;
//     });
//   }

//   Future<void> _resetTOS() async {
//     await GoogleMapsNavigator.resetTermsAccepted();
//     await _updateTermsAcceptedState();
//   }

//   Future<void> _displayRouteSegments() async {
//     final List<RouteSegment> segments =
//         await GoogleMapsNavigator.getRouteSegments();
//     showMessage('Route segments amount: ${segments.length}');
//   }

//   Future<void> _displayTraveledRoute() async {
//     final List<LatLng> route = await GoogleMapsNavigator.getTraveledRoute();
//     showMessage('Traveled route segment points: ${route.length}');
//   }

//   Future<void> _displayCurrentRouteSegment() async {
//     final RouteSegment? segment =
//         await GoogleMapsNavigator.getCurrentRouteSegment();
//     showMessage(
//         'Current route segment destination: ${segment?.destinationWaypoint?.title ?? 'unknown'}');
//   }

//   @override
//   Widget build(BuildContext context) => buildPage(
//       context,
//       (BuildContext context) => Padding(
//           padding: EdgeInsets.zero,
//           child: Stack(
//             children: <Widget>[
//               Column(children: <Widget>[
//                 // Removed the travel mode selection widget
//                 Expanded(
//                   child: _navigatorInitializedAtLeastOnce &&
//                           _userLocation != null
//                       ? GoogleMapsNavigationView(
//                           onViewCreated: _onViewCreated,
//                           onMapClicked: _onMapClicked,
//                           onMapLongClicked: _onMapClicked,
//                           onRecenterButtonClicked:
//                               _onRecenterButtonClickedEvent,
//                           onNavigationUIEnabledChanged:
//                               _onNavigationUIEnabledChanged,
//                           initialCameraPosition: CameraPosition(
//                             // Initialize map to user location.
//                             target: _userLocation!,
//                             zoom: 15,
//                           ),
//                           initialNavigationUIEnabledPreference: _guidanceRunning
//                               ? NavigationUIEnabledPreference.automatic
//                               : NavigationUIEnabledPreference.disabled,
//                         )
//                       : const Center(
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: <Widget>[
//                               Text('Waiting navigator and user location'),
//                               SizedBox(height: 10),
//                               SizedBox(
//                                   width: 30,
//                                   height: 30,
//                                   child: CircularProgressIndicator())
//                             ],
//                           ),
//                         ),
//                 ),
//                 if (_navigationViewController != null) bottomControls
//               ]),
//               if (_showRemainingTimeAndDistanceLabels)
//                 _createRemainingTimeAndDistanceLabels()
//             ],
//           )));

//   Widget get bottomControls {
//     if (!_termsAndConditionsAccepted || !_locationPermissionsAccepted) {
//       return Padding(
//           padding: const EdgeInsets.all(15),
//           child: Wrap(
//               alignment: WrapAlignment.center,
//               spacing: 10,
//               children: <Widget>[
//                 const Text(
//                     'Terms and conditions and location permissions must be accepted'
//                     ' before navigation can be started.'),
//                 getOptionsButton(context, onPressed: () => toggleOverlay())
//               ]));
//     }
//     if (!_navigatorInitializedAtLeastOnce) {
//       return const Text('Waiting for navigator to initialize...');
//     }
//     return Padding(
//       padding: const EdgeInsets.all(15),
//       child: Column(
//         children: <Widget>[
//           if (_errorOnSetDestinations && _waypoints.isNotEmpty) ...<Widget>[
//             const Text('Error while setting destinations'),
//             ElevatedButton(
//               onPressed: _retryToUpdateNavigationDestinations,
//               child: const Text('Retry'),
//             ),
//           ],
//           if (_guidanceRunning &&
//               _simulationState == SimulationState.runningOutdated)
//             Wrap(
//                 alignment: WrapAlignment.center,
//                 spacing: 10,
//                 children: <Widget>[
//                   const Text('Simulation is running with outdated route'),
//                   ElevatedButton(
//                     onPressed: () => _startSimulation(),
//                     child: const Text('Update simulation'),
//                   ),
//                 ]),
//           if (_waypoints.isNotEmpty)
//             Wrap(
//               alignment: WrapAlignment.center,
//               spacing: 10,
//               children: <Widget>[
//                 if (!_guidanceRunning)
//                   ElevatedButton(
//                     onPressed: _validRoute ? _startGuidedNavigation : null,
//                     child: const Text('Start Guidance'),
//                   ),
//                 if (_guidanceRunning)
//                   ElevatedButton(
//                     onPressed: _validRoute ? _stopGuidedNavigation : null,
//                     child: const Text('Stop Guidance'),
//                   ),
//                 if (_guidanceRunning &&
//                     _simulationState == SimulationState.notRunning)
//                   ElevatedButton(
//                     onPressed: () => _startSimulation(),
//                     child: const Text('Start simulation'),
//                   ),
//                 if (_guidanceRunning &&
//                     _simulationState == SimulationState.unknown)
//                   ElevatedButton(
//                     onPressed: () => _startSimulation(),
//                     child: const Text('Resume simulation state'),
//                   ),
//                 if (_guidanceRunning &&
//                     (_simulationState == SimulationState.running ||
//                         _simulationState == SimulationState.runningOutdated ||
//                         _simulationState == SimulationState.paused))
//                   ElevatedButton(
//                     onPressed: () => _stopSimulation(),
//                     child: const Text('Stop simulation'),
//                   ),
//               ],
//             ),
//           if (_waypoints.isEmpty)
//             const Padding(
//               padding: EdgeInsets.all(15),
//               child: Text('Click on the map to add waypoints'),
//             ),
//           Wrap(
//             alignment: WrapAlignment.center,
//             spacing: 10,
//             children: <Widget>[
//               ElevatedButton(
//                 onPressed: _newWaypointMarker != null ? _addWaypoint : null,
//                 child: const Text('Add waypoint'),
//               ),
//               ElevatedButton(
//                 onPressed: _waypoints.isNotEmpty && !_guidanceRunning
//                     ? () => _clearNavigationWaypoints()
//                     : null,
//                 child: const Text('Clear waypoints'),
//               ),
//               getOptionsButton(context, onPressed: () => toggleOverlay())
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _createRemainingTimeAndDistanceLabels() {
//     return SafeArea(
//         minimum: const EdgeInsets.all(8.0),
//         child: Align(
//             alignment: Alignment.topLeft,
//             child: Card(
//                 child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 mainAxisSize: MainAxisSize.min,
//                 children: <Widget>[
//                   Text(
//                     'Remaining time: ${formatRemainingDuration(Duration(seconds: _remainingTime))}',
//                     style: const TextStyle(fontSize: 15),
//                   ),
//                   Text(
//                     'Remaining distance: ${formatRemainingDistance(_remainingDistance)}',
//                     style: const TextStyle(fontSize: 15),
//                   ),
//                 ],
//               ),
//             ))));
//   }

//   // Opens a bottom sheet showing total calls to each event listener.
//   void _showNavigationEventListenerCallCounts(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return Container(
//             padding: const EdgeInsets.all(16.0),
//             child: ListView(
//               children: <Widget>[
//                 Card(
//                     child: ListTile(
//                   title: const Text('On route changed event call count'),
//                   trailing: Text(_onRouteChangedEventCallCount.toString()),
//                 )),
//                 Card(
//                     child: ListTile(
//                   title: const Text(
//                       'On road snapped location updated event call count'),
//                   trailing: Text(
//                       _onRoadSnappedLocationUpdatedEventCallCount.toString()),
//                 )),
//                 if (Platform.isAndroid)
//                   Card(
//                       child: ListTile(
//                     title: const Text(
//                         'On road snapped raw location updated event call count'),
//                     trailing: Text(
//                         _onRoadSnappedRawLocationUpdatedEventCallCount
//                             .toString()),
//                   )),
//                 Card(
//                     child: ListTile(
//                   title: const Text('On traffic updated event call count'),
//                   trailing: Text(_onTrafficUpdatedEventCallCount.toString()),
//                 )),
//                 Card(
//                     child: ListTile(
//                   title: const Text('On rerouting event call count'),
//                   trailing: Text(_onReroutingEventCallCount.toString()),
//                 )),
//                 if (Platform.isAndroid)
//                   Card(
//                       child: ListTile(
//                     title: const Text('On GPS availability event call count'),
//                     trailing: Text(_onGpsAvailabilityEventCallCount.toString()),
//                   )),
//                 Card(
//                     child: ListTile(
//                   title: const Text('On arrival event call count'),
//                   trailing: Text(_onArrivalEventCallCount.toString()),
//                 )),
//                 Card(
//                     child: ListTile(
//                   title: const Text('On speeding updated event call count'),
//                   trailing: Text(_onSpeedingUpdatedEventCallCount.toString()),
//                 )),
//                 Card(
//                     child: ListTile(
//                   title:
//                       const Text('On recenter button clicked event call count'),
//                   trailing:
//                       Text(_onRecenterButtonClickedEventCallCount.toString()),
//                 )),
//                 Card(
//                     child: ListTile(
//                   title: const Text(
//                       'On remaining time or distance changed event call count'),
//                   trailing: Text(_onRemainingTimeOrDistanceChangedEventCallCount
//                       .toString()),
//                 )),
//                 Card(
//                     child: ListTile(
//                   title: const Text(
//                       'On navigation UI enabled changed event call count'),
//                   trailing: Text(
//                       _onNavigationUIEnabledChangedEventCallCount.toString()),
//                 )),
//               ],
//             ));
//       },
//     );
//   }

//   @override
//   Widget buildOverlayContent(BuildContext context) {
//     Color? getExpansionTileTextColor(bool disabled) {
//       return disabled ? Theme.of(context).disabledColor : null;
//     }

//     return Column(children: <Widget>[
//       Card(
//         child: ExpansionTile(
//           title: const Text('Terms and conditions'),
//           children: <Widget>[
//             Wrap(
//                 alignment: WrapAlignment.center,
//                 spacing: 10,
//                 children: <Widget>[
//                   ElevatedButton(
//                     onPressed: !_termsAndConditionsAccepted
//                         ? () => _showTermsAndConditionsDialogIfNeeded()
//                         : null,
//                     child: const Text('Show TOS'),
//                   ),
//                   ElevatedButton(
//                     onPressed:
//                         _termsAndConditionsAccepted ? () => _resetTOS() : null,
//                     child: const Text('Reset TOS'),
//                   ),
//                 ]),
//             const SizedBox(height: 10)
//           ],
//         ),
//       ),
//       Card(
//         child:
//             ExpansionTile(title: const Text('Navigation'), children: <Widget>[
//           Wrap(
//             alignment: WrapAlignment.center,
//             spacing: 10,
//             children: <Widget>[
//               ElevatedButton(
//                 onPressed: !_navigatorInitialized
//                     ? () => _initializeNavigator()
//                     : null,
//                 child: const Text('Start navigation'),
//               ),
//               ElevatedButton(
//                 onPressed: _navigatorInitialized
//                     ? () => _stopGuidedNavigation()
//                     : null,
//                 child: const Text('Stop navigation'),
//               ),
//               ElevatedButton(
//                 onPressed: _navigatorInitialized
//                     ? (_guidanceRunning ? _stopGuidance : _startGuidance)
//                     : null,
//                 child:
//                     Text(_guidanceRunning ? 'Stop guidance' : 'Start guidance'),
//               ),
//               ElevatedButton(
//                 onPressed: () =>
//                     _showNavigationEventListenerCallCounts(context),
//                 child: const Text('Show listeners'),
//               ),
//               ElevatedButton(
//                 onPressed: () => _showNativeNavigatorState(),
//                 child: const Text('Show native navigator state'),
//               ),
//               ElevatedButton(
//                 onPressed: _waypoints.isNotEmpty ? _displayRouteSegments : null,
//                 child: const Text('Display route segments'),
//               ),
//               ElevatedButton(
//                 onPressed:
//                     _waypoints.isNotEmpty ? _displayCurrentRouteSegment : null,
//                 child: const Text('Display current route segment'),
//               ),
//               ElevatedButton(
//                 onPressed: _waypoints.isNotEmpty && _guidanceRunning
//                     ? _displayTraveledRoute
//                     : null,
//                 child: const Text('Display travelled route'),
//               ),
//               ExampleSwitch(
//                   title: 'Show remaining time and distance',
//                   initialValue: _showRemainingTimeAndDistanceLabels,
//                   onChanged: (bool newValue) async {
//                     setState(() {
//                       _showRemainingTimeAndDistanceLabels = newValue;
//                     });
//                   }),
//               ExampleSwitch(
//                 title: 'Use route tokens',
//                 initialValue: _routeTokensEnabled,
//                 onChanged: _guidanceRunning
//                     ? null
//                     : (bool value) => _setRouteTokensEnabled(value),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10)
//         ]),
//       ),
//       IgnorePointer(
//           ignoring: !_navigatorInitialized,
//           child: Card(
//             child: ExpansionTile(
//               title: const Text('Simulation'),
//               collapsedTextColor:
//                   getExpansionTileTextColor(!_navigatorInitialized),
//               collapsedIconColor:
//                   getExpansionTileTextColor(!_navigatorInitialized),
//               children: <Widget>[
//                 Wrap(
//                   alignment: WrapAlignment.center,
//                   spacing: 10,
//                   children: <Widget>[
//                     if (_simulationState == SimulationState.running)
//                       ElevatedButton(
//                         onPressed: _pauseSimulation,
//                         child: const Text('Pause simulation'),
//                       ),
//                     if (_simulationState == SimulationState.paused)
//                       ElevatedButton(
//                         onPressed: _resumeSimulation,
//                         child: const Text('Resume simulation'),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 10)
//               ],
//             ),
//           )),
//       IgnorePointer(
//           ignoring: !_navigatorInitialized || _navigationViewController == null,
//           child: Card(
//             child: ExpansionTile(
//                 title: const Text('Navigation view'),
//                 collapsedTextColor: getExpansionTileTextColor(
//                     !_navigatorInitialized ||
//                         _navigationViewController == null),
//                 collapsedIconColor: getExpansionTileTextColor(
//                     !_navigatorInitialized ||
//                         _navigationViewController == null),
//                 children: <Widget>[
//                   ExampleSwitch(
//                       title: 'Enable guidance header',
//                       initialValue: _navigationHeaderEnabled,
//                       onChanged: (bool newValue) async {
//                         await _navigationViewController!
//                             .setNavigationHeaderEnabled(newValue);
//                         setState(() {
//                           _navigationHeaderEnabled = newValue;
//                         });
//                       }),
//                   ExampleSwitch(
//                       title: 'Enable footer',
//                       initialValue: _navigationFooterEnabled,
//                       onChanged: (bool newValue) async {
//                         await _navigationViewController!
//                             .setNavigationFooterEnabled(newValue);
//                         setState(() {
//                           _navigationFooterEnabled = newValue;
//                         });
//                       }),
//                   ExampleSwitch(
//                       title: 'Enable progress bar',
//                       initialValue: _navigationTripProgressBarEnabled,
//                       onChanged: (bool newValue) async {
//                         await _navigationViewController!
//                             .setNavigationTripProgressBarEnabled(newValue);
//                         setState(() {
//                           _navigationTripProgressBarEnabled = newValue;
//                         });
//                       }),
//                   ExampleSwitch(
//                       title: 'Enable Navigation UI',
//                       initialValue: _navigationUIEnabled,
//                       onChanged: (bool newValue) async {
//                         await _navigationViewController!
//                             .setNavigationUIEnabled(newValue);
//                         setState(() {
//                           _navigationUIEnabled = newValue;
//                         });
//                       }),
//                   ExampleSwitch(
//                       title: 'Enable recenter button',
//                       initialValue: _recenterButtonEnabled,
//                       onChanged: (bool newValue) async {
//                         await _navigationViewController!
//                             .setRecenterButtonEnabled(newValue);
//                         setState(() {
//                           _recenterButtonEnabled = newValue;
//                         });
//                       }),
//                   ExampleSwitch(
//                       title: 'Display speedlimit icon',
//                       initialValue: _speedLimitIconEnabled,
//                       onChanged: (bool newValue) async {
//                         await _navigationViewController!
//                             .setSpeedLimitIconEnabled(newValue);
//                         setState(() {
//                           _speedLimitIconEnabled = newValue;
//                         });
//                       }),
//                   ExampleSwitch(
//                       title: 'Display speedometer',
//                       initialValue: _speedometerEnabled,
//                       onChanged: (bool newValue) async {
//                         await _navigationViewController!
//                             .setSpeedometerEnabled(newValue);
//                         setState(() {
//                           _speedometerEnabled = newValue;
//                         });
//                       }),
//                   ExampleSwitch(
//                       title: 'Display traffic incident cards',
//                       initialValue: _trafficIndicentCardsEnabled,
//                       onChanged: (bool newValue) async {
//                         await _navigationViewController!
//                             .setTrafficIncidentCardsEnabled(newValue);
//                         setState(() {
//                           _trafficIndicentCardsEnabled = newValue;
//                         });
//                       }),
//                 ]),
//           )),
//       IgnorePointer(
//           ignoring: !_navigatorInitialized || _navigationViewController == null,
//           child: Card(
//             child: ExpansionTile(
//                 title: const Text('Camera'),
//                 collapsedTextColor: getExpansionTileTextColor(
//                     !_navigatorInitialized ||
//                         _navigationViewController == null),
//                 collapsedIconColor: getExpansionTileTextColor(
//                     !_navigatorInitialized ||
//                         _navigationViewController == null),
//                 children: <Widget>[
//                   Wrap(
//                       alignment: WrapAlignment.center,
//                       spacing: 10,
//                       children: <Widget>[
//                         ElevatedButton(
//                           onPressed: () =>
//                               _navigationViewController!.showRouteOverview(),
//                           child: const Text('Route overview'),
//                         ),
//                         ElevatedButton(
//                           onPressed: () => _navigationViewController!
//                               .followMyLocation(CameraPerspective.tilted),
//                           child: const Text('Follow my location'),
//                         )
//                       ]),
//                   const SizedBox(height: 10)
//                 ]),
//           )),
//     ]);
//   }

//   void showMessage(String message) {
//     if (isOverlayVisible) {
//       showOverlaySnackBar(message);
//     } else {
//       final SnackBar snackBar = SnackBar(content: Text(message));
//       ScaffoldMessenger.of(context).showSnackBar(snackBar);
//     }
//   }
// }

// /// Base wrapper widget for example pages, holding mainmenu leading
// /// icon and also page title.
// abstract class ExamplePage extends StatefulWidget {
//   /// [ExamplePage] constuctor
//   const ExamplePage({required this.leading, required this.title, super.key});

//   /// Leading widget is presented in main menu list before page tille.
//   final Widget leading;

//   /// Page title is presented in mainmenu and in page title.
//   final String title;

//   @override
//   ExamplePageState<ExamplePage> createState();
// }

// /// Base state for example pages, holding overlay animation controller and
// /// overlay visibility state.
// abstract class ExamplePageState<T extends ExamplePage> extends State<T>
//     with TickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<Offset> _overlayOffsetAnimation;

//   bool _isOverlayVisible = false;

//   /// Getter for overlay visibility state.
//   bool get isOverlayVisible => _isOverlayVisible;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );
//     _overlayOffsetAnimation = Tween<Offset>(
//       begin: const Offset(0.0, 1.0),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeInOut,
//     ));
//   }

//   /// Toggles overlay visibility.
//   @protected
//   void toggleOverlay() {
//     if (!_isOverlayVisible) {
//       setState(() {
//         _isOverlayVisible = !_isOverlayVisible;
//       });
//       _controller.forward();
//     } else {
//       _controller.reverse().then((_) {
//         setState(() {
//           _isOverlayVisible = false;
//         });
//       });
//     }
//   }

//   /// Helper method to hide overlay.
//   @protected
//   void hideOverlay() {
//     if (_isOverlayVisible) {
//       _controller.reverse().then((_) {
//         setState(() {
//           _isOverlayVisible = false;
//         });
//       });
//     }
//   }

//   /// Builds overlay content.
//   @protected
//   Widget buildOverlayContent(BuildContext context) {
//     throw UnimplementedError();
//   }

//   /// Wraps page content with scaffold and overlay.
//   @protected
//   Widget buildPage(BuildContext context, WidgetBuilder builder) {
//     return Stack(
//       children: <Widget>[
//         Scaffold(
//           appBar: AppBar(
//             title: Text(widget.title),
//           ),
//           body: Builder(builder: (BuildContext context) => builder(context)),
//         ),
//         if (_isOverlayVisible) _buildOverlay(),
//       ],
//     );
//   }

//   Widget _buildOverlay() {
//     return Stack(
//       children: <Widget>[
//         // Overlay background, which is used to close overlay when tapped.
//         GestureDetector(
//             onTap: hideOverlay,
//             child: AnimatedBuilder(
//                 animation: _controller,
//                 builder: (BuildContext context, Widget? child) => Container(
//                     color: Colors.black.withOpacity(_controller.value * 0.5)))),
//         // Overlay content
//         SlideTransition(
//           position: _overlayOffsetAnimation,
//           child: Align(
//             alignment: Alignment.bottomCenter,
//             // GestureDetector is used to prevent closing overlay when tapping
//             // on the content itself.
//             child: GestureDetector(
//               onTap: () {},
//               behavior: HitTestBehavior.opaque,
//               child: Material(
//                 color: Theme.of(context).cardColor,
//                 elevation: 4,
//                 borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(16),
//                     topRight: Radius.circular(16)),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: <Widget>[
//                     // Close button
//                     Padding(
//                       padding: const EdgeInsets.only(left: 16, right: 16),
//                       child: Align(
//                         alignment: Alignment.topRight,
//                         child: IconButton(
//                           icon: const Icon(Icons.close),
//                           onPressed: () => hideOverlay(),
//                         ),
//                       ),
//                     ),
//                     // Container for overlay content
//                     Container(
//                       constraints: BoxConstraints(
//                           maxHeight: MediaQuery.of(context).size.height * 0.6),
//                       child: SafeArea(
//                         top: false,
//                         minimum: const EdgeInsets.only(
//                             left: 8, right: 8, bottom: 16),
//                         // Make content scrollable
//                         child: Scrollbar(
//                           thumbVisibility: true,
//                           radius: const Radius.circular(30),
//                           child: SingleChildScrollView(
//                             child: buildOverlayContent(context),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         )
//       ],
//     );
//   }

//   /// Helper method to show message overlay.
//   void showOverlaySnackBar(String message,
//       {Alignment alignment = Alignment.bottomCenter}) {
//     final OverlayState overlay = Overlay.of(context);
//     final OverlayEntry overlayEntry = OverlayEntry(
//       builder: (BuildContext context) => Align(
//         alignment: alignment,
//         child: SizedBox(
//           width: double.infinity,
//           child: Material(
//             elevation: 10.0,
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               color: Theme.of(context).snackBarTheme.backgroundColor,
//               child: SafeArea(
//                   top: false,
//                   child: Text(
//                     message,
//                     style: Theme.of(context).snackBarTheme.contentTextStyle,
//                   )),
//             ),
//           ),
//         ),
//       ),
//     );

//     overlay.insert(overlayEntry);

//     // Automatically remove the snack bar after some duration
//     Future<void>.delayed(const Duration(seconds: 3))
//         .then((_) => overlayEntry.remove());
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }

// Future<bool> requestTermsAndConditionsAcceptance() async {
//   return (await GoogleMapsNavigator.areTermsAccepted()) ||
//       (await GoogleMapsNavigator.showTermsAndConditionsDialog(
//         'Aceite os Termos e Condições',
//         'Warrior Company',
//       ));
// }

// Future<bool> requestLocationDialogAcceptance() async {
//   return (await Permission.locationWhenInUse.isGranted) ||
//       (await Permission.locationWhenInUse.request()) ==
//           PermissionStatus.granted;
// }

// const Size _markerSize = Size(80, 80); // Example size in logical pixels

// /// Creates a waypoint marker with the given waypoint number and registers it.
// ///
// /// Returns an [ImageDescriptor] for the registered image.
// Future<ImageDescriptor> registerWaypointMarkerImage(
//     int waypointNumber, double imagePixelRatio) async {
//   final ui.PictureRecorder recorder = ui.PictureRecorder();
//   final Canvas canvas = Canvas(recorder);
//   final _WaypointMarkerPainter painter = _WaypointMarkerPainter(waypointNumber);

//   painter.paint(canvas, _markerSize);

//   final ui.Image image = await recorder
//       .endRecording()
//       .toImage(_markerSize.width.floor(), _markerSize.height.floor());

//   final ByteData? bytes =
//       await image.toByteData(format: ui.ImageByteFormat.png);

//   // Call registerBitmapImage with ByteData
//   return registerBitmapImage(bitmap: bytes!, imagePixelRatio: imagePixelRatio);
// }

// class _WaypointMarkerPainter extends CustomPainter {
//   _WaypointMarkerPainter(this.waypointNumber);
//   final int waypointNumber;

//   @override
//   void paint(Canvas canvas, Size size) {
//     const double strokeWidth = 6.0;

//     // Draw the background circle
//     final Paint circlePaint = Paint()
//       ..color = Colors.blue
//       ..style = PaintingStyle.fill;
//     final Offset center = Offset(size.width / 2, size.height / 2);
//     final double radius = size.width / 2 - strokeWidth / 2;
//     canvas.drawCircle(center, radius, circlePaint);

//     // Draw the border
//     final Paint borderPaint = Paint()
//       ..color = Colors.blue[800]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth;
//     canvas.drawCircle(center, radius, borderPaint);

//     // Draw the waypoint number
//     final TextSpan textSpan = TextSpan(
//       text: waypointNumber.toString(),
//       style: const TextStyle(
//         color: Colors.white,
//         fontSize: 50,
//         fontWeight: FontWeight.bold,
//       ),
//     );
//     final TextPainter textPainter = TextPainter(
//       text: textSpan,
//       textAlign: TextAlign.center,
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout(
//       maxWidth: size.width,
//     );
//     final Offset textOffset = Offset(
//       center.dx - textPainter.width / 2,
//       center.dy - textPainter.height / 2,
//     );
//     textPainter.paint(canvas, textOffset);
//   }

//   @override
//   bool shouldRepaint(_WaypointMarkerPainter oldDelegate) => false;
//   @override
//   bool shouldRebuildSemantics(_WaypointMarkerPainter oldDelegate) => false;
// }

// // Note: This Routes API implementation is ment to be used only to
// // support the example app, and only includes the bare minimum to get
// // the route tokens.

// const String _routesApiUrl = 'https://routes.googleapis.com/';
// const String _computeRoutesUrl = '$_routesApiUrl/directions/v2:computeRoutes';
// const String _mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

// /// Queries the Google Maps Routes API and returns a list of route tokens.
// ///
// /// [waypoints] is a list of [NavigationWaypoint] representing the route waypoints.
// /// [travelMode] is a string representing the travel mode.
// /// Returns a list of route tokens or throws an error if the request fails.
// Future<List<String>> getRouteToken(List<NavigationWaypoint> waypoints) async {
//   assert(_mapsApiKey.isNotEmpty,
//       'MAPS_API_KEY is not provided. Please pass it as a Dart define during the app build.');
//   assert(waypoints.length >= 2,
//       'At least two waypoints (origin and destination) are required.');

//   final Uri apiUrl = Uri.parse(_computeRoutesUrl);

//   final Map<String, dynamic> requestBody = <String, dynamic>{
//     'origin': _toRoutesApiWaypoint(waypoints.first),
//     'destination': _toRoutesApiWaypoint(waypoints.last),
//     'intermediates': waypoints
//         .sublist(1, waypoints.length - 1)
//         .map((NavigationWaypoint wp) => _toRoutesApiWaypoint(wp, via: true))
//         .toList(),
//     'travelMode': 'DRIVE',
//     'routingPreference': 'TRAFFIC_AWARE',
//   };

//   final Map<String, String> headers = <String, String>{
//     'X-Goog-Api-Key': _mapsApiKey,
//     'X-Goog-Fieldmask': 'routes.routeToken',
//     'Content-Type': 'application/json',
//   };

//   final http.Response response =
//       await http.post(apiUrl, headers: headers, body: jsonEncode(requestBody));

//   if (response.statusCode == 200) {
//     final Map<String, dynamic> responseData =
//         jsonDecode(response.body) as Map<String, dynamic>;
//     final List<dynamic>? routeTokens = responseData['routes'] as List<dynamic>?;

//     if (routeTokens == null) {
//       throw Exception('Failed to get route tokens');
//     }

//     return routeTokens
//         .map<String>((dynamic route) =>
//             (route as Map<String, dynamic>)['routeToken'] as String)
//         .toList();
//   } else {
//     throw Exception(
//         'Failed to get route tokens: ${response.reasonPhrase}:\n${response.body}');
//   }
// }

// /// Converts a [NavigationWaypoint] to a waypoint request format supported
// /// by the Routes API.
// Map<String, dynamic> _toRoutesApiWaypoint(NavigationWaypoint waypoint,
//     {bool via = false}) {
//   assert(waypoint.target != null || waypoint.placeID != null,
//       'Invalid NavigationWaypoint: Either target or placeID must be provided.');
//   final Map<String, dynamic> output = <String, dynamic>{
//     'via': via,
//   };
//   if (waypoint.placeID != null) {
//     output['placeId'] = waypoint.placeID;
//   } else if (waypoint.target != null) {
//     final Map<String, dynamic> location = <String, dynamic>{
//       'latLng': <String, dynamic>{
//         'latitude': waypoint.target!.latitude,
//         'longitude': waypoint.target!.longitude
//       }
//     };

//     if (waypoint.preferredSegmentHeading != null) {
//       location['heading'] = waypoint.preferredSegmentHeading;
//     }

//     output['location'] = location;
//   }
//   return output;
// }

// /// Builds options button Widget for the example app.
// Widget getOptionsButton(
//   BuildContext context, {
//   required void Function()? onPressed,
//   ButtonStyle? style,
// }) =>
//     ElevatedButton.icon(
//       style: style ?? ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
//       icon: const Icon(Icons.settings),
//       onPressed: onPressed,
//       label: const Text('Options'),
//     );

// /// Builds options button Widget with positioned alignment for the example app.
// Widget getOverlayOptionsButton(BuildContext context,
//         {required void Function()? onPressed, ButtonStyle? style}) =>
//     SafeArea(
//       child: Align(
//         alignment:
//             Platform.isAndroid ? Alignment.bottomCenter : Alignment.bottomRight,
//         child: Padding(
//           padding: const EdgeInsets.all(10),
//           child: getOptionsButton(context, onPressed: onPressed, style: style),
//         ),
//       ),
//     );

// String formatRemainingDuration(Duration duration) {
//   // Get total number of hours, minutes, and seconds.
//   final int hours = duration.inHours;
//   final int minutes = duration.inMinutes.remainder(60);
//   final int seconds = duration.inSeconds.remainder(60);

//   // Build the output based on the conditions.
//   if (hours > 0) {
//     // When hours are present, format as "HH:MM".
//     return '$hours hours $minutes minutes';
//   } else if (minutes > 5) {
//     // Otherwise, format as "MM" minutes.
//     return '$minutes minutes';
//   } else if (minutes > 0) {
//     // When there are fewer than 5 minutes, format as "MM:SS".
//     return '$minutes minutes $seconds seconds';
//   } else {
//     // When there are fewer than 1 minutes, format as "SS".
//     return '$seconds seconds';
//   }
// }

// String formatRemainingDistance(int meters) {
//   if (meters >= 1000) {
//     final double kilometers = meters / 1000;
//     // Using toStringAsFixed to round to 1 decimal place for kilometers.
//     return '${kilometers.toStringAsFixed(1)} km';
//   } else {
//     return '$meters m';
//   }
// }

// class ExampleSwitch extends StatefulWidget {
//   const ExampleSwitch({
//     super.key,
//     required this.title,
//     this.onChanged,
//     required this.initialValue,
//   });

//   /// The title of the switch tile which is displayed next to the switch.
//   final String title;

//   /// Called when the user toggles the switch.
//   ///
//   /// If null, the switch will be disabled.
//   final ValueChanged<bool>? onChanged;

//   /// The initial value of the switch.
//   final bool initialValue;

//   @override
//   State<ExampleSwitch> createState() => _ExampleSwitchState();
// }

// class _ExampleSwitchState extends State<ExampleSwitch> {
//   late bool _flag;

//   @override
//   void initState() {
//     super.initState();
//     _flag = widget.initialValue;
//   }

//   void _toggleFlag(bool value) {
//     setState(() {
//       _flag = value;
//     });
//     if (widget.onChanged != null) {
//       widget.onChanged!(value);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SwitchListTile(
//       title: Text(widget.title),
//       value: _flag,
//       onChanged: widget.onChanged != null ? _toggleFlag : null,
//     );
//   }
// }
