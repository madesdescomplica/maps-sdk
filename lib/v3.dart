// // ignore_for_file: library_private_types_in_public_api

// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart' as loc;
// import 'package:url_launcher/url_launcher.dart';

// void main() {
//   runApp(const MaterialApp(
//     home: NavigationWidget(
//       destinationLat: -5.145795066974555,
//       destinationLng: -42.7857449998978
//     ),
//   ));
// }

// class NavigationWidget extends StatefulWidget {
//   final double destinationLat;
//   final double destinationLng;

//   const NavigationWidget({
//     Key? key,
//     required this.destinationLat,
//     required this.destinationLng,
//   }) : super(key: key);

//   @override
//   _NavigationWidgetState createState() => _NavigationWidgetState();
// }

// class _NavigationWidgetState extends State<NavigationWidget> {
//   late GoogleMapController _mapController;
//   final loc.Location _location = loc.Location();

//   // Posição atual do usuário
//   LatLng _currentPosition = const LatLng(0.0, 0.0);

//   // Marcadores no mapa
//   final Set<Marker> _markers = {};

//   // Polilinhas (rota) no mapa
//   final Set<Polyline> _polylines = {};

//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }

//   // Inicializa a localização e configurações do mapa
//   Future<void> _initialize() async {
//     await _checkLocationPermission();
//     await _getCurrentLocation();
//     _addMarkers();
//     _drawRoute();
//   }

//   // Verifica e solicita permissão de localização
//   Future<void> _checkLocationPermission() async {
//     bool serviceEnabled;
//     loc.PermissionStatus permissionGranted;

//     // Verifica se os serviços de localização estão habilitados
//     serviceEnabled = await _location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _location.requestService();
//       if (!serviceEnabled) {
//         return;
//       }
//     }

//     // Verifica permissão de localização
//     permissionGranted = await _location.hasPermission();
//     if (permissionGranted == loc.PermissionStatus.denied) {
//       permissionGranted = await _location.requestPermission();
//       if (permissionGranted != loc.PermissionStatus.granted) {
//         return;
//       }
//     }
//   }

//   // Obtém a localização atual do usuário
//   Future<void> _getCurrentLocation() async {
//     final loc.LocationData locationData = await _location.getLocation();
//     setState(() {
//       _currentPosition =
//           LatLng(locationData.latitude!, locationData.longitude!);
//     });
//   }

//   // Adiciona marcadores de origem e destino no mapa
//   void _addMarkers() {
//     _markers.add(Marker(
//       markerId: const MarkerId('currentLocation'),
//       position: _currentPosition,
//       infoWindow: const InfoWindow(title: 'Você está aqui'),
//     ));

//     _markers.add(Marker(
//       markerId: const MarkerId('destination'),
//       position: LatLng(widget.destinationLat, widget.destinationLng),
//       infoWindow: const InfoWindow(title: 'Destino'),
//     ));
//   }

//   // Desenha a rota entre a localização atual e o destino
//   void _drawRoute() {
//     _polylines.add(Polyline(
//       polylineId: const PolylineId('route'),
//       points: [_currentPosition, LatLng(widget.destinationLat, widget.destinationLng)],
//       color: Colors.blue,
//       width: 5,
//     ));
//   }

//   // Quando o mapa é criado
//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//     // Move a câmera para a posição atual do usuário
//     _mapController.animateCamera(
//       CameraUpdate.newLatLngZoom(_currentPosition, 14.0),
//     );
//   }

//   // Inicia a navegação no Google Maps
//   Future<void> _startNavigation() async {
//     final String googleMapsUrl =
//         'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition.latitude},${_currentPosition.longitude}&destination=${widget.destinationLat},${widget.destinationLng}&travelmode=driving';

//     if (await canLaunch(googleMapsUrl)) {
//       await launch(googleMapsUrl);
//     } else {
//       throw 'Não foi possível iniciar a navegação';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Navegação'),
//       ),
//       body: _currentPosition.latitude == 0.0 && _currentPosition.longitude == 0.0
//           ? const Center(child: CircularProgressIndicator())
//           : Stack(
//               children: [
//                 GoogleMap(
//                   onMapCreated: _onMapCreated,
//                   initialCameraPosition: CameraPosition(
//                     target: _currentPosition,
//                     zoom: 14.0,
//                   ),
//                   markers: _markers,
//                   polylines: _polylines,
//                   myLocationEnabled: true,
//                 ),
//                 Positioned(
//                   bottom: 20,
//                   left: 20,
//                   right: 20,
//                   child: ElevatedButton.icon(
//                     onPressed: _startNavigation,
//                     icon: const Icon(Icons.navigation),
//                     label: const Text('Iniciar Navegação'),
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 15),
//                       textStyle: const TextStyle(fontSize: 18),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }
