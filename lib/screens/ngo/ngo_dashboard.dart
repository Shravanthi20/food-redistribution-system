import 'package:flutter/material.dart';
import '../../utils/app_router.dart';

class NGODashboard extends StatefulWidget {
  const NGODashboard({Key? key}) : super(key: key);

  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard> {
  // Food preference selection
  final List<String> foodTypes = [
    "Perishables",
    "Prepared Meals",
    "Grains",
    "Beverages",
  ];

  final Set<String> selectedFoodTypes = {"Perishables", "Prepared Meals"};

  // Quantity range
  RangeValues targetQuantity = const RangeValues(50, 200);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Hope Food Bank',
          style: TextStyle(color: Colors.black),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_none, color: Colors.black),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _impactSection(),
            const SizedBox(height: 20),
            _currentDemandSection(context),
            const SizedBox(height: 20),
            _incomingDonationsSection(context),
            const SizedBox(height: 20),
            _logisticsSection(),
          ],
        ),
      ),
    );
  }

  // ================= IMPACT =================
  Widget _impactSection() {
    return Row(
      children: [
        _impactCard(
          title: "Meals Served",
          value: "12,480",
          subtitle: "+12% this month",
          color: Colors.green,
          icon: Icons.restaurant,
        ),
        const SizedBox(width: 12),
        _impactCard(
          title: "Beneficiaries",
          value: "3,820",
          subtitle: "Directly reached",
          color: Colors.orange,
          icon: Icons.groups,
        ),
      ],
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
  Widget _currentDemandSection(BuildContext context) {
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
            "Current Demand",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Selectable chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: foodTypes.map((type) {
              final isSelected = selectedFoodTypes.contains(type);

              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                selectedColor: Colors.green,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedFoodTypes.add(type);
                    } else {
                      selectedFoodTypes.remove(type);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          const Text(
            "Target Quantity (kg)",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Quantity range slider
          RangeSlider(
            values: targetQuantity,
            min: 0,
            max: 500,
            divisions: 10,
            labels: RangeLabels(
              targetQuantity.start.round().toString(),
              targetQuantity.end.round().toString(),
            ),
            onChanged: (values) {
              setState(() {
                targetQuantity = values;
              });
            },
          ),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${targetQuantity.start.round()} – ${targetQuantity.end.round()} kg",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.updateDemand);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Update Demand"),
            ),
          )
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
          "Incoming Donations",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _donationCard(
          context,
          "CityMarket Express",
          "Fresh Produce • 12.5 kg",
          "EXP: 2H",
        ),
        _donationCard(
          context,
          "Gourmet Catering Co.",
          "Prepared Meals • 25 Containers",
          "EXP: 4H",
        ),
      ],
    );
  }

  Widget _donationCard(
    BuildContext context,
    String donor,
    String details,
    String expiry,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              _actionButton(
                "Reject",
                Colors.red,
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.rejectDonation);
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

  // ================= LOGISTICS =================
  Widget _logisticsSection() {
    // Later these should come from Firestore
    double dailyCapacityKg = 500;
    double acceptedTodayKg = 325;

    // Safety check
    if (dailyCapacityKg <= 0) dailyCapacityKg = 1;

    double percentFull = acceptedTodayKg / dailyCapacityKg;
    if (percentFull > 1) percentFull = 1;

    double remainingKg = dailyCapacityKg - acceptedTodayKg;
    if (remainingKg < 0) remainingKg = 0;

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

          // Storage Capacity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Storage Capacity",
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
          ),

          const SizedBox(height: 10),

          Text(
            "Accepted Today: ${acceptedTodayKg.round()} kg / ${dailyCapacityKg.round()} kg",
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 4),

          Text(
            "Remaining Capacity: ${remainingKg.round()} kg",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 18),

          // Service Area
          const Text(
            "Service Area",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            "Currently serving Downtown & West Side",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          const Text(
            "Pickup Radius: 8 km",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
