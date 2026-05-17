import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_theme.dart';
import '../../domain/usecases/send_membership_request.dart';
import '../cubit/search_barbershops_cubit.dart';
import '../cubit/search_barbershops_state.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchBarbershopsCubit>().search('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Buscar barberías',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.onSurface,
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
                context.read<SearchBarbershopsCubit>().search(value);
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<SearchBarbershopsCubit, SearchBarbershopsState>(
              listener: (context, state) {
                if (state is MembershipRequestSent) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Solicitud enviada a ${state.barbershopName}',
                      ),
                    ),
                  );
                  context.pop();
                }
                if (state is SearchBarbershopsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
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
                          color: AppColors.onSurfaceVariant,
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
  final dynamic shop;
  final VoidCallback onRequest;

  const _BarbershopTile({required this.shop, required this.onRequest});

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.surfaceContainerHighest,
              ),
              child: shop.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.network(shop.imageUrl, fit: BoxFit.cover),
                    )
                  : Icon(
                      Icons.storefront_rounded,
                      color: AppColors.outline,
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
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.address,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        '${shop.rating}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
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
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Solicitar'),
            ),
          ],
        ),
      ),
    );
  }
}
