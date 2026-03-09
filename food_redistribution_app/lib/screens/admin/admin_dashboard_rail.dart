import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class AdminDashboardRail extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const AdminDashboardRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryNavy,
            AppTheme.primaryNavyLight,
          ],
        ),
        border: Border(
          right: BorderSide(
            color: AppTheme.accentTeal.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        labelType: NavigationRailLabelType.all,
        backgroundColor: Colors.transparent,
        selectedIconTheme: const IconThemeData(color: AppTheme.accentTeal),
        unselectedIconTheme: const IconThemeData(color: AppTheme.textMuted),
        selectedLabelTextStyle: const TextStyle(
          color: AppTheme.accentTeal,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
        ),
        indicatorColor: AppTheme.accentTeal.withValues(alpha: 0.2),
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
      ),
    );
  }
}
