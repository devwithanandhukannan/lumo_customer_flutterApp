import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ServiceCardHorizontal extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;
  final bool isSuspended;

  const ServiceCardHorizontal({
    super.key,
    required this.service,
    required this.onTap,
    this.isSuspended = false,
  });

  @override
  Widget build(BuildContext context) {
    final rawImg = service['image_url']?.toString();
    final imgUrl = (rawImg != null && rawImg.isNotEmpty)
        ? (rawImg.startsWith('http') ? rawImg : '${ApiClient.baseUrl}$rawImg')
        : null;
    final duration = service['duration_minutes']?.toString() ?? '45';
    final basePrice = service['base_price']?.toString() ?? '0';
    final originalPrice = ((num.tryParse(basePrice) ?? 0) * 1.25).round();
    final name = service['name']?.toString() ?? 'Service';
    final rating = service['rating']?.toString() ?? '4.9';

    return SizedBox(
      width: 170,
      child: AppGlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 18,
        onTap: onTap,
        borderColor: isSuspended ? AppColors.emergencyRedBorder : AppColors.glassBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with ETA and Rating Badges
            SizedBox(
              height: 95,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: imgUrl != null
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              },
                            )
                          : _buildFallbackImage(),
                    ),
                  ),

                  if (isSuspended)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        child: const Center(
                          child: Icon(Icons.block_rounded, color: Colors.redAccent, size: 28),
                        ),
                      ),
                    ),

                  // ETA / Duration Badge (Top Left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(190),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.glassBorder, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, color: AppColors.primary, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            '${duration}m',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Rating Badge (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(190),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.glassBorder, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 12),
                          const SizedBox(width: 2),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Pricing & ADD Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹$originalPrice',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                              maxLines: 1,
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '₹$basePrice',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSuspended ? AppColors.emergencyRedSoft : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSuspended ? Colors.redAccent : AppColors.primary,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSuspended ? Icons.pause_circle_outline_rounded : Icons.add_rounded,
                              color: isSuspended ? Colors.redAccent : AppColors.primary,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              isSuspended ? 'PAUSED' : 'BOOK',
                              style: TextStyle(
                                color: isSuspended ? Colors.redAccent : AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.home_repair_service_rounded, color: AppColors.primary, size: 32),
      ),
    );
  }
}
