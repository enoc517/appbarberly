import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  /// Viene del StatefulShellRoute. Contiene el estado de todas las ramas.
  final StatefulNavigationShell navigationShell;

  static const _items = [
    (Icons.explore_outlined, 'EXPLORAR'),
    (Icons.calendar_today_outlined, 'CITAS'),
    (Icons.grid_view_outlined, 'PANEL'),
    (Icons.person_outline, 'PERFIL'),
  ];

  void _onTap(int index) {
    // initialLocation: true → vuelve a la raíz de la tab si ya estás en ella
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell, // aquí se dibuja la tab activa
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final selected = navigationShell.currentIndex == i;
              return GestureDetector(
                onTap: () => _onTap(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _items[i].$1,
                        size: 22,
                        color: selected
                            ? AppColors.onPrimary
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _items[i].$2,
                        style: AppTypography.labelSmall.copyWith(
                          color: selected
                              ? AppColors.onPrimary
                              : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}