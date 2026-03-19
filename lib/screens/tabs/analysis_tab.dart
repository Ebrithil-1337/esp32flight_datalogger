import 'package:flutter/material.dart'; // Core UI
import 'package:provider/provider.dart'; // State management
import 'package:fl_chart/fl_chart.dart'; // Charting tools
import '../../providers/app_state.dart'; // The Brain

class AnalysisTab extends StatelessWidget
{ // The Analysis UI
  const AnalysisTab({super.key}); // Constructor

  void openSingleChartConfigurator(BuildContext context, AppState appState, int chartIndex)
  { // Configures ONE specific chart
    showDialog(
      context: context,
      builder: (BuildContext dialogContext)
      { // Build popup
        return StatefulBuilder(
          builder: (context, setDialogState)
          { // Allow animation
            return AlertDialog(
              title: const Text('Select Chart Sensors'), // Title
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true, // Shrink
                  itemCount: appState.columnHeaders.length, // Total sensors
                  itemBuilder: (context, idx)
                  { // Build row
                    return CheckboxListTile(
                      title: Text(appState.columnHeaders[idx], style: TextStyle(color: appState.chartColors[idx % appState.chartColors.length], fontWeight: FontWeight.bold)), // Color text
                      value: appState.activeCharts[chartIndex].contains(idx), // Checked?
                      onChanged: (bool? val)
                      { // Clicked
                        setDialogState(()
                        { // Update popup UI visually
                          appState.updateChartSensors(chartIndex, idx, val == true); // Tell the brain
                        });
                      }
                    );
                  }
                )
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

  Widget buildChartLegend(AppState appState, Set<int> sensorsToDraw)
  { // Helper to draw colored text labels
    if (sensorsToDraw.isEmpty) return const Text('Tap the Gear Icon to assign sensors', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)); // Fallback
    
    return Wrap(
      spacing: 12, // Horizontal gap
      runSpacing: 4, // Vertical gap
      children: sensorsToDraw.map((idx)
      { // Loop
        String name = idx < appState.columnHeaders.length ? appState.columnHeaders[idx] : "Sensor ${idx + 1}"; // Pull name
        Color lineCol = appState.chartColors[idx % appState.chartColors.length]; // Pull color
        
        return Row(
          mainAxisSize: MainAxisSize.min, // Keep tight
          children: [
            Container(width: 12, height: 12, color: lineCol), // Box
            const SizedBox(width: 4), // Gap
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), // Text
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context)
  { // Build layout
    final appState = Provider.of<AppState>(context); // Connect to Brain

    return Padding(
      padding: const EdgeInsets.all(8.0), // Padding
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out
            children: [
              Row(
                children: [
                  const Text('👆', style: TextStyle(fontSize: 18)), // Tooltips
                  Switch(
                    value: appState.isZoomMode, // Links switch
                    activeThumbColor: Colors.blue, // Blue
                    inactiveThumbColor: Colors.red, // Red
                    onChanged: (value)
                    { // Flipped
                      appState.setZoomMode(value); // Update brain
                    },
                  ),
                  const Text('✋', style: TextStyle(fontSize: 18)), // Pan/Zoom
                ],
              ),
              ElevatedButton.icon(
                onPressed: appState.addNewChart, // Add chart button
                icon: const Icon(Icons.add), // Plus
                label: const Text('Add Chart'), // Text
              ),
            ],
          ),
          const SizedBox(height: 10), // Spacing
          
          Expanded(
            child: appState.activeCharts.isEmpty 
              ? const Center(child: Text('No charts! Click "Add Chart" to start.', style: TextStyle(fontSize: 18, color: Colors.grey))) // Fallback
              : ListView.builder(
                  itemCount: appState.activeCharts.length, // Total dynamic charts
                  physics: const BouncingScrollPhysics(), // Smooth scrolling
                  itemBuilder: (context, index)
                  { // Build each card
                     return Card(
                       elevation: 4, // Shadow
                       margin: const EdgeInsets.only(bottom: 20), // Bottom gap
                       child: Padding(
                         padding: const EdgeInsets.all(12.0), // Inner gap
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch
                           children: [
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space
                               crossAxisAlignment: CrossAxisAlignment.start, // Top align
                               children: [
                                 Expanded(child: buildChartLegend(appState, appState.activeCharts[index])), // Dynamic legend
                                 Row(
                                   children: [
                                     IconButton(
                                       icon: const Icon(Icons.settings, color: Colors.blue), // Gear
                                       onPressed: () => openSingleChartConfigurator(context, appState, index), // Configurator
                                     ),
                                     IconButton(
                                       icon: const Icon(Icons.delete, color: Colors.red), // Trash
                                       onPressed: () => appState.deleteChart(index), // Delete
                                     ),
                                   ],
                                 ),
                               ],
                             ),
                             const SizedBox(height: 10), // Spacing
                             SizedBox(
                               height: 250, // Fixed height per chart
                               child: LayoutBuilder(
                                  builder: (context, constraints)
                                  { // Width Math
                                    double screenWidth = constraints.maxWidth; // Width
                                    if (screenWidth == 0) screenWidth = 1; // Safety
                                    
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque, // Catch touches
                                      onScaleStart: appState.isZoomMode ? (details)
                                      { // Down
                                        appState.startMinX = appState.visibleMinX; // Math
                                        appState.startMaxX = appState.visibleMaxX; // Math
                                        appState.startFocalX = details.localFocalPoint.dx; // Math
                                      } : null, // Disable
                                      onScaleUpdate: appState.isZoomMode ? (details)
                                      { // Moving
                                        double currentRange = appState.startMaxX - appState.startMinX; // Range
                                        double newRange = currentRange / details.scale; // Stretch
                                        double focalPercent = appState.startFocalX / screenWidth; // Pinch center
                                        double focalDataX = appState.startMinX + (currentRange * focalPercent); // Data center
                                        double currentFocalPercent = details.localFocalPoint.dx / screenWidth; // Pan
                                        
                                        double newMinX = focalDataX - (newRange * currentFocalPercent); // Math
                                        double newMaxX = newMinX + newRange; // Math
                                        double maxDataX = appState.timeCounter > 100 ? appState.timeCounter : 100; // Limit

                                        if (newMinX < 0) newMinX = 0; // Lock left
                                        if (newMaxX > maxDataX) newMaxX = maxDataX; // Lock right
                                        if (newMinX == 0) newMaxX = newMinX + newRange; // Bounce left
                                        if (newMaxX == maxDataX) newMinX = newMaxX - newRange; // Bounce right
                                        if (newMaxX - newMinX < 10) newMaxX = newMinX + 10; // Zoom limit
                                        if (newMinX < 0) newMinX = 0; // Final safety
                                        if (newMaxX > maxDataX) newMaxX = maxDataX; // Final safety
                                        
                                        appState.updateZoom(newMinX, newMaxX); // Update Brain
                                      } : null, // Disable
                                      child: LineChart(
                                        LineChartData(
                                          minX: appState.visibleMinX, // Shared Math
                                          maxX: appState.visibleMaxX, // Shared Math
                                          lineTouchData: LineTouchData(enabled: !appState.isZoomMode), // Tooltips
                                          clipData: const FlClipData.all(), // Clip bounds
                                          titlesData: const FlTitlesData(
                                            show: true, // Labels
                                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide
                                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide
                                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)), // X Axis
                                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)), // Y Axis
                                          ),
                                          lineBarsData: appState.activeCharts[index].where((idx) => idx < appState.allSensorData.length).map((idx)
                                          { // Map ticked sensors to line drawers
                                            return LineChartBarData(
                                              spots: appState.allSensorData[idx], // Array
                                              isCurved: false, // Straight
                                              color: appState.chartColors[idx % appState.chartColors.length], // Color
                                              barWidth: 2, // Thick
                                              dotData: const FlDotData(show: false), // Hide dots
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  }
                               ),
                             ),
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