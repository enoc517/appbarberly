import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_theme.dart';
import '../../../../../shared/widgets/app_toast.dart';
import '../../../../explore/presentation/utils/distance_formatter.dart';
import '../../../barbershop_management/domain/entities/barbershop.dart';
import '../../domain/usecases/send_membership_request.dart';
import '../cubit/search_barbershops_cubit.dart';
import '../cubit/search_barbershops_state.dart';

const kMembershipSearchRadii = [5.0, 10.0, 25.0, 50.0];

class SearchBarbershopsScreen extends StatefulWidget {
  final String barberId;
  final String barberName;
  final String barberEmail;

  const SearchBarbershopsScreen({
    super.key,
    required this.barberId,
    required this.barberName,
    required this.barberEmail,
  });

  @override
  State<SearchBarbershopsScreen> createState() =>
      _SearchBarbershopsScreenState();
}

class _SearchBarbershopsScreenState extends State<SearchBarbershopsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  double _radiusKm = 10.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchBarbershopsCubit>().search('', radiusKm: _radiusKm);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<SearchBarbershopsCubit>().search(value, radiusKm: _radiusKm);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Buscar barberías',
          style: AppTypography.titleLarge.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _search(value);
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o barbero...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Distancia',
                style: AppTypography.labelLarge.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final radius = kMembershipSearchRadii[index];
                return ChoiceChip(
                  label: Text('${radius.toInt()} km'),
                  selected: _radiusKm == radius,
                  onSelected: (_) {
                    setState(() => _radiusKm = radius);
                    _search(_searchController.text);
                  },
                );
              },
              separatorBuilder: (context, _) => const SizedBox(width: 8),
              itemCount: kMembershipSearchRadii.length,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocConsumer<SearchBarbershopsCubit, SearchBarbershopsState>(
              listener: (context, state) {
                if (state is MembershipRequestSent) {
                  AppToast.success(
                    context,
                    'Solicitud enviada a ${state.barbershopName}',
                  );
                  context.pop();
                }
                if (state is SearchBarbershopsError) {
                  AppToast.error(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is SearchBarbershopsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SearchBarbershopsLoaded) {
                  if (state.barbershops.isEmpty) {
                    return Center(
                      child: Text(
                        'No se encontraron barberías',
                        style: AppTypography.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.barbershops.length,
                    itemBuilder: (context, index) {
                      final shop = state.barbershops[index];
                      return _BarbershopTile(
                        shop: shop,
                        onRequest: () {
                          context.read<SearchBarbershopsCubit>().sendRequest(
                            SendMembershipRequestParams(
                              barberId: widget.barberId,
                              barberName: widget.barberName,
                              barberEmail: widget.barberEmail,
                              barberAvatarUrl: '',
                              barbershopId: shop.id,
                              barbershopName: shop.name,
                            ),
                          );
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarbershopTile extends StatelessWidget {
  final Barbershop shop;
  final VoidCallback onRequest;

  const _BarbershopTile({required this.shop, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: shop.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.network(shop.imageUrl, fit: BoxFit.cover),
                    )
                  : Icon(
                      Icons.storefront_rounded,
                      color: theme.colorScheme.outline,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.address,
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (shop.distanceKm != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      formatDistanceKm(shop.distanceKm),
                      style: AppTypography.labelMedium.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${shop.rating}',
                        style: AppTypography.labelMedium.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text('Solicitar'),
            ),
          ],
        ),
      ),
    );
  }
}
