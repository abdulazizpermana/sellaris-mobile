import 'package:flutter/material.dart';
import 'package:sellari_umkm_frontend/features/auth/presentation/pages/dashboard_page.dart';
import 'package:sellari_umkm_frontend/features/auth/presentation/pages/product_page.dart';
import 'package:sellari_umkm_frontend/features/ai/presentation/pages/ai_studio_page.dart';
import 'package:sellari_umkm_frontend/features/profile/presentation/pages/profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _tabs = ['Dashboard', 'AI Studio', 'Produk', 'Profil'];

  List<Widget> get _pages => const [
        DashboardPage(),
        AiStudioPage(),
        ProductPage(),
        ProfilePage(),
      ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _pages),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _onTabSelected(1),
      //   icon: const Icon(Icons.auto_awesome_rounded),
      //   label: const Text('Generate AI'),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'AI Studio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
