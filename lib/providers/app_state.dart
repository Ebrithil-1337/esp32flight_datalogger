import 'package:flutter/material.dart'; // Core UI and ChangeNotifier
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Bluetooth
import 'package:flutter_map/flutter_map.dart'; // Map controller
import 'package:latlong2/latlong.dart' hide Path; // GPS math
import 'package:fl_chart/fl_chart.dart'; // Charts
import 'dart:async'; // Timers
import 'dart:convert'; // UTF8
import 'dart:typed_data'; // Bytes
import 'package:file_picker/file_picker.dart'; // File picking
import 'dart:io'; // File saving
import 'package:flutter_tts/flutter_tts.dart'; // Imports the TTS engine
import 'package:shared_preferences/shared_preferences.dart'; // Local storage for saving settings



class AppState extends ChangeNotifier
{ // The central brain holding all variables and logic

  // --- DASHBOARD VARIABLES ---
  String connectionStatus = "Disconnected"; // Shows if paired
  BluetoothDevice? connectedDevice; // Remembers the active ESP32 connection
  StreamSubscription<List<int>>? bleStream; // Saves the data stream

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
  int selectedTab = 0; // Tab index tracker

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

  // --- TTS VARIABLES ---
  FlutterTts flutterTts = FlutterTts(); // Creates the speech engine
  bool hasAlertedLowVoltage = false; // Prevents the voice from spamming

  double voltageThreshold = 11.0; // Voltage level to trigger the alert
  bool audibleAlertsEnabled = true; // Master switch for all voice alerts

  // --- Language Variables ---
  bool isAppInGerman = false; // Tracks the active UI language



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

  AppState()
  { // This runs automatically when the app starts
    _loadSavedSettings(); // Ask the phone for the saved configuration
  }
Map<int, String> customSensorNames = {}; // Stores custom names by index

  Future<void> _loadSavedSettings() async
  { // Pulls settings from the phone's hard drive
    final prefs = await SharedPreferences.getInstance(); // Open storage
    voltageThreshold = prefs.getDouble('voltageThreshold') ?? 11.0; // Load voltage
    isAppInGerman = prefs.getBool('isAppInGerman') ?? false; // Load language
    audibleAlertsEnabled = prefs.getBool('audibleAlertsEnabled') ?? true; // Load master switch
    
    String? namesJson = prefs.getString('customSensorNames'); // Load names string
    if (namesJson != null)
    { // If custom names exist
      Map<String, dynamic> decoded = jsonDecode(namesJson); // Decode JSON
      customSensorNames = decoded.map((k, v) => MapEntry(int.parse(k), v.toString())); // Parse back to integer map
    }
    notifyListeners(); // Refresh UI
  }

  String getSensorName(int index)
  { // Retrieves the display name
    if (customSensorNames.containsKey(index)) return customSensorNames[index]!; // Return customized name
    if (index < columnHeaders.length) return columnHeaders[index]; // Return CSV name
    return "Sensor ${index + 1}"; // Fallback
  }

  Future<void> updateSensorName(int index, String newName) async
  { // Saves the customized name
    if (newName.trim().isEmpty)
    { // If blank, reset to default CSV name
      customSensorNames.remove(index); // Remove from map
    }
    else
    { // Otherwise update
      customSensorNames[index] = newName.trim(); // Save to map
    }
    final prefs = await SharedPreferences.getInstance(); // Open storage
    await prefs.setString('customSensorNames', jsonEncode(customSensorNames.map((k, v) => MapEntry(k.toString(), v)))); // Save map as JSON
    notifyListeners(); // Refresh UI everywhere instantly
  }

  void toggleAudibleAlerts(bool value) async
  { // Master switch toggle
    audibleAlertsEnabled = value; // Update active memory
    final prefs = await SharedPreferences.getInstance(); // Open storage
    await prefs.setBool('audibleAlertsEnabled', value); // Save to hard drive
    notifyListeners(); // Refresh UI
  }

  Future<void> setVoltageThreshold(double newThreshold) async
  { // Saves the user's custom voltage limit
    voltageThreshold = newThreshold; // Update active memory
    final prefs = await SharedPreferences.getInstance(); // Open storage
    await prefs.setDouble('voltageThreshold', newThreshold); // Save to hard drive
    notifyListeners(); // Refresh UI
  }

  void toggleLanguage() async
  { // Switches global language and saves it
    isAppInGerman = !isAppInGerman; // Flip the boolean
    final prefs = await SharedPreferences.getInstance(); // Open storage
    await prefs.setBool('isAppInGerman', isAppInGerman); // Save to hard drive
    notifyListeners(); // Refresh UI everywhere instantly
  }

  final Map<String, Map<String, String>> _dictionary = { // The translation memory bank
    'Flight Analyzer': {'en': 'Flight Analyzer', 'de': 'Flight Analyzer'},
    'Dashboard': {'en': 'Dashboard', 'de': 'Dashboard'},
    'Analysis': {'en': 'Analysis', 'de': 'Analyse'},
    'Map': {'en': 'Map', 'de': 'Karte'},
    'Live Data': {'en': 'Live Data', 'de': 'Live-Daten'},
    'Session Duration': {'en': 'Session Duration', 'de': 'Sitzungsdauer'},
    'Connect to ESP32': {'en': 'Connect to ESP32', 'de': 'Mit ESP32 verbinden'},
    'Disconnect': {'en': 'Disconnect', 'de': 'Trennen'},
    'Load Saved CSV File': {'en': 'Load Saved CSV', 'de': 'Gespeicherte CSV laden'},
    'Clear Session': {'en': 'Clear Session', 'de': 'Sitzung daten löschen'},
    'Test Audio': {'en': 'Test Audio', 'de': 'Audio testen'},
    'Dashboard Settings': {'en': 'Dashboard Settings', 'de': 'Dashboard-Einstellungen'},
    'Voltage Warning Threshold (V)': {'en': 'Voltage Warning Threshold (V)', 'de': 'Spannungswarnung (V)'},
    'Enable Audible Alerts': {'en': 'Enable Audible Alerts', 'de': 'Akustische Warnungen aktivieren'},
    'Master toggle for all voice warnings': {'en': 'Master toggle for all voice warnings', 'de': 'Hauptschalter für alle Sprachwarnungen'},
    'Close': {'en': 'Close', 'de': 'Schließen'},
  };

  String tr(String key)
  { // Translates a string based on the current language
    if (!_dictionary.containsKey(key)) return key; // Return original if not found in dictionary
    return _dictionary[key]![isAppInGerman ? 'de' : 'en'] ?? key; // Return translated string
  }

  void setTab(int index)
  { // Updates the active tab
    selectedTab = index; // Switch
    if (index == 2) mapLoaded = true; // Boot map
    notifyListeners(); // Update UI
  }

  void setZoomMode(bool value)
  { // Toggles pan and zoom
    isZoomMode = value; // Update
    notifyListeners(); // Update UI
  }

  void updateZoom(double minX, double maxX)
  { // Updates math for zooming
    visibleMinX = minX; // Set left edge
    visibleMaxX = maxX; // Set right edge
    notifyListeners(); // Update UI
  }

  void clearSession()
  { // Instantly wipes all memory and resets the app
    playbackTimer?.cancel(); // Kill any running replays

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

    notifyListeners(); // Update UI
  }

  void processDataRow(List<String> dataList, {bool isReplay = false})
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
if (dataList.length > 11)
    { // Make sure the row actually has the battery column
      double? batteryV = double.tryParse(dataList[11].trim()); // Extract voltage (Column 11)
      if (batteryV != null)
      { // If it is a valid number
        if (batteryV <= voltageThreshold && !hasAlertedLowVoltage)
        { // Custom threshold hit and we haven't locked yet
          if (!isReplay && audibleAlertsEnabled) triggerVoltageAlert(batteryV); // Speak ONLY if it's live AND alerts are on
          hasAlertedLowVoltage = true; // Lock the state so visual alerts (later) still work correctly
        }
        else if (batteryV >= voltageThreshold + 0.2)
        { // Hysteresis: Unlock the warning if voltage recovers
          hasAlertedLowVoltage = false; // Unlock
        }
      }
    }

    timeCounter++; // Move X-axis forward
  }

  Future<void> triggerVoltageAlert(double voltage) async
  { // The function that actually talks
    await flutterTts.setVolume(1.0); // Max volume
    await flutterTts.setPitch(1.0); // Normal voice pitch
    
    if (isAppInGerman)
    { // German callout
      await flutterTts.setLanguage("de-DE"); // Set German
      await flutterTts.speak("Achtung. Batteriespannung ist kritisch bei $voltage Volt."); // German phrase
    }
    else
    { // English callout
      await flutterTts.setLanguage("en-US"); // Set English
      await flutterTts.speak("Warning. Battery voltage is critical at $voltage volts."); // English phrase
    }
  }

  Future<void> testTTS() async
  { // Manual debug trigger for the voice engine
    if (!audibleAlertsEnabled) return; // Exit immediately if the master switch is turned off
    
    await flutterTts.setVolume(1.0); // Max volume
    await flutterTts.setPitch(1.0); // Normal pitch
    
    if (isAppInGerman)
    { // German test
      await flutterTts.setLanguage("de-DE"); // Set German
      await flutterTts.speak("Audiosystem ist online und bereit."); // German phrase
    }
    else
    { // English test
      await flutterTts.setLanguage("en-US"); // Set English
      await flutterTts.speak("Audio system is online and ready."); // English phrase
    }
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

    Uint8List fileBytes = Uint8List.fromList(utf8.encode(fullFile)); // Convert text to raw bytes

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
    connectionStatus = "Scanning..."; // Status
    notifyListeners(); // Update UI

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

    if (connectionStatus == "Scanning...")
    { // Never found
      connectionStatus = "Device not found, try again"; // Prompt user
      notifyListeners(); // Update UI
    }
  }

  void connectToDevice(BluetoothDevice device) async
  { // Handle connection
    connectionStatus = "Connecting..."; // Status
    notifyListeners(); // Update UI

    try
    { // Try block
      await device.connect(license: License.free); // Pair

      clearSession(); // Clean memory before starting

      connectedDevice = device; // Save device
      connectionStatus = "Connected to FlightLogger!"; // Success
      notifyListeners(); // Update UI

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
              { // Save the active stream to our variable
                String csvString = String.fromCharCodes(value); // Decode
                recordedRows.add(csvString.trim()); // Save raw string

                List<String> dataList = csvString.split(','); // Chop

                processDataRow(dataList); // Process
                if (!isZoomMode) visibleMaxX = timeCounter; // Auto scroll

                if (flightPath.isNotEmpty && selectedTab == 2 && mapLoaded)
                { // Camera logic
                  try
                  { // Try move
                    mapController.move(flightPath.last, mapController.camera.zoom); // Move
                  } catch (e) { /* Ignore */ }
                }
                notifyListeners(); // Update UI
              });
            }
          }
        }
      }
    }
    catch (e)
    { // Error block
      connectionStatus = "Connection Failed"; // Status
      connectedDevice = null; // Clear failure
      notifyListeners(); // Update UI
    }
  }

  Future<void> disconnectFromDevice() async
  { // Safely cuts the Bluetooth connection and saves data
    try
    { // Try block catches background crashes
      if (connectedDevice != null)
      { // If we actually have a device
        await bleStream?.cancel(); // Kill the incoming data stream instantly
        await connectedDevice!.disconnect(); // Tell the phone to disconnect the radio
        await saveFlightData(); // Trigger the save dialog safely
      }
    }
    catch (e)
    { // Silently ignore native errors
    }
    finally
    { // This ALWAYS executes
      connectedDevice = null; // Clear memory
      connectionStatus = "Disconnected"; // Update text
      notifyListeners(); // Update UI
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
          if (i == 0) {columnHeaders.add("Time/ID");}
          else if (i == 1) {columnHeaders.add("Temp 1 (°C)");}
          else if (i == 5) {columnHeaders.add("Engine RPM");}
          else if (i == 9) {columnHeaders.add("Latitude");}
          else if (i == 10) {columnHeaders.add("Longitude");}
          else if (i == 11) {columnHeaders.add("Battery (V)");}
          else {columnHeaders.add("Sensor ${i + 1}");} // Fallback
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

      notifyListeners(); // Update UI

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

        processDataRow(dataList, isReplay: true); // Process as a replay so audio is muted

        if (flightPath.isNotEmpty && selectedTab == 2 && mapLoaded)
        { // Camera logic
          try
          { // Try move
            mapController.move(flightPath.last, mapController.camera.zoom); // Move
          } catch (e) { /* Ignore */ }
        }
        replayIndex++; // Increment
        notifyListeners(); // Update UI
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
      processDataRow(dataList, isReplay: true); // Process as a replay so audio is muted
    }

    replayIndex = replayRows.length; // Max out
    visibleMinX = 0; // Reset zoom
    visibleMaxX = timeCounter > 0 ? timeCounter : 100; // Reset zoom
    notifyListeners(); // Update UI
  }

  // --- DYNAMIC CHART FUNCTIONS ---
  void addNewChart()
  { // Adds a brand new chart card
    activeCharts.add({1}); // Add a new chart
    notifyListeners(); // Update UI
  }

  void deleteChart(int index)
  { // Deletes a specific chart card
    activeCharts.removeAt(index); // Remove it
    notifyListeners(); // Update UI
  }

  void updateChartSensors(int chartIndex, int sensorIndex, bool isAdding)
  { // Configures ONE specific chart
    if (isAdding) {activeCharts[chartIndex].add(sensorIndex);} // Add
    else {activeCharts[chartIndex].remove(sensorIndex);} // Remove
    notifyListeners(); // Update UI
  }

  void updateLiveSensors(int sensorIndex, bool isAdding)
  { // Updates selected sensors for Live Data Tab
    if (isAdding) {selectedSensors.add(sensorIndex);} // Add
    else {selectedSensors.remove(sensorIndex);} // Remove
    notifyListeners(); // Update UI
  }
  
}