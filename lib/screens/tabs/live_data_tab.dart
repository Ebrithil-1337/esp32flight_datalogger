import 'package:flutter/material.dart'; // Core UI
import 'package:provider/provider.dart'; // State management
import '../../providers/app_state.dart'; // The Brain

class LiveDataTab extends StatelessWidget
{ // The Live Data UI
  const LiveDataTab({super.key}); // Constructor

  void openSensorSelector(BuildContext context, AppState appState)
  { // Live Data configurator popup
    showDialog(
      context: context,
      builder: (BuildContext dialogContext)
      { // Build popup
        return StatefulBuilder(
          builder: (context, setDialogState)
          { // Allow animation
            return AlertDialog(
              title: const Text('Live Data Sensors'), // Title
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true, // Shrink
                  itemCount: appState.columnHeaders.length, // Total sensors
                  itemBuilder: (context, index)
                  { // Build row
                    return CheckboxListTile(
                      title: Text(appState.columnHeaders[index]), // Name
                      value: appState.selectedSensors.contains(index), // Checked?
                      onChanged: (bool? checked)
                      { // Clicked
                        setDialogState(()
                        { // Update popup UI visually
                          appState.updateLiveSensors(index, checked == true); // Tell the brain
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Close
                  child: const Text('Done'), // Text
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
    List<int> displayIndices = appState.selectedSensors.toList()..sort(); // Sort

    return Padding(
      padding: const EdgeInsets.all(16.0), // Padding
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space
            children: [
              const Text('Live Sensor Data', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), // Title
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.blue), // Gear
                onPressed: () => openSensorSelector(context, appState), // Open Menu
              ),
            ],
          ),
          const SizedBox(height: 10), // Gap
          
          Expanded(
            child: appState.latestDataRow.isEmpty
                ? const Center(child: Text('No data streaming yet.')) // Fallback
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Columns
                      childAspectRatio: 2.5, // Ratio
                      crossAxisSpacing: 10, // Horiz Gap
                      mainAxisSpacing: 10, // Vert Gap
                    ),
                    itemCount: displayIndices.length, // Ticked count
                    itemBuilder: (context, gridIndex)
                    { // Draw card
                      int dataIndex = displayIndices[gridIndex]; // Number
                      if (dataIndex >= appState.latestDataRow.length) return const SizedBox(); // Safety
                      String label = dataIndex < appState.columnHeaders.length ? appState.columnHeaders[dataIndex] : "Sensor ${dataIndex + 1}"; // Label
                      
                      return Card(
                        elevation: 3, // Shadow
                        color: Colors.white, // BG
                        child: Padding(
                          padding: const EdgeInsets.all(8.0), // Inner Pad
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, // Center
                            children: [
                              Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey), overflow: TextOverflow.ellipsis), // Name
                              Text(appState.latestDataRow[dataIndex], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Value
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}