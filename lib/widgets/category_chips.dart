import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Horizontal, scrollable list of category pills shown on the Home screen.
class CategoryChips extends StatelessWidget {
  final Map<String, String> categories;
  final void Function(String subject, String label) onSelected;

  const CategoryChips({


    
    super.key,
    required this.categories,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = categories.entries.toList();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Material(
            color: AppColors.surfaceHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.outline),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelected(entry.key, entry.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Text(
                  entry.value,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
