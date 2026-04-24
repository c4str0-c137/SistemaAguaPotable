import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../admin/vivienda_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) return const SizedBox.shrink();
        
        final user = state.user;
        final isMobile = MediaQuery.of(context).size.width < 800;

        return Scaffold(
          body: Row(
            children: [
              if (!isMobile)
                _buildSidebar(user),
              
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(user),
                    Expanded(
                      child: _buildDashboard(user),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isMobile ? _buildBottomBar(user) : null,
        );
      },
    );
  }

  Widget _buildSidebar(user) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withOpacity(0.1),
      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Icon(LucideIcons.droplets, color: AppColors.primary, size: 32),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: IconButton(
              icon: const Icon(LucideIcons.logOut, color: AppColors.error),
              onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
            ),
          ),
        ),
      ),
      destinations: _getDestinations(user),
    );
  }

  Widget _buildTopBar(user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Panel de ${user.roleName}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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

  Widget _buildDashboard(user) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 3 : 2),
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        children: _getFeatureCards(user),
      ),
    );
  }

  List<NavigationRailDestination> _getDestinations(user) {
    return [
      const NavigationRailDestination(
        icon: Icon(LucideIcons.layoutDashboard),
        label: Text('Inicio'),
      ),
      if (user.roleName == 'Admin') ...[
        const NavigationRailDestination(
          icon: Icon(LucideIcons.users),
          label: Text('Socios'),
        ),
        const NavigationRailDestination(
          icon: Icon(LucideIcons.mapPin),
          label: Text('Zonas'),
        ),
      ],
      if (user.roleName == 'Cobrador' || user.roleName == 'Admin')
        const NavigationRailDestination(
          icon: Icon(LucideIcons.checkSquare),
          label: Text('Cobros'),
        ),
      const NavigationRailDestination(
        icon: Icon(LucideIcons.settings),
        label: Text('Config'),
      ),
    ];
  }

  List<Widget> _getFeatureCards(user) {
    return [
      _buildCard('Resumen General', LucideIcons.barChart3, AppColors.primary, () {}),
      if (user.roleName == 'Admin') ...[
        _buildCard('Gestionar Socios', LucideIcons.users, AppColors.success, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ViviendaListScreen()));
        }),
        _buildCard('Zonas y Mapas', LucideIcons.map, AppColors.info, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ViviendaListScreen()));
        }),
        _buildCard('Tarifas Especiales', LucideIcons.clapperboard, AppColors.warning, () {}),
      ],
      if (user.roleName == 'Cobrador' || user.roleName == 'Admin')
        _buildCard('Registrar Pago', LucideIcons.wallet, AppColors.success, () {}),
      if (user.roleName == 'Lecturador' || user.roleName == 'Admin')
        _buildCard('Nueva Lectura', LucideIcons.penTool, AppColors.primaryLight, () {}),
    ];
  }

  Widget _buildCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: color.withOpacity(0.1))),
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
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(user) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (idx) => setState(() => _selectedIndex = idx),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.wallet), label: 'Cobros'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: 'Config'),
      ],
    );
  }
}
