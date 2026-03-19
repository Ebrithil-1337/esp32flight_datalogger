import 'package:flutter/material.dart'; // Imports UI tools
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Imports the Bluetooth package
import 'package:file_picker/file_picker.dart'; // Imports the native file explorer tools
import 'dart:io'; // Imports the tools to read physical files
import 'package:fl_chart/fl_chart.dart'; // Imports the charting UI tools
import 'dart:async'; // Imports the tools needed for real-time loops and timers
import 'package:flutter_map/flutter_map.dart'; // Map drawing tools
import 'package:latlong2/latlong.dart' hide Path; // Hides the GPS Path class to prevent collisions
import 'dart:convert'; // Needed to encode text
import 'dart:typed_data'; // Needed for the byte list


void main()
{ // Starting point
  runApp(const FlightAnalyzerApp());
}

class FlightAnalyzerApp extends StatelessWidget
{ // Main app widget
  const FlightAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context)
  { // Builds the app layout
    return MaterialApp(
      title: 'Flight Analyzer',
      home: const BluetoothScreen(),
    );
  }
}

// --- CUSTOM PAINTER: CLASSIC COMPASS NEEDLE ---
class ClassicCompassNeedlePainter extends CustomPainter
{ // Draws a detailed 8-point compass rose
  @override
  void paint(Canvas canvas, Size size)
  {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    // --- COLORS ---
    final Paint darkRed = Paint()..color = const Color(0xFFA71C1C)..style = PaintingStyle.fill;
    final Paint lightRed = Paint()..color = const Color(0xFFD32F2F)..style = PaintingStyle.fill;
    
    final Paint darkLightBlue = Paint()..color = const Color(0xFF3B6985)..style = PaintingStyle.fill;
    final Paint lightLightBlue = Paint()..color = const Color(0xFF548CA8)..style = PaintingStyle.fill;
    
    final Paint darkNavy = Paint()..color = const Color(0xFF112233)..style = PaintingStyle.fill;
    final Paint lightNavy = Paint()..color = const Color(0xFF1D3557)..style = PaintingStyle.fill;
    
    final Paint ringPaint = Paint()..color = const Color(0xFF1D3557)..style = PaintingStyle.stroke..strokeWidth = 1.5;

    // --- OUTER RINGS ---
    canvas.drawCircle(Offset(cx, cy), w / 2.2, ringPaint); // Outer ring
    canvas.drawCircle(Offset(cx, cy), w / 3.0, ringPaint..strokeWidth = 0.5); // Inner ring

    // Helper to draw a triangle
    void drawTriangle(Canvas c, Paint p, Offset p1, Offset p2, Offset p3)
    { // Used to draw the sharp points of the star
      Path path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
      c.drawPath(path, p);
    }

    // --- MINOR POINTS (NW, NE, SE, SW) ---
    canvas.save();
    canvas.translate(cx, cy);
    for (int i = 0; i < 4; i++)
    { // Loop to draw the 4 diagonal spikes
      canvas.rotate(45 * 3.14159 / 180); // Rotate 45 degrees
      drawTriangle(canvas, lightNavy, const Offset(0, 0), Offset(0, -w / 2.8), Offset(w / 16, 0)); // Right half
      drawTriangle(canvas, darkNavy, const Offset(0, 0), Offset(0, -w / 2.8), Offset(-w / 16, 0)); // Left half
      canvas.rotate(-45 * 3.14159 / 180); // Reset rotation
      canvas.rotate(90 * 3.14159 / 180); // Move to next quadrant
    }
    canvas.restore();

    // --- MAJOR POINTS (E, W) ---
    canvas.save();
    canvas.translate(cx, cy);
    // East
    drawTriangle(canvas, lightNavy, const Offset(0, 0), Offset(w / 2.4, 0), Offset(0, -w / 12)); // Top half
    drawTriangle(canvas, darkNavy, const Offset(0, 0), Offset(w / 2.4, 0), Offset(0, w / 12)); // Bottom half
    // West
    drawTriangle(canvas, darkNavy, const Offset(0, 0), Offset(-w / 2.4, 0), Offset(0, -w / 12)); // Top half
    drawTriangle(canvas, lightNavy, const Offset(0, 0), Offset(-w / 2.4, 0), Offset(0, w / 12)); // Bottom half
    canvas.restore();

    // --- MAJOR POINTS (N, S) ---
    canvas.save();
    canvas.translate(cx, cy);
    // North (Red)
    drawTriangle(canvas, darkRed, const Offset(0, 0), Offset(0, -w / 2.0), Offset(-w / 12, 0)); // Left half
    drawTriangle(canvas, lightRed, const Offset(0, 0), Offset(0, -w / 2.0), Offset(w / 12, 0)); // Right half
    // South (Blue)
    drawTriangle(canvas, darkLightBlue, const Offset(0, 0), Offset(0, w / 2.0), Offset(-w / 12, 0)); // Left half
    drawTriangle(canvas, lightLightBlue, const Offset(0, 0), Offset(0, w / 2.0), Offset(w / 12, 0)); // Right half
    canvas.restore();

    // --- CENTER PIVOT ---
    canvas.drawCircle(Offset(cx, cy), w / 12, Paint()..color = Colors.white..style = PaintingStyle.fill); // Outer white
    canvas.drawCircle(Offset(cx, cy), w / 18, Paint()..color = const Color(0xFF1D3557)..style = PaintingStyle.fill); // Inner dark
    canvas.drawCircle(Offset(cx, cy), w / 35, Paint()..color = Colors.white..style = PaintingStyle.fill); // Center pin

    // --- LETTERS (N, E, S, W) ---
    void drawText(Canvas c, String text, Offset offset)
    { // Helper to draw text perfectly centered
      TextSpan span = TextSpan(style: const TextStyle(color: Color(0xFF1D3557), fontSize: 14, fontWeight: FontWeight.bold), text: text);
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(c, Offset(offset.dx - (tp.width / 2), offset.dy - (tp.height / 2)));
    }

    drawText(canvas, "N", Offset(cx, cy - w / 2.6)); // North
    drawText(canvas, "S", Offset(cx, cy + w / 2.6)); // South
    drawText(canvas, "E", Offset(cx + w / 2.6, cy)); // East
    drawText(canvas, "W", Offset(cx - w / 2.6, cy)); // West
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // Static drawing
}

class BluetoothScreen extends StatefulWidget
{ // The screen that holds our state
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen>
{ // Variables and logic go here
  
  // --- DASHBOARD VARIABLES ---
  String connectionStatus = "Disconnected"; // Shows if paired
  BluetoothDevice? connectedDevice; // Remembers the active ESP32 connection
  StreamSubscription<List<int>>? bleStream; // MAGIC FIX: Saves the data stream so we can kill it later!
  
  // --- RECORDING VARIABLES ---
  List<String> recordedRows = []; // Memory bank for saving live Bluetooth data
  
  // --- REPLAY VARIABLES ---
  String loadedFileName = "No file loaded"; // Holds selected file name
  int totalDataRows = 0; // Counts total rows
  Timer? playbackTimer; // Looping timer
  List<String> replayRows = []; // Holds all CSV text
  int replayIndex = 0; // Tracks current row
  
  // --- TIME VARIABLES ---
  int? firstTimestamp; // Memory for the exact millisecond the session started
  int? latestTimestamp; // Memory for the most recent millisecond received
  
  // --- NAVIGATION VARIABLES ---
  int _selectedTab = 0; // Tab index tracker
  
  // --- MAP VARIABLES ---
  MapController mapController = MapController(); // Controls map camera
  List<LatLng> flightPath = []; // Holds GPS history
  bool mapLoaded = false; // Tracks map initialization
  double currentHeading = 0.0; // Tracks plane rotation

  // --- UNIVERSAL DATA VARIABLES ---
  List<String> latestDataRow = []; // Holds raw data for Live Tab
  List<String> columnHeaders = []; // Stores sensor names
  Set<int> selectedSensors = {}; // Remembers ticked Live Data sensors
  double timeCounter = 0; // X-axis position for charts
  List<List<FlSpot>> allSensorData = []; // Master list holding data for EVERY column

  // --- SCALABLE CHART VARIABLES ---
  List<Set<int>> activeCharts = [{1}, {5}]; // Holds settings for dynamic charts
  
  final List<Color> chartColors = [
    Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, 
    Colors.teal, Colors.brown, Colors.pink, Colors.cyan, Colors.indigo, 
    Colors.lime, Colors.deepOrange, Colors.amber, Colors.lightBlue
  ]; // Vibrant color palette

  // --- ZOOM VARIABLES ---
  double visibleMinX = 0; // Starting timeline number
  double visibleMaxX = 100; // Ending timeline number
  double startMinX = 0; // Memory for pinch math
  double startMaxX = 100; // Memory for pinch math
  double startFocalX = 0; // Tracks finger pinch center
  bool isZoomMode = true; // Tracks zoom vs tooltips

  // --- HELPER FUNCTIONS ---
  String get formattedSessionTime
  { // Calculates exactly how long the flight was based on ESP32 timestamps
    if (firstTimestamp == null || latestTimestamp == null) return "00:00"; // Fallback
    
    int differenceMs = latestTimestamp! - firstTimestamp!; // Subtract start from end
    if (differenceMs < 0) differenceMs = 0; // Safety
    
    int totalSeconds = differenceMs ~/ 1000; // Convert to seconds
    int minutes = totalSeconds ~/ 60; // Extract minutes
    int seconds = totalSeconds % 60; // Extract leftover seconds
    
    String minStr = minutes.toString().padLeft(2, '0'); // Add leading zero
    String secStr = seconds.toString().padLeft(2, '0'); // Add leading zero
    return "$minStr:$secStr"; // Format cleanly
  }

  void clearSession()
  { // Instantly wipes all memory and resets the app
    playbackTimer?.cancel(); // Kill any running replays
    
    setState(()
    { // Reset UI
      if (connectedDevice == null) connectionStatus = "Disconnected"; // Only reset text if we are not connected
      loadedFileName = "No file loaded"; // Reset file text
      totalDataRows = 0; // Reset row count
      replayRows.clear(); // Delete file from memory
      replayIndex = 0; // Reset counter
      recordedRows.clear(); // Wipe the recording memory bank
      
      firstTimestamp = null; // Wipe time
      latestTimestamp = null; // Wipe time
      
      allSensorData.clear(); // Wipe charts
      flightPath.clear(); // Wipe map
      latestDataRow.clear(); // Wipe live data
      timeCounter = 0; // Reset X-axis
      visibleMinX = 0; // Reset zoom
      visibleMaxX = 100; // Reset zoom
      currentHeading = 0.0; // Reset rotation
    });
  }

  void processDataRow(List<String> dataList)
  { // Organizes data into memory
    if (dataList.isEmpty || dataList[0].trim().isEmpty) return; // Ignore ghost rows
    
    latestDataRow = dataList; // Save entire row
    
    if (columnHeaders.isEmpty)
    { // Fallback for live Bluetooth
       columnHeaders = List.generate(dataList.length, (index) => "Sensor ${index + 1}"); // Generate generic names
       selectedSensors = List.generate(dataList.length, (index) => index).toSet(); // Select all
       allSensorData = List.generate(dataList.length, (index) => []); // Setup arrays
    }
    
    int? currentTimestamp = int.tryParse(dataList[0].trim()); // Read time
    if (currentTimestamp != null)
    { // If valid number
      firstTimestamp ??= currentTimestamp; // Set the start time ONLY once
      latestTimestamp = currentTimestamp; // Constantly update the end time
    }
    
    while (allSensorData.length < dataList.length)
    { // Safety loop for expanding data
       allSensorData.add([]); // Add new empty array
    }
    
    for (int i = 0; i < dataList.length; i++)
    { // Loop through the row
       double? val = double.tryParse(dataList[i].trim()); // Extract number
       if (val != null)
       { // If valid
          allSensorData[i].add(FlSpot(timeCounter, val)); // Save to specific sensor array
       }
    }
    
    double lat = 0.0; // GPS variable
    double lng = 0.0; // GPS variable
    if (dataList.length > 10)
    { // Read GPS safely
      lat = double.tryParse(dataList[9]) ?? 0.0; // Extract Lat
      lng = double.tryParse(dataList[10]) ?? 0.0; // Extract Lng
    }
    
    if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 && (lat != 0.0 || lng != 0.0))
    { // Save valid points
      LatLng newPoint = LatLng(lat, lng); // Create point
      if (flightPath.isNotEmpty)
      { // Math check
        const Distance distance = Distance(); // Math tool
        currentHeading = distance.bearing(flightPath.last, newPoint); // Calculate angle
      }
      flightPath.add(newPoint); // Add to map
    }
    
    timeCounter++; // Move X-axis forward
  }

  // --- EXPORT LOGIC ---
  Future<void> saveFlightData() async
  { // Automatically compiles and saves the recorded Bluetooth flight
    if (recordedRows.isEmpty) return; // Ignore if no data was collected
    
    DateTime now = DateTime.now(); // Get the current exact time
    String yyyy = now.year.toString(); // Year
    String mm = now.month.toString().padLeft(2, '0'); // Month
    String dd = now.day.toString().padLeft(2, '0'); // Day
    String hr = now.hour.toString().padLeft(2, '0'); // Hour
    String min = now.minute.toString().padLeft(2, '0'); // Minute
    String sec = now.second.toString().padLeft(2, '0'); // Second
    
    String fileName = "Replay_${yyyy}_${mm}_${dd}_$hr-$min-$sec.csv"; // Requested file name format
    
    String fileHeader = "${columnHeaders.join(',')}\n"; // Build the header row
    String fileBody = recordedRows.join('\n'); // Build the data block
    String fullFile = "$fileHeader$fileBody"; // Combine them
    
    Uint8List fileBytes = Uint8List.fromList(utf8.encode(fullFile)); // MAGIC FIX: Convert text to raw bytes
    
    try
    { // Safely attempt to save without crashing
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save Flight Data', // Dialog header
        fileName: fileName, // Inject name
        type: FileType.custom, // Custom extension
        allowedExtensions: ['csv'], // Lock to CSV
        bytes: fileBytes, // Let Android handle the writing natively
      );
    }
    catch (e)
    { // Ignore if user cancels or permission denies
    }
  }

  // --- BLUETOOTH LOGIC ---
  void startScan() async
  { // Start scanning
    setState(()
    { // Update UI
      connectionStatus = "Scanning..."; // Status
    });
    
    var subscription = FlutterBluePlus.onScanResults.listen((results)
    { // Listen
      for (ScanResult r in results)
      { // Loop
        if (r.device.advName == "ESP32_FlightLogger")
        { // Match
          FlutterBluePlus.stopScan(); // Stop
          connectToDevice(r.device); // Connect
          break; // Stop checking
        }
      }
    });

    await FlutterBluePlus.startScan(withServices: const [], timeout: const Duration(seconds: 4)); // Scan
    
    subscription.cancel(); // Clean up listener
    
    setState(()
    { // Check timeout
      if (connectionStatus == "Scanning...")
      { // Never found
        connectionStatus = "Device not found, try again"; // Prompt user
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async
  { // Handle connection
    setState(()
    { // Instantly update
      connectionStatus = "Connecting..."; // Status
    });
    
    try
    { // Try block
      await device.connect(license: License.free); // Pair
      
      clearSession(); // Clean memory before starting
      
      setState(()
      { // Update UI
        connectedDevice = device; // Save device
        connectionStatus = "Connected to FlightLogger!"; // Success
      });
      
      List<BluetoothService> services = await device.discoverServices(); // Get services
      
      for (BluetoothService service in services)
      { // Loop services
        if (service.uuid.toString() == "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
        { // Match service
          for (BluetoothCharacteristic characteristic in service.characteristics)
          { // Loop characteristics
            if (characteristic.uuid.toString() == "beb5483e-36e1-4688-b7f5-ea07361b26a8")
            { // Match data
              await characteristic.setNotifyValue(true); // Start stream
              
              bleStream = characteristic.onValueReceived.listen((value)
              { // MAGIC FIX: Save the active stream to our variable
                String csvString = String.fromCharCodes(value); // Decode
                recordedRows.add(csvString.trim()); // Save raw string
                
                List<String> dataList = csvString.split(','); // Chop
                
                setState(()
                { // Update
                  processDataRow(dataList); // Process
                  if (!isZoomMode) visibleMaxX = timeCounter; // Auto scroll
                  
                  if (flightPath.isNotEmpty && _selectedTab == 2 && mapLoaded)
                  { // Camera logic
                    try 
                    { // Try move
                      mapController.move(flightPath.last, mapController.camera.zoom); // Move
                    } catch (e) { /* Ignore */ }
                  }
                });
              });
            }
          }
        }
      }
    }
    catch (e)
    { // Error block
      setState(()
      { // Update UI
        connectionStatus = "Connection Failed"; // Status
        connectedDevice = null; // Clear failure
      });
    }
  }

  Future<void> disconnectFromDevice() async
  { // Safely cuts the Bluetooth connection and saves data
    try
    { // Try block catches background crashes
      if (connectedDevice != null)
      { // If we actually have a device
        await bleStream?.cancel(); // MAGIC FIX: Kill the incoming data stream instantly!
        await connectedDevice!.disconnect(); // Tell the phone to disconnect the radio
        await saveFlightData(); // Trigger the save dialog safely AFTER dropping the connection
      }
    }
    catch (e)
    { // Silently ignore native errors
    }
    finally
    { // This ALWAYS executes
      setState(()
      { // Update UI
        connectedDevice = null; // Clear memory
        connectionStatus = "Disconnected"; // Update text
      });
    }
  }

  // --- FILE PICKER & REPLAY LOGIC ---
  void pickCSVFile() async
  { // Pick file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // Custom
      allowedExtensions: ['csv'], // CSV only
    );

    if (result != null)
    { // If selected
      String filePath = result.files.single.path!; // Path
      File dataFile = File(filePath); // File
      String fileContents = await dataFile.readAsString(); // Read contents
      
      clearSession(); // Clean memory
      
      setState(()
      { // Setup
        fileContents = fileContents.replaceAll('\r', ''); // Clean Windows returns
        fileContents = fileContents.replaceAll(';', ','); // Convert semicolons
        
        replayRows = fileContents.split('\n'); // Chop rows
        replayRows.removeWhere((row) => row.trim().isEmpty); // Delete empty rows
        
        if (replayRows.isEmpty) return; // Safety check
        
        List<String> firstRow = replayRows[0].split(','); // Look at first row
        
        if (num.tryParse(firstRow[0].trim()) != null)
        { // Old file without headers
          columnHeaders = []; // Clear
          for (int i = 0; i < firstRow.length; i++)
          { // Build dynamic headers
            if (i == 0) columnHeaders.add("Time/ID");
            else if (i == 1) columnHeaders.add("Temp 1 (°C)");
            else if (i == 5) columnHeaders.add("Engine RPM");
            else if (i == 9) columnHeaders.add("Latitude");
            else if (i == 10) columnHeaders.add("Longitude");
            else if (i == 11) columnHeaders.add("Battery (V)");
            else columnHeaders.add("Sensor ${i + 1}"); // Fallback
          }
          replayIndex = 0; // Start at row 0
        }
        else
        { // Proper header exists
          columnHeaders = firstRow; // Use text
          replayIndex = 1; // Skip row 0
        }
        
        selectedSensors = List.generate(columnHeaders.length, (index) => index).toSet(); // Select all
        allSensorData = List.generate(columnHeaders.length, (index) => []); // Setup memory
        
        loadedFileName = result.files.single.name; // Save name
        totalDataRows = replayRows.length; // Save count
      });
      
      startReplay(); // Play
    } 
  }

  void startReplay()
  { // Start playback
    playbackTimer?.cancel(); // Kill old timer
    
    playbackTimer = Timer.periodic(const Duration(milliseconds: 250), (timer)
    { // Loop
      if (replayIndex < replayRows.length)
      { // If running
        List<String> dataList = replayRows[replayIndex].split(','); // Chop
        
        setState(()
        { // Update
          processDataRow(dataList); // Process
          
          if (flightPath.isNotEmpty && _selectedTab == 2 && mapLoaded)
          { // Camera logic
            try 
            { // Try move
              mapController.move(flightPath.last, mapController.camera.zoom); // Move
            } catch (e) { /* Ignore */ }
          }
        });
        
        replayIndex++; // Increment
      }
      else
      { // End
        timer.cancel(); // Stop
      }
    });
  }

  void skipReplay()
  { // Fast forward
    playbackTimer?.cancel(); // Kill timer
    
    for (int i = replayIndex; i < replayRows.length; i++)
    { // Loop remaining
      List<String> dataList = replayRows[i].split(','); // Chop
      processDataRow(dataList); // Process
    }
    
    setState(()
    { // Update UI
       replayIndex = replayRows.length; // Max out
       visibleMinX = 0; // Reset zoom
       visibleMaxX = timeCounter > 0 ? timeCounter : 100; // Reset zoom
    });
  }

  // --- DYNAMIC CHART FUNCTIONS ---
  void addNewChart()
  { // Adds a brand new chart card
    setState(()
    { // Update UI
      activeCharts.add({1}); // Add a new chart
    });
  }

  void deleteChart(int index)
  { // Deletes a specific chart card
    setState(()
    { // Update UI
      activeCharts.removeAt(index); // Remove it
    });
  }

  void openSingleChartConfigurator(int chartIndex)
  { // Configures ONE specific chart
    showDialog(
      context: context,
      builder: (BuildContext context)
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
                  itemCount: columnHeaders.length, // Total sensors
                  itemBuilder: (context, idx)
                  { // Build row
                    return CheckboxListTile(
                      title: Text(columnHeaders[idx], style: TextStyle(color: chartColors[idx % chartColors.length], fontWeight: FontWeight.bold)), // Color text
                      value: activeCharts[chartIndex].contains(idx), // Checked?
                      onChanged: (bool? val)
                      { // Clicked
                        setDialogState(()
                        { // Update popup
                          if (val == true) activeCharts[chartIndex].add(idx); // Add
                          else activeCharts[chartIndex].remove(idx); // Remove
                        });
                        setState((){}); // Redraw charts
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

  void openSensorSelector()
  { // Live Data configurator
    showDialog(
      context: context,
      builder: (BuildContext context)
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
                  itemCount: columnHeaders.length, // Total sensors
                  itemBuilder: (context, index)
                  { // Build row
                    return CheckboxListTile(
                      title: Text(columnHeaders[index]), // Name
                      value: selectedSensors.contains(index), // Checked?
                      onChanged: (bool? checked)
                      { // Clicked
                        setDialogState(()
                        { // Update popup
                          if (checked == true) selectedSensors.add(index); // Add
                          else selectedSensors.remove(index); // Remove
                        });
                        setState(() {}); // Redraw
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

  // --- UI RENDERING ---
  @override
  Widget build(BuildContext context)
  { // Main build
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Analyzer'), // Title
      ),
      body: IndexedStack(
        index: _selectedTab, // Tab control
        children: [
          buildDashboardTab(), // Index 0
          buildAnalysisTab(), // Index 1
          mapLoaded ? buildMapTab() : const SizedBox(), // Index 2
          buildLiveDataTab(), // Index 3
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab, // Active index
        type: BottomNavigationBarType.fixed, // Prevent hiding
        onTap: (index)
        { // Tapped
          setState(()
          { // Update
            _selectedTab = index; // Switch
            if (index == 2) mapLoaded = true; // Boot map
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'), // Btn 0
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Analysis'), // Btn 1
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'), // Btn 2
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Live Data'), // Btn 3
        ],
      ),
    );
  }

  Widget buildDashboardTab()
  { // Dashboard UI
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Vertically
        children: [
          Text(connectionStatus, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)), // Status
          const SizedBox(height: 40), // Spacing
          
          const Text('Session Duration', style: TextStyle(fontSize: 20, color: Colors.grey)), // Time Label
          Text(formattedSessionTime, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)), // Time Counter
          const SizedBox(height: 40), // Spacing
          
          if (connectedDevice == null)
            ElevatedButton(
              onPressed: startScan, // Scan
              child: const Padding(
                padding: EdgeInsets.all(12.0), // Padding
                child: Text('Connect to ESP32', style: TextStyle(fontSize: 20)), // Text
              ),
            )
          else
            ElevatedButton(
              onPressed: disconnectFromDevice, // Disconnect
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
              if (connectedDevice != null)
              { // If we are connected to Bluetooth, save and disconnect first
                await disconnectFromDevice();
              }
              pickCSVFile(); // Open the file picker
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green), // Green
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Padding
              child: Text(connectedDevice == null ? 'Load Saved CSV File' : 'Disconnect and load saved csv file', style: const TextStyle(fontSize: 20, color: Colors.white)), // Dynamic Text
            ),
          ),
          const SizedBox(height: 10), // Spacing
          
          if (totalDataRows > 0 && replayIndex < totalDataRows)
            ElevatedButton(
              onPressed: skipReplay, // Skip
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), // Orange
              child: const Padding(
                padding: EdgeInsets.all(8.0), // Padding
                child: Text('Skip Replay', style: TextStyle(fontSize: 16, color: Colors.white)), // Text
              ),
            ),
            
          const SizedBox(height: 20), // Spacing
          
          ElevatedButton.icon(
            onPressed: clearSession, // Wipe app
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Red color
            icon: const Icon(Icons.delete_forever, color: Colors.white), // Trash icon
            label: const Text('Clear Session', style: TextStyle(color: Colors.white)), // Text
          ),
          
          const SizedBox(height: 20), // Spacing
          
          if (totalDataRows > 0) ...[
            Text('File: $loadedFileName', style: const TextStyle(fontSize: 16)), // Name
            Text('Data Rows: $totalDataRows', style: const TextStyle(fontSize: 16)), // Rows
          ],
        ],
      ),
    );
  }

  Widget buildChartLegend(Set<int> sensorsToDraw)
  { // Helper to draw colored text labels
    if (sensorsToDraw.isEmpty) return const Text('Tap the Gear Icon to assign sensors', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)); // Fallback
    
    return Wrap(
      spacing: 12, // Horizontal gap
      runSpacing: 4, // Vertical gap
      children: sensorsToDraw.map((idx)
      { // Loop
        String name = idx < columnHeaders.length ? columnHeaders[idx] : "Sensor ${idx + 1}"; // Pull name
        Color lineCol = chartColors[idx % chartColors.length]; // Pull color
        
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

  Widget buildAnalysisTab()
  { // Completely rebuilt, infinitely scrolling charts screen
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
                    value: isZoomMode, // Links switch
                    activeThumbColor: Colors.blue, // Blue
                    inactiveThumbColor: Colors.red, // Red
                    onChanged: (value)
                    { // Flipped
                      setState(() { isZoomMode = value; }); // Redraw
                    },
                  ),
                  const Text('✋', style: TextStyle(fontSize: 18)), // Pan/Zoom
                ],
              ),
              ElevatedButton.icon(
                onPressed: addNewChart, // Add chart button
                icon: const Icon(Icons.add), // Plus
                label: const Text('Add Chart'), // Text
              ),
            ],
          ),
          const SizedBox(height: 10), // Spacing
          
          Expanded(
            child: activeCharts.isEmpty 
              ? const Center(child: Text('No charts! Click "Add Chart" to start.', style: TextStyle(fontSize: 18, color: Colors.grey))) // Fallback
              : ListView.builder(
                  itemCount: activeCharts.length, // Total dynamic charts
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
                                 Expanded(child: buildChartLegend(activeCharts[index])), // Dynamic legend
                                 Row(
                                   children: [
                                     IconButton(
                                       icon: const Icon(Icons.settings, color: Colors.blue), // Gear
                                       onPressed: () => openSingleChartConfigurator(index), // Configurator
                                     ),
                                     IconButton(
                                       icon: const Icon(Icons.delete, color: Colors.red), // Trash
                                       onPressed: () => deleteChart(index), // Delete
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
                                      onScaleStart: isZoomMode ? (details)
                                      { // Down
                                        startMinX = visibleMinX; // Math
                                        startMaxX = visibleMaxX; // Math
                                        startFocalX = details.localFocalPoint.dx; // Math
                                      } : null, // Disable
                                      onScaleUpdate: isZoomMode ? (details)
                                      { // Moving
                                        setState(()
                                        { // Calculate
                                          double currentRange = startMaxX - startMinX; // Range
                                          double newRange = currentRange / details.scale; // Stretch
                                          double focalPercent = startFocalX / screenWidth; // Pinch center
                                          double focalDataX = startMinX + (currentRange * focalPercent); // Data center
                                          double currentFocalPercent = details.localFocalPoint.dx / screenWidth; // Pan
                                          
                                          visibleMinX = focalDataX - (newRange * currentFocalPercent); // Math
                                          visibleMaxX = visibleMinX + newRange; // Math
                                          double maxDataX = timeCounter > 100 ? timeCounter : 100; // Limit

                                          if (visibleMinX < 0) visibleMinX = 0; // Lock left
                                          if (visibleMaxX > maxDataX) visibleMaxX = maxDataX; // Lock right
                                          if (visibleMinX == 0) visibleMaxX = visibleMinX + newRange; // Bounce left
                                          if (visibleMaxX == maxDataX) visibleMinX = visibleMaxX - newRange; // Bounce right
                                          if (visibleMaxX - visibleMinX < 10) visibleMaxX = visibleMinX + 10; // Zoom limit
                                          if (visibleMinX < 0) visibleMinX = 0; // Final safety
                                          if (visibleMaxX > maxDataX) visibleMaxX = maxDataX; // Final safety
                                        });
                                      } : null, // Disable
                                      child: LineChart(
                                        LineChartData(
                                          minX: visibleMinX, // Shared Math
                                          maxX: visibleMaxX, // Shared Math
                                          lineTouchData: LineTouchData(enabled: !isZoomMode), // Tooltips
                                          clipData: const FlClipData.all(), // Clip bounds
                                          titlesData: const FlTitlesData(
                                            show: true, // Labels
                                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide
                                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide
                                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)), // X Axis
                                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)), // Y Axis
                                          ),
                                          lineBarsData: activeCharts[index].where((idx) => idx < allSensorData.length).map((idx)
                                          { // Map ticked sensors to line drawers
                                            return LineChartBarData(
                                              spots: allSensorData[idx], // Array
                                              isCurved: false, // Straight
                                              color: chartColors[idx % chartColors.length], // Color
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

Widget buildMapTab()
  { // Map UI wrapped in a Stack to support overlays
    return Stack(
      children: [
        
        FlutterMap(
          mapController: mapController, // Controller
          options: MapOptions(
            initialCenter: flightPath.isNotEmpty ? flightPath.last : const LatLng(54.3233, 10.1228), // Center
            initialZoom: 16.0, // Zoom
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', // Satellite
              userAgentPackageName: 'com.example.esp32flight_datalogger', // User Agent
            ),
            
            if (flightPath.length > 1) 
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: flightPath, // GPS Data
                    color: Colors.blue, // Blue
                    strokeWidth: 4.0, // Thick
                  ),
                ],
              ),
              
            if (flightPath.isNotEmpty)
              MarkerLayer(
                markers: [
                  Marker(
                    point: flightPath.last, // Center
                    width: 40,
                    height: 40,
                    child: Transform.rotate(
                      angle: currentHeading * (3.14159 / 180), // Math rotation
                      child: const Icon(Icons.flight, color: Colors.red, size: 40), // Plane
                    ),
                  ),
                ],
              ),
          ],
        ),
        
        // UPGRADED 8-POINT COMPASS OVERLAY
        Positioned(
          top: 16, // Lock to top
          right: 16, // Lock to right
          child: GestureDetector(
            onTap: ()
            { // Clicked
              mapController.rotate(0.0); // Snap map back to exactly North
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white70, // Semi-transparent white backing
                shape: BoxShape.circle, // Make it round
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)], // Drop shadow
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0), // Smaller padding to maximize compass size
                child: StreamBuilder<MapEvent>(
                  stream: mapController.mapEventStream, // Listens directly to map movements
                  builder: (context, snapshot)
                  { // Redraws just the compass when the map spins
                    double currentRotation = 0.0; // Default to North
                    try
                    { // Attempt to read the camera
                       currentRotation = mapController.camera.rotation; // Get rotation in degrees
                    }
                    catch (e) { /* Ignore if map isn't fully built yet */ }
                    
                    return Transform.rotate(
                      angle: -currentRotation * (3.14159 / 180), // Counter-rotate so it always points North
                      child: CustomPaint(
                        size: const Size(80, 80), // Made it much larger to show the details!
                        painter: ClassicCompassNeedlePainter(), // Calls our new detailed drawing
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
  Widget buildLiveDataTab()
  { // Live Data UI
    List<int> displayIndices = selectedSensors.toList()..sort(); // Sort

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
                onPressed: openSensorSelector, // Open Menu
              ),
            ],
          ),
          const SizedBox(height: 10), // Gap
          
          Expanded(
            child: latestDataRow.isEmpty
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
                      if (dataIndex >= latestDataRow.length) return const SizedBox(); // Safety
                      String label = dataIndex < columnHeaders.length ? columnHeaders[dataIndex] : "Sensor ${dataIndex + 1}"; // Label
                      
                      return Card(
                        elevation: 3, // Shadow
                        color: Colors.white, // BG
                        child: Padding(
                          padding: const EdgeInsets.all(8.0), // Inner Pad
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, // Center
                            children: [
                              Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey), overflow: TextOverflow.ellipsis), // Name
                              Text(latestDataRow[dataIndex], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Value
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