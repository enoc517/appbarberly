import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../motion/app_motion.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  /// Viene del StatefulShellRoute. Contiene el estado de todas las ramas.
  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  DateTime? _lastBackPressedAt;
  static const _swipeVelocityThreshold = 300.0;

  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _previousIndex = 0;
  int _swipeDirection = 0;

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

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.navigationShell.currentIndex;

    _transitionController = AnimationController(
      vsync: this,
      duration: AppMotion.normal,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: AppMotion.standard,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _transitionController.value = 1;
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newIndex = widget.navigationShell.currentIndex;
    if (newIndex != _previousIndex) {
      _swipeDirection = newIndex > _previousIndex ? -1 : 1;
      _previousIndex = newIndex;

      if (!AppMotion.reduceMotion(context)) {
        _transitionController.reset();
        _transitionController.forward();
      }
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    // initialLocation: true -> vuelve a la raiz de la tab si ya estas en ella.
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < _swipeVelocityThreshold) return;

    final currentIndex = widget.navigationShell.currentIndex;
    final minIndex = _isBarberShell ? 4 : 0;
    final maxIndex = _isBarberShell ? 7 : 3;

    var targetIndex = currentIndex;
    if (velocity < 0 && currentIndex < maxIndex) {
      targetIndex = currentIndex + 1;
      _swipeDirection = -1;
    } else if (velocity > 0 && currentIndex > minIndex) {
      targetIndex = currentIndex - 1;
      _swipeDirection = 1;
    }

    if (targetIndex == currentIndex) return;

    widget.navigationShell.goBranch(targetIndex, initialLocation: false);
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
    AppToast.info(context, 'Pulsa atras otra vez para salir');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BackButtonListener(
      onBackButtonPressed: () => _onBackPressed(context),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: Scaffold(
          body: _BranchTransition(
            fadeAnimation: _fadeAnimation,
            slideAnimation: _slideAnimation,
            direction: _swipeDirection,
            child: widget.navigationShell,
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
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
                        color: selected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
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
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: AppTypography.labelSmall.copyWith(
                                color: selected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
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

class _BranchTransition extends StatelessWidget {
  const _BranchTransition({
    required this.child,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.direction,
  });

  final Widget child;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final int direction;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) {
      return child;
    }

    final adjustedSlide = Tween<Offset>(
      begin: Offset(slideAnimation.value.dx * direction, 0),
      end: Offset.zero,
    ).animate(fadeAnimation);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(position: adjustedSlide, child: child),
    );
  }
}
