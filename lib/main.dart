import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';

void main()
{ // Boot sequence
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()), // Inject the Brain into the app
      ],
      child: const FlightLoggerApp(), // Run the app
    ),
  );
}

class FlightLoggerApp extends StatelessWidget
{ // Root application widget
  const FlightLoggerApp({super.key}); // Constructor

  @override
  Widget build(BuildContext context)
  { // Build root
    return MaterialApp(
      title: 'ESP32 Flight Logger', // App title
      theme: ThemeData(
        primarySwatch: Colors.blue, // Theme color
        useMaterial3: true, // Modern UI elements
      ),
      home: const SplashScreen(), // Load the splash screen layout
    );
  }
}