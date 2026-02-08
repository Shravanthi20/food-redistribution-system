import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_donation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../utils/app_router.dart';

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

  // ✅ Time slot feature
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

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
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
                    _newRequestsSection(donationProvider, user.uid), // [NEW]
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notification_important, size: 16, color: Colors.orange.shade900),
                  const SizedBox(width: 8),
                  Text(
                    "YOU HAVE NEW ASSIGNMENTS!",
                    style: TextStyle(
                      color: Colors.orange.shade900, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 12
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...snapshot.data!.map((assignment) {
              final donationId = assignment['donationId'];
              final assignmentId = assignment['assignmentId'];
              
              // Fetch Donation Details for this assignment
              return StreamBuilder<FoodDonation?>(
                stream: provider.getDonationStream(donationId),
                builder: (context, docSnapshot) {
                  if (!docSnapshot.hasData) return const SizedBox.shrink();
                  final donation = docSnapshot.data!;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4)
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("MATCHED — ACTION REQUIRED", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(donation.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("${donation.quantity} ${donation.unit} from Anonymous Donor", style: TextStyle(color: Colors.grey[600])),
                         const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await provider.acceptAssignment(assignmentId, donationId, userId);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text("Accept"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                   await provider.rejectAssignment(assignmentId, donationId, userId, "User declined");
                                },
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text("Decline"),
                              ),
                            ),
                          ],
                        )
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
             const Text("My Active Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        StreamBuilder<List<FoodDonation>>(
          stream: provider.getAvailableDonationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No available tasks nearby."));
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage("assets/images/profile.jpg"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Good morning,",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.pushNamed(context, AppRouter.volunteerProfile);
              } else if (value == 'logout') {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.signOut();
                Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Edit Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          )
        ],
      ),
    );
  }

  // ================= STATUS CARD =================
  Widget _statusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Current Status: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isOnline ? "Online" : "Offline",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Visible to nearby surplus tasks",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Switch(
            value: isOnline,
            activeColor: Colors.green,
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
        const Text(
          "Available Tasks",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
        )
      ],
    );
  }

  // ================= TASK CARD =================
  Widget _taskCard(BuildContext context, FoodDonation task, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isActive ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? "IN PROGRESS" : "AVAILABLE",
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("~2.5 km", // Placeholder for actual distance calc
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 14),
                    const Icon(Icons.timer, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(task.isUrgent ? "Urgent" : "Normal",
                        style:
                            TextStyle(fontSize: 12, color: task.isUrgent ? Colors.red : Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "${task.quantity} ${task.unit} • ${task.foodTypes.map((e) => e.name).join(', ')}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                if (!isActive)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                             Navigator.pushNamed(
                               context, 
                               AppRouter.acceptTask,
                               arguments: task // Pass donation object
                             );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Accept Task"),
                        ),
                      ),
                    ],
                  )
                else
                   Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                             Navigator.pushNamed(
                               context, 
                               AppRouter.taskExecution, 
                               arguments: {'donationId': task.id}
                             );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Continue Delivery"),
                        ),
                      ),
                    ],
                  )
              ],
            ),
          )
        ],
      ),
    );
  }
}
