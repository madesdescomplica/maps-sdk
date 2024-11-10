// // ignore_for_file: library_private_types_in_public_api

// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart';

// void main() {
//   runApp(const MaterialApp(
//     home: RealTimeTripWidget(),
//   ));
// }

// class RealTimeTripWidget extends StatefulWidget {
//   const RealTimeTripWidget({super.key});

//   @override
//   _RealTimeTripWidgetState createState() => _RealTimeTripWidgetState();
// }

// class _RealTimeTripWidgetState extends State<RealTimeTripWidget> {
//   late GoogleMapController _mapController;
//   final Location _location = Location();

//   // Para armazenar a posição atual
//   LatLng _currentPosition = const LatLng(0.0, 0.0);

//   // Para armazenar a rota percorrida
//   final List<LatLng> _route = [];

//   @override
//   void initState() {
//     super.initState();
//     _checkLocationPermission();
//   }

//   // Verifica e solicita permissão de localização
//   void _checkLocationPermission() async {
//     bool serviceEnabled;
//     PermissionStatus permissionGranted;

//     // Verifica se o serviço está habilitado
//     serviceEnabled = await _location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _location.requestService();
//       if (!serviceEnabled) {
//         return;
//       }
//     }

//     // Verifica permissão
//     permissionGranted = await _location.hasPermission();
//     if (permissionGranted == PermissionStatus.denied) {
//       permissionGranted = await _location.requestPermission();
//       if (permissionGranted != PermissionStatus.granted) {
//         return;
//       }
//     }

//     // Obtém a localização inicial
//     LocationData locationData = await _location.getLocation();
//     _currentPosition =
//         LatLng(locationData.latitude!, locationData.longitude!);

//     // Começa a escutar as mudanças de localização
//     _location.onLocationChanged.listen((LocationData currentLocation) {
//       setState(() {
//         _currentPosition =
//             LatLng(currentLocation.latitude!, currentLocation.longitude!);
//         _route.add(_currentPosition);
//       });
//       _mapController.animateCamera(
//         CameraUpdate.newLatLng(_currentPosition),
//       );
//     });
//   }

//   // Quando o mapa é criado
//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//     _location.changeSettings(interval: 1000); // Atualiza a cada 1 segundo
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Viagem em Tempo Real'),
//       ),
//       body: GoogleMap(
//         onMapCreated: _onMapCreated,
//         initialCameraPosition: CameraPosition(
//           target: _currentPosition,
//           zoom: 16.0,
//         ),
//         myLocationEnabled: true,
//         polylines: {
//           Polyline(
//             polylineId: const PolylineId('route'),
//             points: _route,
//             color: Colors.blue,
//             width: 5,
//           ),
//         },
//       ),
//     );
//   }
// }
