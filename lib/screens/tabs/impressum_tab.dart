import 'package:flutter/material.dart'; // Core UI
import 'package:provider/provider.dart'; // State management
import '../../providers/app_state.dart'; // Connect to Brain

class ImpressumScreen extends StatelessWidget 
{ // Main class for the Impressum page
  const ImpressumScreen({super.key});

  @override
  Widget build(BuildContext context) 
  { // Build layout
    final appState = Provider.of<AppState>(context); // Connect to AppState for translations

    return Scaffold(
      appBar: AppBar(
        title: Text(appState.tr('Impressum')), // Translated Title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding around the edges
        child: ListView(
          children: [
            const Icon(Icons.info_outline, size: 80, color: Colors.blue), // Top logo/icon
            const SizedBox(height: 20), // Spacing
            
            const Text('Flight Analyzer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center), // App Name
            const Text('Version 1.2.1', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center), // Version number
            
            const SizedBox(height: 40), // Spacing
            
            Text(appState.tr('About this App'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Translated Header
            const SizedBox(height: 10), // Spacing
            const Text('Diese App wurde für ein Schulprojekt entwickelt und ist für den Betrieb in Kombination mit einem ESP32 Flight Data Recorder vorgesehen.'),
            
            const SizedBox(height: 30), // Spacing
            
            Text(appState.tr('Design und Entwicklung:'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Translated Header
            const SizedBox(height: 10), // Spacing
            const Text('Created by: [ Frithjof Winteler & Lisa Wollesen]'), 
            const Text('Erstellt für die Berufliche Schule des Kreises Nordfriesland in Husum.'),
            
          ],
        ),
      ),
    );
  }
}