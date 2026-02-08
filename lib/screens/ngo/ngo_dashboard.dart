import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/food_donation.dart';

class NGODashboard extends StatefulWidget {
  const NGODashboard({Key? key}) : super(key: key);

  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.appUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          user?.fullName ?? 'Hope Food Bank',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.signOut();
                Navigator.pushReplacementNamed(context, AppRouter.login);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                     children: [
                       Icon(Icons.logout, color: Colors.red),
                       SizedBox(width: 8),
                       Text('Sign Out'),
                     ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _impactSection(user?.uid),
            const SizedBox(height: 20),
            _currentDemandSection(user?.uid),
            const SizedBox(height: 20),
            _activeDeliveriesSection(user?.uid),
            const SizedBox(height: 20),
            _incomingDonationsSection(context),
            const SizedBox(height: 20),
            _logisticsSection(user?.uid),
          ],
        ),
      ),
    );
  }

  // ================= IMPACT =================
  Widget _impactSection(String? userId) {
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('food_donations')
          .where('assignedNGOId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .snapshots(),
      builder: (context, snapshot) {
        int mealsServed = 0;
        int beneficiaries = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            mealsServed += (data['estimatedMeals'] as num? ?? 0).toInt();
            beneficiaries += (data['estimatedPeopleServed'] as num? ?? 0).toInt();
          }
        }

        return Row(
          children: [
            _impactCard(
              title: "Meals Served",
              value: NumberFormat.compact().format(mealsServed),
              subtitle: "Total delivered",
              color: Colors.green,
              icon: Icons.restaurant,
            ),
            const SizedBox(width: 12),
            _impactCard(
              title: "Beneficiaries",
              value: NumberFormat.compact().format(beneficiaries),
              subtitle: "Directly reached",
              color: Colors.orange,
              icon: Icons.groups,
            ),
          ],
        );
      },
    );
  }

  Widget _impactCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DEMAND =================
  Widget _currentDemandSection(String? userId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Current Demand",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                 onPressed: () {
                    Navigator.pushNamed(context, AppRouter.updateDemand);
                 },
                 child: const Text("Update"),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (userId != null)
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('ngo_demands')
                  .where('ngoId', isEqualTo: userId)
                  .where('status', isEqualTo: 'active')
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No active demands set.\nTap Update to post requirements.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                final categories = List<String>.from(data['categories'] ?? []);
                final quantity = data['quantity'];
                final unit = data['unit'];
                final urgency = data['urgency'] ?? 'Normal';

                Color urgencyColor = Colors.blue;
                if (urgency == 'High') urgencyColor = Colors.orange;
                if (urgency == 'Critical') urgencyColor = Colors.red;

                return Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Wrap(
                       spacing: 8,
                       runSpacing: 8,
                       children: categories.map((cat) => Chip(
                         label: Text(cat),
                         backgroundColor: Colors.green.shade50,
                         labelStyle: TextStyle(color: Colors.green.shade800),
                       )).toList(),
                     ),
                     const SizedBox(height: 16),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              const Text("Quantity Needed", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text("$quantity $unit", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                           ],
                         ),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(
                             color: urgencyColor.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(20),
                             border: Border.all(color: urgencyColor.withOpacity(0.5)),
                           ),
                           child: Text(
                             urgency.toUpperCase(),
                             style: TextStyle(color: urgencyColor, fontWeight: FontWeight.bold, fontSize: 12),
                           ),
                         )
                       ],
                     )
                   ],
                );
              },
            )
          else 
            const Text("Please log in to view demands"),
        ],
      ),
    );
  }

  // ================= DONATIONS =================
  Widget _incomingDonationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Available Donations",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Fetch available donations (Matched & Unmatched)
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('food_donations')
              .where('status', isEqualTo: 'listed')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ));
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No available donations right now."));
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                // Use a helper to safely parse FoodDonation if needed, or just use raw data
                final quantity = data['quantity'] ?? 0;
                final foodItems = List<String>.from(data['foodItems'] ?? []);
                final expiresAt = (data['expiryDate'] as Timestamp?)?.toDate();
                final timeString = expiresAt != null 
                    ? "Expires in ${expiresAt.difference(DateTime.now()).inHours}h" 
                    : "Unknown Expiry";

                final isMatched = data['matchingStatus'] == 'pending_ngo';
                final statusText = isMatched ? "MATCHED FOR YOU" : timeString;
                
                return _donationCard(
                  context,
                  "Anonymous Donor", 
                  "${foodItems.take(2).join(', ')} • $quantity items",
                  statusText,
                  isHighlighted: isMatched,
                );
              }).toList().cast<Widget>(),
            );
          },
        ),
      ],
    );
  }

  Widget _donationCard(
    BuildContext context,
    String donor,
    String details,
    String expiry, {
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                donor,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                expiry,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(details),
          const SizedBox(height: 10),
          Row(
            children: [
              _actionButton(
                "Accept",
                Colors.green,
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.inspectDelivery);
                },
              ),
              _actionButton(
                "Clarify",
                Colors.blue,
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.clarifyRequest);
                },
              ),
             
            ],
          )
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  // ================= ACTIVE DELIVERIES =================
  Widget _activeDeliveriesSection(String? userId) {
    if (userId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Active Matches & Deliveries",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('food_donations')
              .where('assignedNGOId', isEqualTo: userId)
              .where('status', whereIn: ['matched', 'pickedUp', 'inTransit', 'delivered']) // Exclude 'completed'/ 'listed'
              .orderBy('updatedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LinearProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "No active deliveries correctly.",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final donationId = doc.id;
                final status = data['status'] ?? 'unknown';
                final foodItems = List<String>.from(data['foodItems'] ?? []);
                final quantity = data['quantity'] ?? 0;
                
                Color statusColor = Colors.orange;
                String statusText = "Matched";
                IconData statusIcon = Icons.handshake;

                if (status == 'pickedUp') {
                   statusColor = Colors.purple;
                   statusText = "Picked Up";
                   statusIcon = Icons.inventory_2;
                } else if (status == 'inTransit') {
                   statusColor = Colors.blue;
                   statusText = "On the Way";
                   statusIcon = Icons.local_shipping;
                } else if (status == 'delivered') {
                   statusColor = Colors.green;
                   statusText = "Arrived";
                   statusIcon = Icons.check_circle;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: statusColor, width: 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                               Icon(statusIcon, color: statusColor, size: 20),
                               const SizedBox(width: 8),
                               Text(
                                 statusText.toUpperCase(),
                                 style: TextStyle(
                                   color: statusColor,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 12,
                                 ),
                               ),
                            ],
                          ),
                          if (status == 'delivered') 
                             ElevatedButton(
                               onPressed: () {
                                  // Navigate to inspect
                                  // We need to pass the donation object or ID
                                  // Fetching object again in next screen or passing partial
                                  Navigator.pushNamed(
                                    context, 
                                    AppRouter.inspectDelivery,
                                    arguments: FoodDonation.fromFirestore(doc),
                                  );
                               },
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.green,
                                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                 minimumSize: const Size(0, 32),
                               ),
                               child: const Text("Inspect", style: TextStyle(fontSize: 12)),
                             ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "${foodItems.take(3).join(', ')} • $quantity Items",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Donor: Anonymous", // data['donorName'] ?? 
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ================= LOGISTICS =================
  Widget _logisticsSection(String? userId) {
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('ngo_profiles').doc(userId).snapshots(),
      builder: (context, profileSnapshot) {
        final profileData = profileSnapshot.data?.data() as Map<String, dynamic>?;
        final double capacity = (profileData?['capacity'] as num? ?? 100).toDouble();
        final double safeCapacity = capacity > 0 ? capacity : 100.0;

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('food_donations')
              .where('assignedNGOId', isEqualTo: userId)
              .where('status', whereIn: ['matched', 'pickedUp', 'inTransit'])
              .snapshots(),
          builder: (context, donationSnapshot) {
            double currentLoad = 0;
            if (donationSnapshot.hasData) {
              for (var doc in donationSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                currentLoad += (data['quantity'] as num? ?? 0).toDouble();
              }
            }

            double percentFull = currentLoad / safeCapacity;
            if (percentFull > 1) percentFull = 1;

            String statusText;
            Color statusColor;

            if (percentFull < 0.7) {
              statusText = "Capacity Available";
              statusColor = Colors.green;
            } else if (percentFull < 0.9) {
              statusText = "Near Full";
              statusColor = Colors.orange;
            } else {
              statusText = "Almost Full";
              statusColor = Colors.red;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Logistics & Service",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Current Load",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "${(percentFull * 100).round()}% Full",
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percentFull,
                    backgroundColor: Colors.grey.shade300,
                    color: statusColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${currentLoad.toInt()} / ${safeCapacity.toInt()} units in active processing",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                   const SizedBox(height: 8),
                   Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
