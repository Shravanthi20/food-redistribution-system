import 'package:flutter/material.dart';

class TaskExecutionScreen extends StatefulWidget {
  const TaskExecutionScreen({Key? key}) : super(key: key);

  @override
  State<TaskExecutionScreen> createState() => _TaskExecutionScreenState();
}

class _TaskExecutionScreenState extends State<TaskExecutionScreen> {
  String status = "Assigned";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Task Execution",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusCard(),
            const SizedBox(height: 20),

            const Text(
              "Pickup & Drop Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _infoRow(Icons.store, "Pickup", "CityMarket Express, Downtown"),
            _infoRow(Icons.location_on, "Drop", "Hope Food Bank"),
            _infoRow(Icons.restaurant, "Food", "Prepared Meals • 25 packs"),
            _infoRow(Icons.timer, "Deadline", "Within 2 hours"),

            const SizedBox(height: 25),

            // Pickup Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: status == "Assigned"
                    ? () {
                        setState(() {
                          status = "Picked Up";
                        });
                      }
                    : null,
                child: const Text("Confirm Pickup"),
              ),
            ),

            const SizedBox(height: 12),

            // Enroute Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: status == "Picked Up"
                    ? () {
                        setState(() {
                          status = "En Route";
                        });
                      }
                    : null,
                child: const Text("Mark En-route"),
              ),
            ),

            const SizedBox(height: 12),

            // Delivery Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: status == "En Route"
                    ? () {
                        setState(() {
                          status = "Delivered";
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Delivery Confirmed Successfully!"),
                          ),
                        );
                      }
                    : null,
                child: const Text("Confirm Delivery"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    Color color;

    if (status == "Assigned") {
      color = Colors.grey;
    } else if (status == "Picked Up") {
      color = Colors.green;
    } else if (status == "En Route") {
      color = Colors.orange;
    } else {
      color = Colors.blue;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: color),
          const SizedBox(width: 10),
          Text(
            "Current Status: $status",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
