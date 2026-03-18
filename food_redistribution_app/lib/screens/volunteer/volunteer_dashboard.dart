import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_donation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glass_widgets.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({Key? key}) : super(key: key);

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  bool isOnline = true;

  int deliveries = 24;
  double reliability = 4.9;

  int selectedIndex = 0;

  final List<String> timeSlots = [
    "Morning (6AM-12PM)",
    "Afternoon (12PM-5PM)",
    "Evening (5PM-10PM)",
    "Full Day",
  ];

  String selectedSlot = "Full Day";

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).appUser;
    final donationProvider = Provider.of<DonationProvider>(context, listen: false);

    if (user == null) {
      return GradientScaffold(
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warningAmber.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notification_important_rounded, size: 16, color: AppTheme.warningAmber),
                  const SizedBox(width: 8),
                  Text(
                    "NEW ASSIGNMENTS",
                    style: TextStyle(
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.warningAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "MATCHED — ACTION REQUIRED",
                            style: TextStyle(
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
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${donation.quantity} ${donation.unit} from Anonymous Donor",
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: GradientButton(
                                text: 'Accept',
                                icon: Icons.check_rounded,
                                onPressed: () async {
                                  await provider.acceptAssignment(assignmentId, donationId, userId);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GradientButton(
                                text: 'Decline',
                                outlined: true,
                                gradientColors: [AppTheme.errorCoral, AppTheme.errorCoral],
                                onPressed: () async {
                                  await provider.rejectAssignment(assignmentId, donationId, userId, "User declined");
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
            }).toList(),
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        final tasks = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Active Tasks",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...tasks.map((task) => _taskCard(context, task, isActive: true)).toList(),
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
              return Center(
                child: CircularProgressIndicator(color: AppTheme.accentTeal),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 48, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      "No available tasks nearby",
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: snapshot.data!.map((task) => _taskCard(context, task)).toList(),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.accentTeal, AppTheme.accentCyan],
              ),
            ),
            child: CircleAvatar(
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
                  "Good morning,",
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                Text(
                  name,
                  style: TextStyle(
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
                        leading: Icon(Icons.person_rounded, color: AppTheme.accentTeal),
                        title: Text('Edit Profile', style: TextStyle(color: AppTheme.textPrimary)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRouter.volunteerProfile);
                        },
                      ),
                      Divider(color: AppTheme.surfaceGlassBorder),
                      ListTile(
                        leading: Icon(Icons.logout_rounded, color: AppTheme.errorCoral),
                        title: Text('Sign Out', style: TextStyle(color: AppTheme.errorCoral)),
                        onTap: () async {
                          Navigator.pop(context);
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          await auth.signOut();
                          Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
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
                    "Status: ",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOnline 
                        ? AppTheme.successTeal.withOpacity(0.15)
                        : AppTheme.textMuted.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? AppTheme.successTeal : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? "Online" : "Offline",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isOnline ? AppTheme.successTeal : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Visible to nearby surplus tasks",
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          Switch(
            value: isOnline,
            activeColor: AppTheme.successTeal,
            activeTrackColor: AppTheme.successTeal.withOpacity(0.3),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.surfaceGlassDark,
            onChanged: (value) {
              setState(() {
                isOnline = value;
              });
            },
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
          "Available Tasks",
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        GlassBadge(text: 'Near You', color: AppTheme.accentTeal),
      ],
    );
  }

  // ================= TASK CARD =================
  Widget _taskCard(BuildContext context, FoodDonation task, {bool isActive = false}) {
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
                ? AppTheme.successTeal.withOpacity(0.15)
                : AppTheme.accentCyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isActive ? "IN PROGRESS" : "AVAILABLE",
              style: TextStyle(
                color: isActive ? AppTheme.successTeal : AppTheme.accentCyan,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text("~2.5 km", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(width: 14),
              Icon(Icons.schedule_rounded, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: task.isUrgent ? AppTheme.errorCoral.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.isUrgent ? "Urgent" : "Normal",
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: task.isUrgent ? FontWeight.w600 : FontWeight.normal,
                    color: task.isUrgent ? AppTheme.errorCoral : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${task.quantity} ${task.unit} • ${task.foodTypes.map((e) => e.name).join(', ')}",
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          if (!isActive)
            GradientButton(
              text: 'Accept Task',
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
              text: 'Continue Delivery',
              icon: Icons.local_shipping_rounded,
              width: double.infinity,
              gradientColors: [AppTheme.accentCyan, AppTheme.accentCyanSoft],
              onPressed: () {
                Navigator.pushNamed(
                  context, 
                  AppRouter.taskExecution, 
                  arguments: {'donationId': task.id},
                );
              },
            ),
        ],
      ),
    );
  }
}
