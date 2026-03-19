import 'package:flutter/material.dart'; // Core UI
import 'package:provider/provider.dart'; // State management
import '../providers/app_state.dart'; // The Brain

import 'tabs/dashboard_tab.dart'; // Dashboard UI
import 'tabs/analysis_tab.dart'; // Analysis UI
import 'tabs/map_tab.dart'; // Map UI
import 'tabs/live_data_tab.dart'; // Live Data UI

class HomeScreen extends StatelessWidget
{ // Main navigation layout
  const HomeScreen({super.key}); // Constructor

  @override
  Widget build(BuildContext context)
  { // Build layout
    final appState = Provider.of<AppState>(context); // Connect to the Brain

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Analyzer'), // App bar title
      ),
      body: IndexedStack(
        index: appState.selectedTab, // Read current tab from Brain
        children: const [
          DashboardTab(), // Index 0
          AnalysisTab(), // Index 1
          MapTab(), // Index 2
          LiveDataTab(), // Index 3
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: appState.selectedTab, // Read active index
        type: BottomNavigationBarType.fixed, // Prevent hiding
        onTap: (index)
        { // Tab clicked
          appState.setTab(index); // Tell Brain to switch tabs
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
}