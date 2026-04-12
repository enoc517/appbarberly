import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_theme.dart';
import '../bloc/welcome_bloc.dart';
import '../bloc/welcome_event.dart';
import '../bloc/welcome_state.dart';

/// Welcome / Onboarding screen — the app's entry point.
///
/// Replicates the "Celestial Tailor" hero layout from the HTML reference:
/// full-bleed barbershop image → gradient overlay → brand mark → headline →
/// CTA cluster → decorative motifs.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WelcomeBloc(),
      child: const _WelcomeView(),
    );
  }
}

class _WelcomeView extends StatefulWidget {
  const _WelcomeView();

  @override
  State<_WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<_WelcomeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure status bar icons are light over the dark image.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return BlocListener<WelcomeBloc, WelcomeState>(
      listenWhen: (prev, curr) =>
          curr.navigation != WelcomeNavigation.none,
      listener: (context, state) {
        switch (state.navigation) {
          case WelcomeNavigation.login:
            // TODO: Navigate to LoginScreen when implemented.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Navegar a Login (pendiente)')),
            );
            break;
          case WelcomeNavigation.onboarding:
            // TODO: Navigate to Onboarding / Registration.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Navegar a Onboarding (pendiente)')),
            );
            break;
          case WelcomeNavigation.none:
            break;
        }
      },
      child: Scaffold(
        // No AppBar / BottomNav — focused transactional screen.
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Background Image ───────────────────────────────────────
            _buildBackgroundImage(),

            // ── 2. Gradient Overlay (Space Blue → transparent) ────────────
            _buildGradientOverlay(),

            // ── 3. Tropical Pink Accent Notch (top-right) ─────────────────
            _buildAccentNotch(),

            // ── 4. Content: brand, headline, description, CTAs ────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: _buildContent(context),
                ),
              ),
            ),

            // ── 5. Decorative paw motif (bottom-right) ────────────────────
            _buildPawMotif(),

            // ── 6. Footer gradient line ───────────────────────────────────
            _buildFooterLine(),
          ],
        ),
      ),
    );
  }

  // ── Background ──────────────────────────────────────────────────────────────

  Widget _buildBackgroundImage() {
    // Using a placeholder gradient that evokes the barbershop atmosphere.
    // In production, replace with an actual AssetImage.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A2A20), // dark green tint (barbershop)
            Color(0xFF0F1C2C), // Space Blue
            Color(0xFF050D16),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.35, 0.7, 1.0],
          colors: [
            Colors.transparent,
            AppColors.primaryContainer.withValues(alpha: 0.30),
            AppColors.primaryContainer.withValues(alpha: 0.60),
            AppColors.primaryContainer,
          ],
        ),
      ),
    );
  }

  // ── Accent Notch ────────────────────────────────────────────────────────────

  Widget _buildAccentNotch() {
    return Positioned(
      top: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(100),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withValues(alpha: 0.20),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(100),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Content ─────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    final bloc = context.read<WelcomeBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Brand Mark ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 32, top: 16),
          child: _buildBrandMark(),
        ),

        const Spacer(),

        // ── Headline + Description + CTAs ───────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main headline
              Text(
                'Tu estilo,',
                style: AppTypography.displayLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'nuestra firma',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.onTertiaryContainer, // Tropical Pink
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                'Reserva citas, gestiona tu estilo y descubre '
                'los mejores barberos en un solo lugar.',
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.80),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 32),

              // ── CTA Cluster ─────────────────────────────────────────
              // Primary: "Comenzar →"
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      bloc.add(const WelcomeStartPressed()),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    textStyle: AppTypography.labelLarge.copyWith(
                      fontFamily: AppTypography.headlineFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Comenzar',
                        style: AppTypography.labelLarge.copyWith(
                          fontFamily: AppTypography.headlineFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Secondary: "Ya tengo una cuenta"
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      bloc.add(const WelcomeLoginPressed()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    textStyle: AppTypography.labelLarge.copyWith(
                      fontFamily: AppTypography.headlineFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  child: Text(
                    'Ya tengo una cuenta',
                    style: AppTypography.labelLarge.copyWith(
                      fontFamily: AppTypography.headlineFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
      ],
    );
  }

  // ── Brand Mark ──────────────────────────────────────────────────────────────

  Widget _buildBrandMark() {
    return Row(
      children: [
        // Icon container — Tropical Pink circle
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.onTertiaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.content_cut,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'STITCH & STYLE',
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }

  // ── Decorative Paw Motif ────────────────────────────────────────────────────

  Widget _buildPawMotif() {
    return Positioned(
      bottom: 40,
      right: 32,
      child: Opacity(
        opacity: 0.15,
        child: Icon(
          Icons.pets,
          size: 120,
          color: Colors.white.withValues(alpha: 0.60),
        ),
      ),
    );
  }

  // ── Footer Gradient Line ────────────────────────────────────────────────────

  Widget _buildFooterLine() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.secondaryContainer.withValues(alpha: 0.40),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
