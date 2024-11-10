// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:google_navigation_flutter/google_navigation_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';

// void main() {
//   runApp(const MaterialApp(home: NavigationPage()));
// }

// /// Página de demonstração de navegação do Google Maps.
// ///
// /// Esta página demonstra como usar o plugin do SDK de Navegação do Google Maps,
// /// definindo destinos de navegação, iniciando e parando a navegação.
// class NavigationPage extends ExamplePage {
//   /// Cria um novo widget de página de demonstração de navegação.
//   const NavigationPage({super.key})
//       : super(leading: const Icon(Icons.navigation), title: 'Navigation');

//   @override
//   ExamplePageState<NavigationPage> createState() => _NavigationPageState();
// }

// /// Estado de simulação local.
// enum SimulationState {
//   /// Estado de simulação desconhecido.
//   unknown,

//   /// Simulação em execução.
//   running,

//   /// Simulação em execução com rota desatualizada.
//   runningOutdated,

//   /// Simulação pausada.
//   paused,

//   /// Simulação não está em execução.
//   notRunning,
// }

// /// Estado da página de demonstração de navegação.
// class _NavigationPageState extends ExamplePageState<NavigationPage> {
//   /// Controlador de visualização de navegação usado para interagir com a visualização de navegação.
//   GoogleNavigationViewController? _navigationViewController;

//   /// Última localização do usuário recebida do navegador.
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

//   // Define o modo de viagem padrão para direção (carro) e remove opções para alterá-lo.
//   final NavigationTravelMode _travelMode = NavigationTravelMode.driving;
//   final List<NavigationWaypoint> _waypoints = <NavigationWaypoint>[];

//   /// Se verdadeiro, tokens de rota e API de Rotas são usados para calcular a rota.
//   bool _routeTokensEnabled = false;

//   /// Usado para rastrear se o navegador foi inicializado pelo menos uma vez.
//   bool _navigatorInitializedAtLeastOnce = false;

//   /// As assinaturas de eventos precisam ser armazenadas para poder cancelá-las.
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
//     // Verifica se os termos e condições foram aceitos e mostra o diálogo se não.
//     await _showTermsAndConditionsDialogIfNeeded();

//     // Verifica se as permissões de localização foram aceitas e mostra o diálogo se não.
//     await _askLocationPermissionsIfNeeded();

//     // Inicializa o navegador se os termos e condições e as permissões de localização
//     // tiverem sido aceitos.
//     if (_termsAndConditionsAccepted && _locationPermissionsAccepted) {
//       await _initializeNavigator();
//     }
//   }

//   Future<void> _setRouteTokensEnabled(bool value) async {
//     setState(() {
//       // Tokens de rota são suportados apenas para o modo de direção neste aplicativo de exemplo.
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
//     assert(_termsAndConditionsAccepted, 'Os termos devem ser aceitos');
//     assert(
//         _locationPermissionsAccepted, 'As permissões de localização devem ser concedidas');

//     if (!_navigatorInitialized) {
//       debugPrint('Inicializando nova sessão de navegação...');
//       await GoogleMapsNavigator.initializeNavigationSession();
//       await _setupListeners();
//       await _updateNavigatorInitializationState();
//       await _restorePossibleNavigatorState();
//       unawaited(_setDefaultUserLocationAfterDelay());
//       debugPrint('O navegador foi inicializado: $_navigatorInitialized');
//     }
//     setState(() {});
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

//   /// O emulador iOS não atualiza a localização e não dispara eventos de roadsnapping.
//   /// Inicializa a localização do usuário para [cameraLocationMIT] se a localização do usuário
//   /// não estiver disponível após o tempo limite.
//   Future<void> _setDefaultUserLocationAfterDelay() async {
//     Future<void>.delayed(const Duration(milliseconds: 1500), () async {
//       if (mounted && _userLocation == null) {
//         _userLocation = await _navigationViewController?.getMyLocation() ??
//             const LatLng(latitude: 42.3601, longitude: -71.094013);
//         if (mounted) {
//           setState(() {});
//         }
//       }
//     });
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
//     // Limpa os ouvintes antigos para garantir que nos inscrevemos em cada evento apenas uma vez.
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

//   // Observação: atualizações de localização bruta não estão disponíveis no iOS.
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
//       // A orientação está em execução, habilita a IU de navegação.
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

//     // Limpa a sessão de navegação.
//     // Isso também limpará os destinos, parará a simulação, parará a orientação
//     await GoogleMapsNavigator.cleanup();
//     await _removeNewWaypointMarker();
//     await _removeDestinationWaypointMarkers();
//     _waypoints.clear();

//     // Redefine a perspectiva de navegação para cima do norte.
//     await _navigationViewController!
//         .followMyLocation(CameraPerspective.topDownNorthUp);

//     // Certifique-se de que o estado de inicialização da navegação esteja atualizado.
//     await _updateNavigatorInitializationState();

//     // Ao limpar o navegador, a simulação também é interrompida, atualize o estado.
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
//       // Adiciona novo marcador.
//       final List<Marker?> addedMarkers = await _navigationViewController!
//           .addMarkers(<MarkerOptions>[markerOptions]);
//       if (addedMarkers.first != null) {
//         _newWaypointMarker = addedMarkers.first;
//       } else {
//         showMessage('Erro ao adicionar marcador de destino');
//       }
//     } else {
//       // Atualiza marcador existente.
//       final Marker updatedWaypointMarker =
//           _newWaypointMarker!.copyWith(options: markerOptions);
//       final List<Marker?> updatedMarkers = await _navigationViewController!
//           .updateMarkers(<Marker>[updatedWaypointMarker]);
//       if (updatedMarkers.first != null) {
//         _newWaypointMarker = updatedMarkers.first;
//       } else {
//         showMessage('Erro ao atualizar marcador de destino');
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

//       // Desregistra imagens de marcadores personalizados
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

//       // Converte o novo marcador de waypoint em marcador de destino.
//       await _convertNewWaypointMarkerToDestinationMarker(_nextWaypointIndex);
//       await _updateNavigationDestinationsAndNavigationViewState();
//     }
//     setState(() {});
//   }

//   /// Método auxiliar que primeiro atualiza os destinos e depois
//   /// atualiza o estado da visualização de navegação para mostrar a visão geral da rota.
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
//       showMessage('Calculando a rota.');
//     }
//   }

//   /// Este método é chamado pelo manipulador de eventos _onArrivalEvent quando o usuário
//   /// chegou a um waypoint.
//   Future<void> _arrivedToWaypoint(NavigationWaypoint waypoint) async {
//     debugPrint('Chegou ao waypoint: ${waypoint.title}');

//     // Remove o primeiro waypoint da lista.
//     if (_waypoints.isNotEmpty) {
//       _waypoints.removeAt(0);
//     }
//     // Remove o primeiro marcador de destino da lista.
//     if (_destinationWaypointMarkers.isNotEmpty) {
//       final Marker markerToRemove = _destinationWaypointMarkers.first;
//       await _navigationViewController!.removeMarkers(<Marker>[markerToRemove]);

//       // Desregistra imagem de marcador personalizado.
//       await unregisterImage(markerToRemove.options.icon);

//       _destinationWaypointMarkers.removeAt(0);
//     }

//     await GoogleMapsNavigator.continueToNextDestination();

//     if (_waypoints.isEmpty) {
//       debugPrint('Chegou ao último waypoint, parando a navegação.');

//       // Se não houver próximo waypoint, significa que chegamos ao último
//       // destino. Portanto, pare a navegação.
//       await _stopGuidedNavigation();
//     }

//     setState(() {});
//   }

//   Future<bool> _updateNavigationDestinations() async {
//     if (_navigationViewController == null || _waypoints.isEmpty) {
//       return false;
//     }

//     if (!_navigatorInitialized) {
//       await _initializeNavigator();
//     }

//     // Se os tokens de rota estiverem habilitados, construa destinos com tokens de rota.
//     final Destinations? destinations = _routeTokensEnabled
//         ? (await _buildDestinationsWithRoutesApi())
//         : _buildDestinations();

//     if (destinations == null) {
//       // Falha ao construir destinos.
//       // Isso pode acontecer se os tokens de rota estiverem habilitados e o token de rota não puder
//       // ser buscado.
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
//           // Rota é válida. Retorna true como sucesso.
//           setState(() {
//             _errorOnSetDestinations = false;
//           });
//           return true;
//         case NavigationRouteStatus.internalError:
//           showMessage(
//               'Ocorreu um erro interno inesperado. Por favor, reinicie o aplicativo.');
//           break;
//         case NavigationRouteStatus.routeNotFound:
//           showMessage('A rota não pôde ser calculada.');
//           break;
//         case NavigationRouteStatus.networkError:
//           showMessage(
//               'Uma conexão de rede funcional é necessária para calcular a rota.');
//           break;
//         case NavigationRouteStatus.quotaExceeded:
//           showMessage(
//               'Cota insuficiente de API para usar a navegação.');
//           break;
//         case NavigationRouteStatus.quotaCheckFailed:
//           showMessage(
//               'Falha na verificação da cota da API, não é possível autorizar a navegação.');
//           break;
//         case NavigationRouteStatus.apiKeyNotAuthorized:
//           showMessage(
//               'Uma chave de API válida é necessária para usar a navegação.');
//           break;
//         case NavigationRouteStatus.statusCanceled:
//           showMessage(
//               'O cálculo da rota foi cancelado em favor de um mais recente.');
//           break;
//         case NavigationRouteStatus.duplicateWaypointsError:
//           showMessage(
//               'A rota não pôde ser calculada devido a waypoints duplicados.');
//           break;
//         case NavigationRouteStatus.noWaypointsError:
//           showMessage(
//               'A rota não pôde ser calculada porque nenhum waypoint foi fornecido.');
//           break;
//         case NavigationRouteStatus.locationUnavailable:
//           showMessage(
//               'Nenhuma localização do usuário está disponível. Você permitiu permissão de localização?');
//           break;
//         case NavigationRouteStatus.waypointError:
//           showMessage('Waypoints inválidos fornecidos.');
//           break;
//         case NavigationRouteStatus.travelModeUnsupported:
//           showMessage(
//               'A rota não pôde ser calculada para o modo de viagem fornecido.');
//           break;
//         case NavigationRouteStatus.unknown:
//           showMessage(
//               'A rota não pôde ser calculada devido a um erro desconhecido.');
//           break;
//         case NavigationRouteStatus.locationUnknown:
//           showMessage(
//               'A rota não pôde ser calculada porque a localização do usuário é desconhecida.');
//           break;
//       }
//     } on RouteTokenMalformedException catch (_) {
//       showMessage('Token de rota malformado');
//     } on SessionNotInitializedException catch (_) {
//       showMessage('Não é possível definir destinos, sessão não inicializada');
//     }
//     setState(() {
//       _errorOnSetDestinations = true;
//     });
//     return false;
//   }

//   Destinations? _buildDestinations() {
//     // Mostra mensagem de cálculo de rota com atraso.
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

//     showMessage('Usando token de rota da API de Rotas.');

//     List<String> routeTokens = <String>[];
//     try {
//       routeTokens = await getRouteToken(
//         <NavigationWaypoint>[
//           // Adiciona a localização do usuário como localização inicial para obter o token de rota.
//           NavigationWaypoint.withLatLngTarget(
//               title: 'Origin', target: _userLocation),
//           ..._waypoints,
//         ],
//       );
//     } catch (e) {
//       showMessage('Falha ao obter tokens de rota da API de Rotas. $e');
//       return null;
//     }

//     if (routeTokens.isEmpty) {
//       showMessage('Falha ao obter tokens de rota da API de Rotas.');
//       return null;
//     } else if (routeTokens.length > 1) {
//       showMessage(
//           'Mais de um token de rota recebido da API de Rotas. Usando o primeiro.');
//     }

//     return Destinations(
//         waypoints: _waypoints,
//         displayOptions: NavigationDisplayOptions(showDestinationMarkers: false),
//         routeTokenOptions: RouteTokenOptions(
//           routeToken: routeTokens.first, // Usa o primeiro token de rota obtido.
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
//       showMessage('Navegador inicializado');
//     } else {
//       showMessage('Navegador não inicializado');
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
//         SimulationOptions(speedMultiplier: 5),
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
//     showMessage('Quantidade de segmentos de rota: ${segments.length}');
//   }

//   Future<void> _displayTraveledRoute() async {
//     final List<LatLng> route = await GoogleMapsNavigator.getTraveledRoute();
//     showMessage('Pontos do segmento de rota percorridos: ${route.length}');
//   }

//   Future<void> _displayCurrentRouteSegment() async {
//     final RouteSegment? segment =
//         await GoogleMapsNavigator.getCurrentRouteSegment();
//     showMessage(
//         'Destino do segmento de rota atual: ${segment?.destinationWaypoint?.title ?? 'desconhecido'}');
//   }

//   @override
//   Widget build(BuildContext context) => buildPage(
//       context,
//       (BuildContext context) => Padding(
//           padding: EdgeInsets.zero,
//           child: Stack(
//             children: <Widget>[
//               Column(children: <Widget>[
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
//                             // Inicializa o mapa para a localização do usuário.
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
//                               Text('Aguardando navegador e localização do usuário'),
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

//   Future<void> _retryToUpdateNavigationDestinations() async {
//     setState(() {
//       _errorOnSetDestinations = false;
//     });
//     await _updateNavigationDestinationsAndNavigationViewState();
//   }

//   Widget get bottomControls {
//     if (!_termsAndConditionsAccepted || !_locationPermissionsAccepted) {
//       return Padding(
//           padding: const EdgeInsets.all(15),
//           child: Wrap(
//               alignment: WrapAlignment.center,
//               spacing: 10,
//               children: <Widget>[
//                 const Text(
//                     'Os termos e condições e as permissões de localização devem ser aceitos'
//                     ' antes que a navegação possa ser iniciada.'),
//               ]));
//     }
//     if (!_navigatorInitializedAtLeastOnce) {
//       return const Text('Aguardando o navegador inicializar...');
//     }
//     return Padding(
//       padding: const EdgeInsets.all(15),
//       child: Column(
//         children: <Widget>[
//           if (_errorOnSetDestinations && _waypoints.isNotEmpty) ...<Widget>[
//             const Text('Erro ao definir destinos'),
//             ElevatedButton(
//               onPressed: _retryToUpdateNavigationDestinations,
//               child: const Text('Tentar novamente'),
//             ),
//           ],
//           if (_guidanceRunning &&
//               _simulationState == SimulationState.runningOutdated)
//             Wrap(
//                 alignment: WrapAlignment.center,
//                 spacing: 10,
//                 children: <Widget>[
//                   const Text('Simulação em execução com rota desatualizada'),
//                   ElevatedButton(
//                     onPressed: () => _startSimulation(),
//                     child: const Text('Atualizar simulação'),
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
//                     child: const Text('Iniciar Navegação'),
//                   ),
//                 if (_guidanceRunning)
//                   ElevatedButton(
//                     onPressed: _validRoute ? _stopGuidedNavigation : null,
//                     child: const Text('Parar Navegação'),
//                   ),
//                 if (_guidanceRunning &&
//                     _simulationState == SimulationState.notRunning)
//                   ElevatedButton(
//                     onPressed: () => _startSimulation(),
//                     child: const Text('Iniciar simulação'),
//                   ),
//                 if (_guidanceRunning &&
//                     _simulationState == SimulationState.unknown)
//                   ElevatedButton(
//                     onPressed: () => _startSimulation(),
//                     child: const Text('Retomar estado da simulação'),
//                   ),
//                 if (_guidanceRunning &&
//                     (_simulationState == SimulationState.running ||
//                         _simulationState == SimulationState.runningOutdated ||
//                         _simulationState == SimulationState.paused))
//                   ElevatedButton(
//                     onPressed: () => _stopSimulation(),
//                     child: const Text('Parar simulação'),
//                   ),
//               ],
//             ),
//           if (_waypoints.isEmpty)
//             const Padding(
//               padding: EdgeInsets.all(15),
//               child: Text('Clique no mapa para adicionar waypoints'),
//             ),
//           Wrap(
//             alignment: WrapAlignment.center,
//             spacing: 10,
//             children: <Widget>[
//               ElevatedButton(
//                 onPressed: _newWaypointMarker != null ? _addWaypoint : null,
//                 child: const Text('Adicionar waypoint'),
//               ),
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
//                     'Tempo restante: ${formatRemainingDuration(Duration(seconds: _remainingTime))}',
//                     style: const TextStyle(fontSize: 15),
//                   ),
//                   Text(
//                     'Distância restante: ${formatRemainingDistance(_remainingDistance)}',
//                     style: const TextStyle(fontSize: 15),
//                   ),
//                 ],
//               ),
//             ))));
//   }

//   void showMessage(String message) {
//     final SnackBar snackBar = SnackBar(content: Text(message));
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//   }
// }

// /// Classe base para páginas de exemplo, contendo o ícone principal
// /// e o título da página.
// abstract class ExamplePage extends StatefulWidget {
//   /// Construtor de [ExamplePage]
//   const ExamplePage({required this.leading, required this.title, super.key});

//   /// Widget principal apresentado na lista do menu principal antes do título da página.
//   final Widget leading;

//   /// Título da página apresentado no menu principal e no título da página.
//   final String title;

//   @override
//   ExamplePageState<ExamplePage> createState();
// }

// /// Estado base para páginas de exemplo.
// abstract class ExamplePageState<T extends ExamplePage> extends State<T> {
//   /// Construtor padrão
//   @override
//   void initState() {
//     super.initState();
//   }

//   /// Constrói o conteúdo da página.
//   @protected
//   Widget buildPage(BuildContext context, WidgetBuilder builder) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Builder(builder: (BuildContext context) => builder(context)),
//     );
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

// const Size _markerSize = Size(80, 80); // Tamanho de exemplo em pixels lógicos

// /// Cria um marcador de waypoint com o número do waypoint fornecido e o registra.
// ///
// /// Retorna um [ImageDescriptor] para a imagem registrada.
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

//   // Chama registerBitmapImage com ByteData
//   return registerBitmapImage(bitmap: bytes!, imagePixelRatio: imagePixelRatio);
// }

// class _WaypointMarkerPainter extends CustomPainter {
//   _WaypointMarkerPainter(this.waypointNumber);
//   final int waypointNumber;

//   @override
//   void paint(Canvas canvas, Size size) {
//     const double strokeWidth = 6.0;

//     // Desenha o círculo de fundo
//     final Paint circlePaint = Paint()
//       ..color = Colors.blue
//       ..style = PaintingStyle.fill;
//     final Offset center = Offset(size.width / 2, size.height / 2);
//     final double radius = size.width / 2 - strokeWidth / 2;
//     canvas.drawCircle(center, radius, circlePaint);

//     // Desenha a borda
//     final Paint borderPaint = Paint()
//       ..color = Colors.blue[800]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth;
//     canvas.drawCircle(center, radius, borderPaint);

//     // Desenha o número do waypoint
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

// // Observação: Esta implementação da API de Rotas é destinada a ser usada apenas
// // para suportar o aplicativo de exemplo e inclui apenas o mínimo necessário para obter
// // os tokens de rota.

// const String _routesApiUrl = 'https://routes.googleapis.com/';
// const String _computeRoutesUrl = '$_routesApiUrl/directions/v2:computeRoutes';
// const String _mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

// /// Consulta a API de Rotas do Google Maps e retorna uma lista de tokens de rota.
// ///
// /// [waypoints] é uma lista de [NavigationWaypoint] representando os waypoints da rota.
// /// Retorna uma lista de tokens de rota ou lança um erro se a solicitação falhar.
// Future<List<String>> getRouteToken(List<NavigationWaypoint> waypoints) async {
//   assert(_mapsApiKey.isNotEmpty,
//       'MAPS_API_KEY não foi fornecido. Por favor, passe como uma definição do Dart durante a compilação do aplicativo.');
//   assert(waypoints.length >= 2,
//       'Pelo menos dois waypoints (origem e destino) são necessários.');

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
//       throw Exception('Falha ao obter tokens de rota');
//     }

//     return routeTokens
//         .map<String>((dynamic route) =>
//             (route as Map<String, dynamic>)['routeToken'] as String)
//         .toList();
//   } else {
//     throw Exception(
//         'Falha ao obter tokens de rota: ${response.reasonPhrase}:\n${response.body}');
//   }
// }

// /// Converte um [NavigationWaypoint] para um formato de solicitação de waypoint suportado
// /// pela API de Rotas.
// Map<String, dynamic> _toRoutesApiWaypoint(NavigationWaypoint waypoint,
//     {bool via = false}) {
//   assert(waypoint.target != null || waypoint.placeID != null,
//       'NavigationWaypoint inválido: ou target ou placeID deve ser fornecido.');
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

// String formatRemainingDuration(Duration duration) {
//   final int hours = duration.inHours;
//   final int minutes = duration.inMinutes.remainder(60);
//   final int seconds = duration.inSeconds.remainder(60);

//   if (hours > 0) {
//     return '$hours horas $minutes minutos';
//   } else if (minutes > 5) {
//     return '$minutes minutos';
//   } else if (minutes > 0) {
//     return '$minutes minutos $seconds segundos';
//   } else {
//     return '$seconds segundos';
//   }
// }

// String formatRemainingDistance(int meters) {
//   if (meters >= 1000) {
//     final double kilometers = meters / 1000;
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

//   /// O título do switch exibido ao lado do switch.
//   final String title;

//   /// Chamado quando o usuário alterna o switch.
//   ///
//   /// Se for nulo, o switch ficará desabilitado.
//   final ValueChanged<bool>? onChanged;

//   /// O valor inicial do switch.
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
