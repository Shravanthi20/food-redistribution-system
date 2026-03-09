import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_redistribution_app/utils/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/hygiene_service.dart';
import '../../utils/app_localizations_ext.dart';
import 'volunteer_unsafe_cancel_screen.dart';

class VolunteerPickupProofScreen extends StatefulWidget {
  final String donationId;
  final String volunteerId;
  final String ngoId;
  final String donorId;
  final String donationTitle;

  const VolunteerPickupProofScreen({
    super.key,
    required this.donationId,
    required this.volunteerId,
    required this.ngoId,
    required this.donorId,
    required this.donationTitle,
  });

  @override
  State<VolunteerPickupProofScreen> createState() =>
      _VolunteerPickupProofScreenState();
}

class _VolunteerPickupProofScreenState
    extends State<VolunteerPickupProofScreen> {
  final HygieneService _hygieneService = HygieneService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _notesController = TextEditingController();

  File? _capturedImage;
  String _foodCondition = 'good'; // good / moderate / unsafe
  bool _isUploading = false;
  bool _uploadComplete = false;

  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (photo != null) {
        setState(() => _capturedImage = File(photo.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Camera error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadProof() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please take a photo first.'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      await _hygieneService.uploadPickupProofImage(
        donationId: widget.donationId,
        volunteerId: widget.volunteerId,
        imageFile: _capturedImage!,
        foodCondition: _foodCondition,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadComplete = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pickup proof uploaded successfully.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _cancelUnsafe() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VolunteerUnsafeCancelScreen(
          donationId: widget.donationId,
          volunteerId: widget.volunteerId,
          ngoId: widget.ngoId,
          donorId: widget.donorId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceOffWhite,
        foregroundColor: AppTheme.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.pickupProof,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.donationTitle,
                style: const TextStyle(fontSize: 11, color: Colors.black45)),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildMandatoryBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoSection(),
                  const SizedBox(height: 20),
                  _buildFoodConditionSelector(),
                  const SizedBox(height: 20),
                  _buildNotesField(),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMandatoryBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
      child: const Row(
        children: [
          Icon(Icons.camera_alt, color: Color(0xFF4CAF50), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Photo is required before marking pickup complete.',
              style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _captureImage,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surfaceOffWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _capturedImage != null
                ? const Color(0xFF4CAF50)
                : AppTheme.iosGray4,
            width: 2,
          ),
        ),
        child: _capturedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_capturedImage!, fit: BoxFit.cover),
                    if (_uploadComplete)
                      Container(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                        child: const Center(
                          child: Icon(Icons.check_circle,
                              color: AppTheme.textPrimary, size: 60),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _captureImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.refresh,
                              color: AppTheme.textPrimary, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      color: Color(0xFF4CAF50), size: 48),
                  SizedBox(height: 10),
                  Text('Tap to take a photo of the food',
                      style: TextStyle(color: Colors.black54, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('This is mandatory for pickup completion',
                      style: TextStyle(color: Colors.black38, fontSize: 12)),
                ],
              ),
      ),
    );
  }

  Widget _buildFoodConditionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${context.l10n.foodCondition} *',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildConditionChip('good', 'Good', const Color(0xFF4CAF50),
                Icons.thumb_up_outlined),
            const SizedBox(width: 10),
            _buildConditionChip('moderate', 'Moderate', Colors.orange,
                Icons.warning_amber_outlined),
            const SizedBox(width: 10),
            _buildConditionChip(
                'unsafe', 'Unsafe', Colors.redAccent, Icons.dangerous_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionChip(
      String value, String label, Color color, IconData icon) {
    final isSelected = _foodCondition == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _foodCondition = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : AppTheme.surfaceOffWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected ? color : AppTheme.iosGray4,
                width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.black38, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? color : Colors.black38,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Condition Notes (optional)',
            style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          style: const TextStyle(color: AppTheme.textPrimary),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe any observations about the food condition...',
            hintStyle: const TextStyle(color: Colors.black38),
            filled: true,
            fillColor: AppTheme.surfaceOffWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.iosGray4),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.iosGray4),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceOffWhite,
        border: Border(top: BorderSide(color: AppTheme.iosGray4)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (_capturedImage != null && !_isUploading && !_uploadComplete)
                      ? _uploadProof
                      : null,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                  _uploadComplete
                      ? 'Proof Uploaded ✓'
                      : _isUploading
                          ? 'Uploading...'
                          : 'Upload Pickup Proof',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.iosGray5,
                disabledForegroundColor: AppTheme.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cancelUnsafe,
              icon: const Icon(Icons.dangerous_outlined, size: 16),
              label: const Text('Cancel – Food Unsafe',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
