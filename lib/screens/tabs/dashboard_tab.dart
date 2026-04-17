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
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Lets the dialog stretch closer to the phone edges
              titlePadding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 8), // Shrinks the gap above the title
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4), // Shrinks the gap between title and content

              title: Text(appState.tr('Dashboard Settings')), 
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    SwitchListTile(
                      title: Text(appState.tr('Enable Audible Alerts'), style: const TextStyle(fontWeight: FontWeight.bold)), // Translated Label
                      subtitle: Text(appState.tr('Master toggle for all voice warnings')), // Translated Description
                      value: appState.audibleAlertsEnabled, // Bind to brain
                      activeThumbColor: Colors.blue, // Replaced activeColor with activeThumbColor
                      onChanged: (bool value)
                      { // Toggled
                        appState.toggleAudibleAlerts(value); // Update and save
                        setDialogState(() {}); // Force the popup to redraw
                      },
                    ),
                    const SizedBox(height: 10), // Spacing
                    TextField(
                      controller: voltageController, // Binds the text box
                      keyboardType: const TextInputType.numberWithOptions(decimal: true), // Force a number pad
                      decoration: InputDecoration(
                        labelText: appState.tr('Voltage Warning Threshold (V)'), // Translated Floating label
                        border: const OutlineInputBorder(), // Clean box border
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
                          label: Text(appState.tr('Test Audio'), style: const TextStyle(color: Colors.white)), // Translated Text
                        ),
                        ElevatedButton.icon(
                          onPressed: ()
                          { // Language toggle wrapper
                            appState.toggleLanguage(); // Flips the language in the brain
                            setDialogState(() {}); // Force the popup to redraw to show DE/EN text change
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple), // Purple color
                          icon: const Icon(Icons.language, color: Colors.white), // Globe icon
                          label: Text(appState.isAppInGerman ? 'DE' : 'EN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Dynamic Text
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
                      label: Text(appState.tr('Clear Session'), style: const TextStyle(color: Colors.white)), // Translated Text
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Close button
                  child: Text(appState.tr('Close')), // Translated Text
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
          // ADDED SingleChildScrollView right here so only the column scrolls
          child: SingleChildScrollView( 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Vertically center content
              children: [
                Text(appState.connectionStatus, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)), // Status
                const SizedBox(height: 40), // Spacing
                
                Text(appState.tr('Session Duration'), style: const TextStyle(fontSize: 20, color: Colors.grey)), // Translated Time Label
                Text(appState.formattedSessionTime, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)), // Time Counter
                const SizedBox(height: 40), // Spacing
                
                if (appState.connectedDevice == null)
                  ElevatedButton(
                    onPressed: appState.startScan, // Scan
                    child: Padding(
                      padding: const EdgeInsets.all(12.0), // Padding
                      child: Text(appState.tr('Connect to ESP32'), style: const TextStyle(fontSize: 20)), // Translated Text
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: appState.disconnectFromDevice, // Disconnect
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), // Red color
                    child: Padding(
                      padding: const EdgeInsets.all(12.0), // Padding
                      child: Text(appState.tr('Disconnect'), style: const TextStyle(fontSize: 20, color: Colors.white)), // Translated Text
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
                    child: Text(appState.connectedDevice == null ? appState.tr('Load Saved CSV File') : appState.tr('Load Saved CSV File'), style: const TextStyle(fontSize: 20, color: Colors.white)), // Translated Dynamic Text
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
          ), // END of SingleChildScrollView
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