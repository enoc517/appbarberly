import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../motion/app_motion.dart';
import '../theme/app_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  /// Viene del StatefulShellRoute. Contiene el estado de todas las ramas.
  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  DateTime? _lastBackPressedAt;

  static const _clientItems = [
    _ShellItem(Icons.explore_outlined, 'EXPLORAR', 0),
    _ShellItem(Icons.calendar_today_outlined, 'CITAS', 1),
    _ShellItem(Icons.favorite_border_rounded, 'FAVORITOS', 2),
    _ShellItem(Icons.person_outline, 'PERFIL', 3),
  ];

  static const _barberItems = [
    _ShellItem(Icons.grid_view_outlined, 'PANEL', 4),
    _ShellItem(Icons.calendar_month_outlined, 'AGENDA', 5),
    _ShellItem(Icons.storefront_outlined, 'BARBERÍA', 6),
    _ShellItem(Icons.person_outline, 'PERFIL', 7),
  ];

  bool get _isBarberShell => widget.navigationShell.currentIndex >= 4;

  List<_ShellItem> get _items => _isBarberShell ? _barberItems : _clientItems;

  int get _homeBranchIndex => _isBarberShell ? 4 : 0;

  void _onTap(int index) {
    // initialLocation: true -> vuelve a la raiz de la tab si ya estas en ella.
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  Future<bool> _onBackPressed(BuildContext context) async {
    if (widget.navigationShell.currentIndex != _homeBranchIndex) {
      widget.navigationShell.goBranch(_homeBranchIndex, initialLocation: true);
      return true;
    }

    final now = DateTime.now();
    final shouldExit =
        _lastBackPressedAt != null &&
        now.difference(_lastBackPressedAt!) < const Duration(seconds: 2);

    if (shouldExit) {
      SystemNavigator.pop();
      return true;
    }

    _lastBackPressedAt = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Pulsa atras otra vez para salir')),
      );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () => _onBackPressed(context),
      child: Scaffold(
        body: widget.navigationShell,
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
                final item = _items[i];
                final selected =
                    widget.navigationShell.currentIndex == item.branchIndex;
                return AppPressable(
                  onTap: () => _onTap(item.branchIndex),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.standard,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: AnimatedScale(
                      scale: selected ? 1.02 : 1,
                      duration: AppMotion.fast,
                      curve: AppMotion.standard,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 22,
                            color: selected
                                ? AppColors.onPrimary
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
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
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellItem {
  const _ShellItem(this.icon, this.label, this.branchIndex);

  final IconData icon;
  final String label;
  final int branchIndex;
}
