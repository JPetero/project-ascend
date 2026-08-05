import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class _WorkoutCategory {
  const _WorkoutCategory(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _categories = [
  _WorkoutCategory(Icons.fitness_center_rounded, 'Strength'),
  _WorkoutCategory(Icons.directions_run_rounded, 'Cardio'),
  _WorkoutCategory(Icons.self_improvement_rounded, 'Mobility'),
  _WorkoutCategory(Icons.sports_gymnastics_rounded, 'Bodyweight'),
  _WorkoutCategory(Icons.timer_outlined, 'Quick (10-15 min)'),
  _WorkoutCategory(Icons.spa_outlined, 'Recovery'),
];

/// A polished coming-soon shell. Workout planning and logging land in a
/// later sprint (see packages/docs/roadmap.md); this establishes the
/// navigation and visual language ahead of time.
class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            const AscendSectionHeader(
              title: 'Categories',
              subtitle: 'Full workout planning and logging are coming soon.',
            ),
            const SizedBox(height: AscendSpacing.md),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AscendSpacing.md,
              crossAxisSpacing: AscendSpacing.md,
              childAspectRatio: 1.6,
              children: [
                for (final category in _categories)
                  AscendCard(
                    semanticLabel: '${category.label}, coming soon',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          category.icon,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: AscendSpacing.sm),
                        Text(
                          category.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AscendSpacing.lg),
            AscendEmptyState(
              icon: Icons.construction_rounded,
              title: 'Workout logging is on the way',
              message:
                  'Structured plans, exercise logging, and history will appear here in an '
                  'upcoming release. Your Home dashboard already shows a sample workout for today.',
            ),
          ],
        ),
      ),
    );
  }
}
