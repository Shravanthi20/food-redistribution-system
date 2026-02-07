import 'package:flutter/material.dart';

class AdminDashboardRail extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const AdminDashboardRail({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      unselectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Overview'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.verified_user_outlined),
          selectedIcon: Icon(Icons.verified_user),
          label: Text('Verifications'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('Governance'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.swap_calls_outlined),
          selectedIcon: Icon(Icons.swap_calls),
          label: Text('Overrides'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('Analytics'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.hub_outlined),
          selectedIcon: Icon(Icons.hub),
          label: Text('Matching'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history_edu_outlined),
          selectedIcon: Icon(Icons.history_edu),
          label: Text('Logs'),
        ),
      ],
    );
  }
}
