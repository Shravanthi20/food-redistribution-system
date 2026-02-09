import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/verification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class VerifyUserScreen extends StatefulWidget {
  final Map<String, dynamic> verificationData;

  const VerifyUserScreen({Key? key, required this.verificationData}) : super(key: key);

  @override
  State<VerifyUserScreen> createState() => _VerifyUserScreenState();
}

class _VerifyUserScreenState extends State<VerifyUserScreen> {
  bool _isProcessing = false;
  final TextEditingController _notesController = TextEditingController();

  Map<String, dynamic> get submission => widget.verificationData['submission'] ?? {};
  Map<String, dynamic> get user => widget.verificationData['user'] ?? {};
  String get submissionId => widget.verificationData['id'];

  Future<void> _processVerification(VerificationStatus status) async {
    setState(() => _isProcessing = true);
    
    try {
      final adminId = Provider.of<AuthProvider>(context, listen: false).firebaseUser?.uid ?? 'admin';
      
      await Provider.of<AdminDashboardProvider>(context, listen: false)
          .reviewVerification(
            submissionId, 
            adminId, 
            status, 
            _notesController.text.isNotEmpty ? _notesController.text : null
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification ${status.name}')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Verification'),
        content: TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection (Required)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (_notesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(ctx);
              _processVerification(VerificationStatus.rejected);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documents = (submission['documentInfo'] as List<dynamic>?) ?? [];
    // Just finding the first doc URL for simple display if available
    // In current implementation, 'information' might be the URL or text
    
    return Scaffold(
      appBar: AppBar(title: const Text('Verify User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: user['profileImageUrl'] != null 
                              ? NetworkImage(user['profileImageUrl']) 
                              : null,
                          child: user['profileImageUrl'] == null 
                              ? Text((user['email'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 24))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['email'] ?? 'Unknown Email', style: Theme.of(context).textTheme.titleLarge),
                              Text('Role: ${submission['userRole']}', style: Theme.of(context).textTheme.bodyMedium),
                              Text('Submitted: ${submission['submittedAt']?.toDate().toString() ?? 'Unknown'}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text('Additional Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Name: ${user['fullName'] ?? '${user['firstName']} ${user['lastName']}'}'),
                    Text('Phone: ${user['phoneNumber'] ?? user['phone'] ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Text('Submitted Documents', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            
            if (documents.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No documents found')),
                ),
              ),
              
            ...documents.map((doc) {
              final isUrl = doc['information'].toString().startsWith('http');
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: Text(doc['type'] ?? 'Document'),
                  subtitle: Text(isUrl ? 'Tap to view document' : doc['information']),
                  trailing: isUrl ? const Icon(Icons.open_in_new) : null,
                  onTap: isUrl ? () => _launchUrl(doc['information']) : null,
                ),
              );
            }).toList(),
            
            const SizedBox(height: 32),
            
            // Actions
            if (!_isProcessing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _showRejectDialog,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => _processVerification(VerificationStatus.approved),
                    ),
                  ),
                ],
              )
            else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')),
        );
      }
    }
  }
}
