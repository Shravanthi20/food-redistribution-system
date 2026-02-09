import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/issue_service.dart';
import '../../services/food_donation_service.dart'; // [NEW]
import '../../utils/app_router.dart';
import '../../models/food_donation.dart'; // To fetch donation if needed, or pass ID.

class AdminIssuesScreen extends StatefulWidget {
  const AdminIssuesScreen({Key? key}) : super(key: key);

  @override
  State<AdminIssuesScreen> createState() => _AdminIssuesScreenState();
}

class _AdminIssuesScreenState extends State<AdminIssuesScreen> {
  final IssueService _issueService = IssueService();
  final FoodDonationService _donationService = FoodDonationService(); // [NEW]

  void _resolveIssue(String issueId) {
    showDialog(
      context: context,
      builder: (context) {
        final noteController = TextEditingController();
        return AlertDialog(
          title: const Text('Resolve Issue'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(hintText: 'Resolution notes (optional)'),
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              child: const Text('Mark Resolved'),
              onPressed: () async {
                await _issueService.resolveIssue(issueId, noteController.text);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _reassign(String donationId) async {
     try {
       final donation = await _donationService.getDonation(donationId);
       if (donation != null && mounted) {
          Navigator.pushNamed(
            context, 
            AppRouter.donationDetail,
            arguments: donation,
          );
       } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Donation not found')),
           );
         }
       }
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error fetching donation: $e')),
         );
       }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issue Management')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _issueService.getOpenIssues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No open issues'));
          }

          final issues = snapshot.data!.docs;

          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index].data() as Map<String, dynamic>;
              final issueId = issues[index].id;
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                         children: [
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                               color: Colors.red.shade100,
                               borderRadius: BorderRadius.circular(4),
                             ),
                             child: Text(
                               'Target: ${issue['targetRole']}',
                               style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                             ),
                           ),
                           const Spacer(),
                           Text(
                             issue['createdAt'] != null 
                             ? (issue['createdAt'] as Timestamp).toDate().toString().substring(0, 16)
                             : 'Just now',
                             style: const TextStyle(color: Colors.grey, fontSize: 12),
                           ),
                         ],
                       ),
                       const SizedBox(height: 8),
                       Text('Reported By: ${issue['reporterRole']}'),
                       const SizedBox(height: 8),
                       Text(
                         issue['reason'] ?? 'No reason provided',
                         style: const TextStyle(fontSize: 16),
                       ),
                       const SizedBox(height: 12),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.end,
                         children: [
                           OutlinedButton(
                             onPressed: () => _reassign(issue['donationId']),
                             child: const Text('View/Reassign'),
                           ),
                           const SizedBox(width: 8),
                           ElevatedButton(
                             onPressed: () => _resolveIssue(issueId),
                             child: const Text('Resolve'),
                           ),
                         ],
                       )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
