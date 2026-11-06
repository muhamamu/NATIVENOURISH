import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'food_search_screen.dart';
import 'activity_screen.dart';
import 'summary_screen.dart';
import 'profile_screen.dart';
import '../widgets/animated_pill_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    FoodSearchScreen(),
    ActivityScreen(),
    SummaryScreen(),
    ProfileScreen(),
  ];

  final List<NavItem> _navItems = const [
    NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Dashboard',
    ),
    NavItem(
      icon: Icons.restaurant_menu_outlined,
      activeIcon: Icons.restaurant_menu_rounded,
      label: 'Food Log',
    ),
    NavItem(
      icon: Icons.directions_run_outlined,
      activeIcon: Icons.directions_run_rounded,
      label: 'Activity',
    ),
    NavItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
      label: 'Trends',
    ),
    NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: AnimatedPillNavBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: _navItems,
        ),
      ),
    );
  }
}
