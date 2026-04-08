import 'package:flutter/material.dart';

import '../models/pack_models.dart';
import '../theme/app_theme.dart';
import 'status_badges.dart';

class PackSelectorCard extends StatelessWidget {
  const PackSelectorCard({
    super.key,
    required this.pack,
    required this.selected,
    required this.onTap,
    required this.showOwner,
  });

  final VisiblePack pack;
  final bool selected;
  final VoidCallback onTap;
  final bool showOwner;

  @override
  Widget build(BuildContext context) {
    final cardTextColor = selected ? Colors.white : AppColors.ink;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 12),
      width: 286,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? AppColors.ocean : AppColors.line,
          width: selected ? 1.8 : 1,
        ),
        gradient: LinearGradient(
          colors: selected
              ? [AppColors.ocean, const Color(0xFF2B6CA6)]
              : [Colors.white, const Color(0xFFF9FBFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? AppColors.ocean.withOpacity(0.18)
                : Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: cardTextColor,
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pack.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: cardTextColor,
                                    fontSize: 20,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Code ${pack.packageCode}',
                              style: TextStyle(
                                color: selected
                                    ? Colors.white70
                                    : AppColors.ink.withOpacity(0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: pack.status,
                        color: selected ? Colors.white : AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (showOwner) ...[
                    Text(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      pack.ownerFullName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cardTextColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pack.ownerEmail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white70
                            : AppColors.ink.withOpacity(0.62),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _MetaLine(
                    label: 'LFP',
                    value: pack.lfpBmsId ?? 'Not assigned',
                    selected: selected,
                  ),
                  const SizedBox(height: 6),
                  _MetaLine(
                    label: 'Supercap',
                    value: pack.supercapBmsId ?? 'Not assigned',
                    selected: selected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
    required this.selected,
  });

  final String label;
  final String value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white70 : AppColors.ink.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}
