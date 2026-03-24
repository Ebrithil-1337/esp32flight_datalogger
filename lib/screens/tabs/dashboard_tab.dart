import 'package:flutter/material.dart'; // Core UI
import 'package:provider/provider.dart'; // State management
import '../../providers/app_state.dart'; // The Brain

class DashboardTab extends StatelessWidget
{ // The Dashboard UI
  const DashboardTab({super.key}); // Constructor

  void openSettingsMenu(BuildContext context, AppState appState)
  { // Opens the settings popup
    TextEditingController voltageController = TextEditingController(text: appState.voltageThreshold.toString()); // Pre-fill with current saved value

    showDialog(
      context: context,
      builder: (BuildContext dialogContext)
      { // Build popup
        return StatefulBuilder(
          builder: (context, setDialogState)
          { // Allow the popup itself to update visually when buttons are pressed
            return AlertDialog(
              title: const Text('Dashboard Settings'), // Title
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Wrap content tightly
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Audible Alerts', style: TextStyle(fontWeight: FontWeight.bold)), // Label
                      value: appState.audibleAlertsEnabled, // Bind to brain
                      activeThumbColor: const Color.fromARGB(255, 33, 243, 61), // Theme color
                      onChanged: (bool value)
                      { // Toggled
                        appState.toggleAudibleAlerts(value); // Update and save to phone
                        setDialogState(() {}); // Force the popup to redraw the switch animation
                      },
                    ),
                    const SizedBox(height: 10), // Spacing
                    TextField(
                      controller: voltageController, // Binds the text box
                      keyboardType: const TextInputType.numberWithOptions(decimal: true), // Force a number pad
                      decoration: const InputDecoration(
                        labelText: 'Voltage Warning Threshold (V)', // Floating label
                        border: OutlineInputBorder(), // Clean box border
                      ),
                      onChanged: (value)
                      { // Triggers every time you type a number
                        double? parsed = double.tryParse(value); // Convert string to number safely
                        if (parsed != null)
                        { // If it is a valid number
                          appState.setVoltageThreshold(parsed); // Save it to the phone instantly
                        }
                      },
                    ),
                    const SizedBox(height: 20), // Spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Push buttons apart
                      children: [
                        ElevatedButton.icon(
                          onPressed: appState.testTTS, // Triggers the voice test
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey), // Distinct color
                          icon: const Icon(Icons.volume_up, color: Colors.white), // Speaker icon
                          label: const Text('Test', style: TextStyle(color: Colors.white)), // Text
                        ),
                        ElevatedButton.icon(
                          onPressed: ()
                          { // Language toggle wrapper
                            appState.toggleTTSLanguage(); // Flips the language in the brain
                            setDialogState(() {}); // Force the popup to redraw to show DE/EN text change
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple), // Purple color
                          icon: const Icon(Icons.language, color: Colors.white), // Globe icon
                          label: Text(appState.isGermanTTS ? 'DE' : 'EN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Dynamic Text
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Spacing
                    ElevatedButton.icon(
                      onPressed: ()
                      { // Clear session wrapper
                        appState.clearSession(); // Wipe app data
                        Navigator.of(context).pop(); // Automatically close popup after clearing
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Danger color
                      icon: const Icon(Icons.delete_forever, color: Colors.white), // Trash icon
                      label: const Text('Clear Session', style: TextStyle(color: Colors.white)), // Text
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Close button
                  child: const Text('Close'), // Text
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context)
  { // Build layout
    final appState = Provider.of<AppState>(context); // Connect to Brain

    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Vertically center content
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
                  { // If connected, disconnect first
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
              
              if (appState.totalDataRows > 0) ...[
                Text('File: ${appState.loadedFileName}', style: const TextStyle(fontSize: 16)), // Name
                Text('Data Rows: ${appState.totalDataRows}', style: const TextStyle(fontSize: 16)), // Rows
              ],
            ],
          ),
        ),
        
        // SETTINGS GEAR BUTTON
        Positioned(
          top: 16, // Padding from top edge
          right: 16, // Padding from right edge
          child: IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey, size: 32), // Gear icon
            onPressed: () => openSettingsMenu(context, appState), // Trigger popup
          ),
        ),
      ],
    );
  }
}