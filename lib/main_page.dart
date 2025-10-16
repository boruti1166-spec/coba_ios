import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/pelatihan_page.dart';
import 'pages/ujian_page.dart';
import 'pages/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildNavigator(GlobalKey<NavigatorState> key, Widget page) {
    return Navigator(
      key: key,
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(builder: (context) => page);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab =
        !await _navigatorKeys[_selectedIndex].currentState!.maybePop();

        if (isFirstRouteInCurrentTab) {
          return true; // keluar app
        }
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Offstage(
              offstage: _selectedIndex != 0,
              child: _buildNavigator(_navigatorKeys[0], const HomePage()),
            ),
            Offstage(
              offstage: _selectedIndex != 1,
              child: _buildNavigator(_navigatorKeys[1], const PelatihanPage()),
            ),
            Offstage(
              offstage: _selectedIndex != 2,
              child: _buildNavigator(_navigatorKeys[2], const UjianPage()),
            ),
            Offstage(
              offstage: _selectedIndex != 3,
              child: _buildNavigator(_navigatorKeys[3], const ProfilePage()),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.school), label: "Pelatihan"),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Ujian"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
