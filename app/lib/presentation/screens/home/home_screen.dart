import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sistema_control_agua/core/theme/app_colors.dart';
import 'package:sistema_control_agua/presentation/blocs/auth/auth_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/auth/auth_event.dart';
import 'package:sistema_control_agua/presentation/blocs/auth/auth_state.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_event.dart';
import 'package:sistema_control_agua/presentation/blocs/socio/socio_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/socio/socio_event.dart';
import 'package:sistema_control_agua/injection_container.dart';
import 'package:sistema_control_agua/presentation/screens/admin/socios_screen.dart';
import 'package:sistema_control_agua/presentation/screens/admin/vivienda_list_screen.dart';
import 'package:sistema_control_agua/presentation/screens/admin/zonas_screen.dart';
import 'package:sistema_control_agua/presentation/screens/admin/cobros_screen.dart';
import 'package:sistema_control_agua/presentation/screens/admin/configuracion_screen.dart';
import 'package:sistema_control_agua/presentation/screens/admin/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    print('HomeScreen: AuthState = $state');
    if (state is! Authenticated) return const SizedBox.shrink();

    final user = state.user;
    final isMobile = MediaQuery.of(context).size.width < 800;
    final navItems = _getNavItems(user);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
              if (!isMobile)
                SizedBox(
                  width: 80,
                  height: double.infinity,
                  child: _buildSidebar(user, navItems),
                ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildTopBar(user),
                      Expanded(
                        child: ClipRect(
                          child: _buildCurrentScreen(user),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ),
      bottomNavigationBar: isMobile ? _buildBottomBar(user) : null,
    );
  }

  Widget _buildCurrentScreen(user) {
    final isAdmin = user.roleName == 'Admin';
    final isCobrador = user.roleName == 'Cobrador' || user.roleName == 'Admin';

    // Logical index mapping
    // 0: Inicio
    // 1: Socios (Admin)
    // 2: Zonas (Admin)
    // 3: Cobros (Cobrador/Admin)
    // 4: Config

    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return isAdmin ? const SociosScreen() : const CobrosScreen();
      case 2:
        return isAdmin ? const ZonasScreen() : const ConfiguracionScreen();
      case 3:
        return isCobrador ? const CobrosScreen() : const ConfiguracionScreen();
      case 4:
        return const ConfiguracionScreen();
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildSidebar(user, List<Map<String, dynamic>> items) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(LucideIcons.droplets, color: AppColors.primary, size: 32),
          const SizedBox(height: 48),
          Expanded(
            child: Column(
              children: items.map((item) {
                final targetIndex = item['index'] as int;
                final isSelected = _selectedIndex == targetIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = targetIndex),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppColors.error),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTopBar(user) {
    final titles = _getSectionTitles(user);
    final idx = _selectedIndex.clamp(0, titles.length - 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            titles[idx],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(user.email,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(LucideIcons.user, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  List<String> _getSectionTitles(user) {
    return ['Inicio', 'Socios', 'Zonas', 'Cobros', 'Configuración'];
  }

  Widget _buildDashboard(user) {
    final width = MediaQuery.of(context).size.width;
    final crossAxis = width > 1200 ? 4 : (width > 800 ? 3 : 2);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.count(
        crossAxisCount: crossAxis,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        children: _getFeatureCards(user),
      ),
    );
  }

  List<Map<String, dynamic>> _getNavItems(user) {
    final isAdmin = user.roleName == 'Admin';
    final isCobrador = user.roleName == 'Cobrador' || user.roleName == 'Admin';

    return [
      {'index': 0, 'label': 'Inicio', 'icon': LucideIcons.layoutDashboard},
      if (isAdmin) ...[
        {'index': 1, 'label': 'Socios', 'icon': LucideIcons.users},
        {'index': 2, 'label': 'Zonas', 'icon': LucideIcons.mapPin},
      ],
      if (isCobrador)
        {'index': 3, 'label': 'Cobros', 'icon': LucideIcons.checkSquare},
      {'index': 4, 'label': 'Config', 'icon': LucideIcons.settings},
    ];
  }

  List<NavigationRailDestination> _getDestinations(user) {
    return _getNavItems(user).map((item) {
      return NavigationRailDestination(
        icon: Icon(item['icon']),
        label: Text(item['label']),
      );
    }).toList();
  }

  List<Widget> _getFeatureCards(user) {
    final isAdmin = user.roleName == 'Admin';
    final isCobrador = user.roleName == 'Cobrador' || user.roleName == 'Admin';
    final isLecturador = user.roleName == 'Lecturador' || user.roleName == 'Admin';

    return [
      _buildCard('Resumen General', LucideIcons.barChart3, AppColors.primary, () {}),
      if (isAdmin) ...[
        _buildCard('Gestionar Socios', LucideIcons.users, AppColors.success, () {
          setState(() => _selectedIndex = 1);
        }),
        _buildCard('Zonas y Mapas', LucideIcons.map, AppColors.info, () {
          setState(() => _selectedIndex = 2);
        }),
        _buildCard('Tarifas', LucideIcons.badgeDollarSign, AppColors.warning, () {
          setState(() => _selectedIndex = 4);
        }),
      ],
      if (isCobrador)
        _buildCard('Registrar Pago', LucideIcons.wallet, AppColors.success, () {
          setState(() => _selectedIndex = 3);
        }),
      if (isLecturador)
        _buildCard('Nueva Lectura', LucideIcons.penTool, AppColors.primaryLight, () {}),
    ];
  }

  Widget _buildCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.1)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(user) {
    // For mobile bottom bar, we only show 3 main icons: Inicio, Cobros, Config
    // This allows easier access on small screens
    int displayIdx = 0;
    if (_selectedIndex == 0) displayIdx = 0;
    else if (_selectedIndex == 3) displayIdx = 1;
    else if (_selectedIndex == 4) displayIdx = 2;
    else displayIdx = 0; // Default to home if not in bottom bar items

    return BottomNavigationBar(
      currentIndex: displayIdx,
      onTap: (idx) {
        setState(() {
          if (idx == 0) _selectedIndex = 0;
          else if (idx == 1) _selectedIndex = 3;
          else if (idx == 2) _selectedIndex = 4;
        });
      },
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard), label: 'Inicio'),
        BottomNavigationBarItem(
            icon: Icon(LucideIcons.wallet), label: 'Cobros'),
        BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings), label: 'Config'),
      ],
    );
  }
}
