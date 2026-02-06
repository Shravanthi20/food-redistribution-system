import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_router.dart';
import '../../models/user.dart';

class DocumentSubmissionScreen extends StatefulWidget {
  const DocumentSubmissionScreen({Key? key}) : super(key: key);

  @override
  State<DocumentSubmissionScreen> createState() => _DocumentSubmissionScreenState();
}

class _DocumentSubmissionScreenState extends State<DocumentSubmissionScreen> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jepg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _submitDocument() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // We assume the user is already logged in (registered state)
      final userId = authProvider.user!.uid;
      
      await authProvider.uploadVerificationDocument(userId, _selectedFile!);
      
      if (mounted) {
        // Navigate to Pending Screen
        Navigator.pushReplacementNamed(context, AppRouter.verificationPending);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading document: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Verification')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Document Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please upload your NGO Registration Certificate or Food Safety License to split.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedFile?.name ?? 'No file selected',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: _selectedFile != null ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                  ),
                  if (_selectedFile == null)
                    ElevatedButton(
                      onPressed: _pickFile,
                      child: const Text('Choose'),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedFile = null),
                    )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedFile != null && !_isUploading) ? _submitDocument : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit for Verification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
