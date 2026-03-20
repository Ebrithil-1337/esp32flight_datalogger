import 'package:flutter/material.dart'; // Core UI
import 'package:provider/provider.dart'; // State management
import 'package:flutter_map/flutter_map.dart'; // Map controller
import 'package:latlong2/latlong.dart' hide Path; // GPS math
import '../../providers/app_state.dart'; // The Brain
import '../../widgets/compass_painter.dart'; // The compass tool

class MapTab extends StatelessWidget
{ // The Map UI
  const MapTab({super.key}); // Constructor

  @override
  Widget build(BuildContext context)
  { // Build layout
    final appState = Provider.of<AppState>(context); // Connect to Brain

    if (!appState.mapLoaded) return const SizedBox(); // Wait for boot

    return Stack(
      children: [
        FlutterMap(
          mapController: appState.mapController, // Controller
          options: MapOptions(
            initialCenter: appState.flightPath.isNotEmpty ? appState.flightPath.last : const LatLng(54.3233, 10.1228), // Center
            initialZoom: 16.0, // Zoom
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', // Satellite
              userAgentPackageName: 'com.example.esp32flight_datalogger', // User Agent
            ),
            if (appState.flightPath.length > 1) 
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: appState.flightPath, // GPS Data
                    color: Colors.blue, // Blue
                    strokeWidth: 4.0, // Thick
                  ),
                ],
              ),
            if (appState.flightPath.isNotEmpty)
              MarkerLayer(
                markers: [
                  Marker(
                    point: appState.flightPath.last, // Center
                    width: 40,
                    height: 40,
                    child: Transform.rotate(
                      angle: appState.currentHeading * (3.14159 / 180), // Math rotation
                      child: const Icon(Icons.flight, color: Colors.red, size: 40), // Plane
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          top: 16, // Lock to top
          right: 16, // Lock to right
          child: GestureDetector(
            onTap: ()
            { // Clicked
              appState.mapController.rotate(0.0); // Snap map back to exactly North
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white70, // Semi-transparent white backing
                shape: BoxShape.circle, // Make it round
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)], // Drop shadow
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0), // Padding
                child: StreamBuilder<MapEvent>(
                  stream: appState.mapController.mapEventStream, // Listens directly to map movements
                  builder: (context, snapshot)
                  { // Redraws just the compass when the map spins
                    double currentRotation = 0.0; // Default to North
                    try
                    { // Attempt to read the camera
                       currentRotation = appState.mapController.camera.rotation; // Get rotation in degrees
                    }
                    catch (e) { /* Ignore if map isn't fully built yet */ }
                    
                    return Transform.rotate(
                      angle: -currentRotation * (3.14159 / 180), // Counter-rotate so it always points North
                      child: CustomPaint(
                        size: const Size(80, 80), // Size
                        painter: ClassicCompassNeedlePainter(), // Custom drawing
                      ),
                    );
                  }
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}