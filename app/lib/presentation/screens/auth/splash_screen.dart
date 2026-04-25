import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sistema_control_agua/core/theme/app_colors.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_event.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_state.dart';
import 'package:sistema_control_agua/injection_container.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.droplets, color: Colors.white, size: 100)
                .animate().fade(duration: 800.ms).scale(curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
