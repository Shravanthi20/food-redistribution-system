import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/issue_service.dart';

class IssueReportingScreen extends StatefulWidget {
  final String donationId;

  const IssueReportingScreen({Key? key, required this.donationId}) : super(key: key);

  @override
  State<IssueReportingScreen> createState() => _IssueReportingScreenState();
}

class _IssueReportingScreenState extends State<IssueReportingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final IssueService _issueService = IssueService(); // Direct instantiation for simplicity
  
  String _selectedTarget = 'Volunteer'; // Default
  bool _isSubmitting = false;

  final List<String> _targetOptions = ['Volunteer', 'NGO', 'Donor', 'System/App'];

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      await _issueService.reportIssue(
        donationId: widget.donationId,
        reporterId: authProvider.user!.uid,
        reporterRole: authProvider.user!.role.name,
        targetRole: _selectedTarget,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reported to Admin successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reporting issue: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report an Issue')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Help us understand the problem.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              DropdownButtonFormField<String>(
                value: _selectedTarget,
                decoration: const InputDecoration(
                  labelText: 'Who is this issue related to?',
                  border: OutlineInputBorder(),
                ),
                items: _targetOptions.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTarget = value!);
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _reasonController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Volunteer is not moving, NGO refused pickup...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please provide a reason';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitIssue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
