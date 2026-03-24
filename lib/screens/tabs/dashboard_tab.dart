import 'package:flutter/material.dart'; // Core UI
import 'package:provider/provider.dart'; // State management
import '../../providers/app_state.dart'; // The Brain

class DashboardTab extends StatelessWidget
{ // The Dashboard UI
  const DashboardTab({super.key}); // Constructor

  @override
  Widget build(BuildContext context)
  { // Build layout
    final appState = Provider.of<AppState>(context); // Connect to Brain

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Vertically
        children: [
          Text(appState.connectionStatus, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)), // Status
          const SizedBox(height: 40), // Spacing
          
          const Text('Session Duration', style: TextStyle(fontSize: 20, color: Colors.grey)), // Time Label
          Text(appState.formattedSessionTime, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)), // Time Counter
          const SizedBox(height: 40), // Spacing
          
          if (appState.connectedDevice == null)
            ElevatedButton(
              onPressed: appState.startScan, // Scan
              child: const Padding(
                padding: EdgeInsets.all(12.0), // Padding
                child: Text('Connect to ESP32', style: TextStyle(fontSize: 20)), // Text
              ),
            )
          else
            ElevatedButton(
              onPressed: appState.disconnectFromDevice, // Disconnect
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), // Red color
              child: const Padding(
                padding: EdgeInsets.all(12.0), // Padding
                child: Text('Disconnect', style: TextStyle(fontSize: 20, color: Colors.white)), // Text
              ),
            ),
            
          const SizedBox(height: 20), // Spacing
          
          ElevatedButton(
            onPressed: () async
            { // Dynamic Action Button
              if (appState.connectedDevice != null)
              { // If connected, save and disconnect first
                await appState.disconnectFromDevice(); // Trigger disconnect
              }
              appState.pickCSVFile(); // Open the file picker
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green), // Green
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Padding
              child: Text(appState.connectedDevice == null ? 'Load Saved CSV File' : 'Disconnect and load saved csv file', style: const TextStyle(fontSize: 20, color: Colors.white)), // Dynamic Text
            ),
          ),
          const SizedBox(height: 10), // Spacing

          const SizedBox(height: 20), // Spacing
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center them
            children: [
              ElevatedButton.icon(
                onPressed: appState.testTTS, // Triggers the voice test
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey), // Distinct color
                icon: const Icon(Icons.volume_up, color: Colors.white), // Speaker icon
                label: const Text('Test Audio', style: TextStyle(color: Colors.white)), // Text
              ),
              const SizedBox(width: 10), // Gap between buttons
              ElevatedButton.icon(
                onPressed: appState.toggleTTSLanguage, // Flips the language
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple), // Purple color
                icon: const Icon(Icons.language, color: Colors.white), // Globe icon
                label: Text(appState.isGermanTTS ? 'DE' : 'EN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Dynamic Text
              ),
            ],
          ),
          
          if (appState.totalDataRows > 0 && appState.replayIndex < appState.totalDataRows)
            ElevatedButton(
              onPressed: appState.skipReplay, // Skip
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), // Orange
              child: const Padding(
                padding: EdgeInsets.all(8.0), // Padding
                child: Text('Skip Replay', style: TextStyle(fontSize: 16, color: Colors.white)), // Text
              ),
            ),
            
          const SizedBox(height: 20), // Spacing
          
          ElevatedButton.icon(
            onPressed: appState.clearSession, // Wipe app
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Red color
            icon: const Icon(Icons.delete_forever, color: Colors.white), // Trash icon
            label: const Text('Clear Session', style: TextStyle(color: Colors.white)), // Text
          ),
          
          const SizedBox(height: 20), // Spacing
          
          if (appState.totalDataRows > 0) ...[
            Text('File: ${appState.loadedFileName}', style: const TextStyle(fontSize: 16)), // Name
            Text('Data Rows: ${appState.totalDataRows}', style: const TextStyle(fontSize: 16)), // Rows
          ],
        ],
      ),
    );
  }
}