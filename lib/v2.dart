// // ignore_for_file: library_private_types_in_public_api

// import 'dart:async';
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart';
// import 'package:http/http.dart' as http;

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

//   // Posição atual
//   LatLng _currentPosition = const LatLng(0.0, 0.0);

//   // Coordenadas da rota
//   List<LatLng> _routeCoords = [];

//   // Posição do destino
//   LatLng? _destinationPosition;

//   // Polilinhas para exibir no mapa
//   final Set<Polyline> _polylines = {};

//   // Marcadores para exibir no mapa
//   final Set<Marker> _markers = {};

//   // Controlador para entrada do destino
//   final TextEditingController _destinationController = TextEditingController();

//   // Instruções de navegação
//   List<String> _instructions = [];

//   // Sua chave de API do Google Maps (substitua pela sua)
//   final String googleAPIKey = 'AIzaSyDLUEwS3mBAizM2IUUoOEj0yuUiEV8PqTI';

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
//       });

//       // Move a câmera para a posição atual
//       _mapController.animateCamera(
//         CameraUpdate.newLatLng(_currentPosition),
//       );

//       // Atualiza instruções de navegação se tiver destino
//       if (_destinationPosition != null && _routeCoords.isNotEmpty) {
//         _updateNavigationInstructions();
//       }
//     });
//   }

//   // Quando o mapa é criado
//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//     _location.changeSettings(interval: 1000); // Atualiza a cada 1 segundo
//   }

//   // Obtém a rota do ponto atual até o destino
//   Future<void> _getRoute() async {
//     if (_destinationPosition == null) return;

//     String url =
//         'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentPosition.latitude},${_currentPosition.longitude}&destination=${_destinationPosition!.latitude},${_destinationPosition!.longitude}&key=$googleAPIKey';

//     http.Response response = await http.get(Uri.parse(url));
//     Map values = jsonDecode(response.body);

//     if (values['routes'].isNotEmpty) {
//       // Decodifica os pontos da polilinha
//       String encodedPolyline = values['routes'][0]['overview_polyline']['points'];
//       _routeCoords = _decodePolyline(encodedPolyline);

//       // Extrai instruções de navegação
//       _instructions = [];
//       var steps = values['routes'][0]['legs'][0]['steps'];
//       for (var step in steps) {
//         String htmlInstruction = step['html_instructions'];
//         // Remove tags HTML
//         String instruction = htmlInstruction.replaceAll(RegExp(r'<[^>]*>'), '');
//         _instructions.add(instruction);
//       }

//       setState(() {
//         // Adiciona polilinha
//         _polylines.add(Polyline(
//           polylineId: const PolylineId('route'),
//           points: _routeCoords,
//           color: Colors.blue,
//           width: 5,
//         ));

//         // Adiciona marcador do destino
//         _markers.add(Marker(
//           markerId: const MarkerId('destination'),
//           position: _destinationPosition!,
//         ));
//       });
//     } else {
//       //print('Erro ao obter direções');
//     }
//   }

//   // Decodifica a polilinha
//   List<LatLng> _decodePolyline(String encoded) {
//     List<LatLng> polyline = [];
//     int index = 0, len = encoded.length;
//     int lat = 0, lng = 0;

//     while (index < len) {
//       int b, shift = 0, result = 0;

//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1F) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
//       lat += dlat;

//       shift = 0;
//       result = 0;

//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1F) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
//       lng += dlng;

//       LatLng point = LatLng(lat / 1E5, lng / 1E5);
//       polyline.add(point);
//     }
//     return polyline;
//   }

//   // Atualiza instruções de navegação
//   void _updateNavigationInstructions() {
//     // Exemplo simplificado
//     if (_instructions.isNotEmpty) {
//       setState(() {
//         // Remove a primeira instrução como exemplo
//         _instructions.removeAt(0);
//       });
//     }
//   }

//   // Obtém coordenadas do destino a partir do endereço
//   Future<void> _getDestinationCoordinates(String address) async {
//     String url =
//         'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleAPIKey';

//     http.Response response = await http.get(Uri.parse(url));
//     Map values = jsonDecode(response.body);

//     if (values['results'].isNotEmpty) {
//       double lat = values['results'][0]['geometry']['location']['lat'];
//       double lng = values['results'][0]['geometry']['location']['lng'];

//       _destinationPosition = LatLng(lat, lng);
//       _getRoute();
//     } else {
//       //print('Erro ao obter coordenadas do destino');
//     }
//   }

//   @override
//   void dispose() {
//     _destinationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Navegação em Tempo Real'),
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             onMapCreated: _onMapCreated,
//             initialCameraPosition: CameraPosition(
//               target: _currentPosition,
//               zoom: 16.0,
//             ),
//             myLocationEnabled: true,
//             markers: _markers,
//             polylines: _polylines,
//           ),
//           Positioned(
//             top: 10,
//             left: 10,
//             right: 10,
//             child: Card(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 10),
//                 child: TextField(
//                   controller: _destinationController,
//                   decoration: InputDecoration(
//                     hintText: 'Digite o destino',
//                     suffixIcon: IconButton(
//                       icon: const Icon(Icons.search),
//                       onPressed: () {
//                         // Obtém coordenadas do destino
//                         _getDestinationCoordinates(_destinationController.text);
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           if (_instructions.isNotEmpty)
//             Positioned(
//               bottom: 20,
//               left: 10,
//               right: 10,
//               child: Card(
//                 color: Colors.white70,
//                 child: Padding(
//                   padding: const EdgeInsets.all(10),
//                   child: Text(
//                     _instructions.first,
//                     style: const TextStyle(fontSize: 18),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
