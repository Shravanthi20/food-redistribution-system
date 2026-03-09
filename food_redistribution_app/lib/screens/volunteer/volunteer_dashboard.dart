import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/food_donation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../utils/app_localizations_ext.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glass_widgets.dart';
import '../../real_time_tracking/widgets/donation_status_badge.dart';
import '../../real_time_tracking/widgets/delivery_status_panel.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  bool isOnline = false;

  int selectedIndex = 0;

  final List<String> timeSlots = [
    "Morning (6AM-12PM)",
    "Afternoon (12PM-5PM)",
    "Evening (5PM-10PM)",
    "Full Day",
  ];

  String selectedSlot = "Full Day";

  @override
  void initState() {
    super.initState();
    _loadOnlineStatus();
  }

  Future<void> _loadOnlineStatus() async {
    final user = Provider.of<AuthProvider>(context, listen: false).appUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          isOnline = doc.data()?['isOnline'] ?? false;
        });
      }
    } catch (_) {
      // Ignore errors loading status
    }
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    final user = Provider.of<AuthProvider>(context, listen: false).appUser;
    if (user == null) return;
    setState(() => isOnline = value);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
          {'isOnline': value, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error toggling online status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).appUser;
    final donationProvider = Provider.of<DonationProvider>(
      context,
      listen: false,
    );

    if (user == null) {
      return const GradientScaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentTeal),
        ),
      );
    }

    return GradientScaffold(
      showAnimatedBackground: true,
      body: SafeArea(
        child: Column(
          children: [
            _topHeader(user.fullName),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statusCard(),
                    const SizedBox(height: 16),
                    _newRequestsSection(donationProvider, user.uid),
                    const SizedBox(height: 20),
                    _activeTasksSection(donationProvider, user.uid),
                    const SizedBox(height: 20),
                    _availableTasksSection(donationProvider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= NEW REQUESTS (ASSIGNMENTS) =================
  Widget _newRequestsSection(DonationProvider provider, String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: provider.getPendingAssignmentsStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.assignment_outlined,
                    color: AppTheme.accentTeal.withValues(alpha: 0.4)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.noNewPickupRequests,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.warningAmber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notification_important_rounded,
                    size: 16,
                    color: AppTheme.warningAmber,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.newAssignments,
                    style: const TextStyle(
                      color: AppTheme.warningAmber,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...snapshot.data!.map((assignment) {
              final donationId = assignment['donationId'];
              final assignmentId = assignment['assignmentId'];

              return StreamBuilder<FoodDonation?>(
                stream: provider.getDonationStream(donationId),
                builder: (context, docSnapshot) {
                  if (!docSnapshot.hasData) return const SizedBox.shrink();
                  final donation = docSnapshot.data!;

                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    tintColor: AppTheme.warningAmber,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warningAmber.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.l10n.matchedActionRequired,
                            style: const TextStyle(
                              color: AppTheme.warningAmber,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          donation.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${donation.quantity} ${donation.unit} from Anonymous Donor",
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: GradientButton(
                                text: context.l10n.accept,
                                icon: Icons.check_rounded,
                                onPressed: () async {
                                  await provider.acceptAssignment(
                                    assignmentId,
                                    donationId,
                                    userId,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GradientButton(
                                text: context.l10n.decline,
                                outlined: true,
                                gradientColors: const [
                                  AppTheme.errorCoral,
                                  AppTheme.errorCoral,
                                ],
                                onPressed: () async {
                                  await provider.rejectAssignment(
                                    assignmentId,
                                    donationId,
                                    userId,
                                    "User declined",
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }

  // ================= ACTIVE TASKS =================
  Widget _activeTasksSection(DonationProvider provider, String userId) {
    return StreamBuilder<List<FoodDonation>>(
      stream: provider.getVolunteerTasksStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    color: AppTheme.accentTeal.withValues(alpha: 0.4)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.noActiveTasks,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        final tasks = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.myActiveTasks,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...tasks.map((task) => _taskCard(context, task, isActive: true)),
          ],
        );
      },
    );
  }

  // ================= AVAILABLE TASKS =================
  Widget _availableTasksSection(DonationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _availableTasksHeader(),
        const SizedBox(height: 14),
        StreamBuilder<List<FoodDonation>>(
          stream: provider.getAvailableDonationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentTeal),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inbox_rounded,
                      size: 48,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.noAvailableTasksNearby,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: snapshot.data!
                  .map((task) => _taskCard(context, task))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  // ================= HEADER =================
  Widget _topHeader(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.accentTeal, AppTheme.accentCyan],
              ),
            ),
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primaryNavyLight,
              child: Icon(Icons.person_rounded, color: AppTheme.accentTeal),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          GlassIconButton(
            icon: Icons.more_vert_rounded,
            size: 40,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => GlassBottomSheet(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20),
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.person_rounded,
                          color: AppTheme.accentTeal,
                        ),
                        title: Text(
                          context.l10n.editProfile,
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppRouter.volunteerProfile,
                          );
                        },
                      ),
                      const Divider(color: AppTheme.surfaceGlassBorder),
                      ListTile(
                        leading: const Icon(
                          Icons.accessibility_new_rounded,
                          color: AppTheme.accentCyan,
                        ),
                        title: Text(
                          context.l10n.accessibilitySettings,
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppRouter.accessibilitySettings,
                          );
                        },
                      ),
                      const Divider(color: AppTheme.surfaceGlassBorder),
                      ListTile(
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: AppTheme.errorCoral,
                        ),
                        title: Text(
                          context.l10n.signOut,
                          style: const TextStyle(color: AppTheme.errorCoral),
                        ),
                        onTap: () async {
                          Navigator.pop(context); // Close bottom sheet
                          final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          await auth.signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRouter.login,
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.l10n.goodMorning;
    if (hour < 17) return context.l10n.goodAfternoon;
    return context.l10n.goodEvening;
  }

  // ================= STATUS CARD =================
  Widget _statusCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.statusLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppTheme.successTeal.withValues(alpha: 0.15)
                          : AppTheme.textMuted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline
                                ? AppTheme.successTeal
                                : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline
                              ? context.l10n.onlineStatus
                              : context.l10n.offlineLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isOnline
                                ? AppTheme.successTeal
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.visibleToNearbyTasks,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          Switch(
            value: isOnline,
            activeThumbColor: AppTheme.successTeal,
            activeTrackColor: AppTheme.successTeal.withValues(alpha: 0.3),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.surfaceGlassDark,
            onChanged: _toggleOnlineStatus,
          ),
        ],
      ),
    );
  }

  // ================= TASK HEADER =================
  Widget _availableTasksHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.availableTasks,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const GlassBadge(text: 'Near You', color: AppTheme.accentTeal),
      ],
    );
  }

  // ================= TASK CARD =================
  Widget _taskCard(
    BuildContext context,
    FoodDonation task, {
    bool isActive = false,
  }) {
    final simplifiedMode = Provider.of<AccessibilityProvider>(
      context,
    ).simplifiedMode;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      tintColor: isActive ? AppTheme.successTeal : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.successTeal.withValues(alpha: 0.15)
                  : AppTheme.accentCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (simplifiedMode)
                  Icon(
                    isActive ? Icons.play_circle_filled : Icons.event_available,
                    size: 16,
                    color:
                        isActive ? AppTheme.successTeal : AppTheme.accentCyan,
                  ),
                if (simplifiedMode) const SizedBox(width: 4),
                Text(
                  isActive ? context.l10n.inProgress : context.l10n.available,
                  style: TextStyle(
                    color:
                        isActive ? AppTheme.successTeal : AppTheme.accentCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (!simplifiedMode) // Hide detailed text in simplified mode to reduce cognitive load
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    task.pickupAddress.isNotEmpty
                        ? task.pickupAddress
                        : context.l10n.locationTBD,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: task.isUrgent
                        ? AppTheme.errorCoral.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.isUrgent
                        ? context.l10n.isUrgent
                        : context.l10n.normalPriority,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          task.isUrgent ? FontWeight.w600 : FontWeight.normal,
                      color: task.isUrgent
                          ? AppTheme.errorCoral
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          if (!simplifiedMode) const SizedBox(height: 10),
          Text(
            simplifiedMode
                ? "${task.quantity} ${task.unit}"
                : "${task.quantity} ${task.unit} • ${task.foodTypes.map((e) => e.name).join(', ')}",
            style: TextStyle(
              fontSize: simplifiedMode ? 16 : 13,
              color: AppTheme.textSecondary,
              fontWeight: simplifiedMode ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 16),
          if (!isActive)
            GradientButton(
              text: simplifiedMode
                  ? context.l10n.goButton
                  : context.l10n.acceptTask,
              icon: Icons.check_circle_rounded,
              width: double.infinity,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.acceptTask,
                  arguments: task,
                );
              },
            )
          else
            GradientButton(
              text: simplifiedMode
                  ? context.l10n.continueDelivery
                  : context.l10n.continueDelivery,
              icon: Icons.local_shipping_rounded,
              width: double.infinity,
              gradientColors: const [
                AppTheme.accentCyan,
                AppTheme.accentCyanSoft,
              ],
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.taskExecution,
                  arguments: {'donationId': task.id},
                );
              },
            ),
          const SizedBox(height: 12),
          // Real-time status panel for volunteers
          if (!simplifiedMode)
            DonationStatusBadge(
              deliveryId: task.id.toString(),
              role: 'volunteer',
            ),
          if (!simplifiedMode) const SizedBox(height: 8),
          if (!simplifiedMode)
            DeliveryStatusPanel(
              role: 'volunteer',
              deliveryId: task.id.toString(),
            ),
        ],
      ),
    );
  }
}
