import 'package:flutter/material.dart';
import 'package:food_redistribution_app/utils/app_theme.dart';
import '../../services/hygiene_service.dart';
import '../../utils/app_localizations_ext.dart';

class VolunteerUnsafeCancelScreen extends StatefulWidget {
  final String donationId;
  final String volunteerId;
  final String ngoId;
  final String donorId;
  final String? adminId;

  const VolunteerUnsafeCancelScreen({
    super.key,
    required this.donationId,
    required this.volunteerId,
    required this.ngoId,
    required this.donorId,
    this.adminId,
  });

  @override
  State<VolunteerUnsafeCancelScreen> createState() =>
      _VolunteerUnsafeCancelScreenState();
}

class _VolunteerUnsafeCancelScreenState
    extends State<VolunteerUnsafeCancelScreen> {
  final HygieneService _hygieneService = HygieneService();
  final TextEditingController _detailsController = TextEditingController();

  String? _selectedReason;
  bool _isSubmitting = false;
  bool _hasConfirmed = false;

  static const List<String> _unsafeReasons = [
    'Food is visibly spoiled or moldy',
    'Strong foul odor detected',
    'Improper storage temperature – food unsafe to serve',
    'Pest contamination visible',
    'Damaged/broken packaging with exposure',
    'Food looks different from listing description',
    'Donor confirmed food is no longer safe',
    'Other safety concern (describe below)',
  ];

  Future<void> _submitCancellation() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a reason.'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    final details = _detailsController.text.trim();

    setState(() => _isSubmitting = true);
    try {
      await _hygieneService.cancelPickupUnsafe(
        donationId: widget.donationId,
        volunteerId: widget.volunteerId,
        reason: _selectedReason!,
        details: details,
        ngoId: widget.ngoId,
        donorId: widget.donorId,
        adminId: widget.adminId,
      );
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceOffWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            Text(context.l10n.cancellationLogged,
                style:
                    const TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
          ],
        ),
        content: Text(
          context.l10n.stakeholdersNotified,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Done'),
          ),
        ],
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
        title: Text(context.l10n.cancelUnsafeFood,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.redAccent)),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDangerBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${context.l10n.whyFoodUnsafe} *',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 12),
                  ..._unsafeReasons.map((r) => _buildReasonTile(r)),
                  const SizedBox(height: 20),
                  Text('${context.l10n.detailedDescription} *',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _detailsController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Describe what you observed in detail. This will be included in the audit log...',
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
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildNotificationInfo(),
                  const SizedBox(height: 16),
                  _buildConfirmationCheckbox(),
                ],
              ),
            ),
          ),
          _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildDangerBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      color: Colors.redAccent.withValues(alpha: 0.12),
      child: const Row(
        children: [
          Icon(Icons.health_and_safety_outlined,
              color: Colors.redAccent, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This action cannot be undone. All stakeholders will be immediately notified. A full audit log will be created.',
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonTile(String reason) {
    final isSelected = _selectedReason == reason;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.redAccent.withValues(alpha: 0.12)
              : AppTheme.surfaceOffWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.redAccent : AppTheme.iosGray4,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.redAccent : Colors.black38,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reason,
                style: TextStyle(
                    color: isSelected ? Colors.redAccent : Colors.black54,
                    fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOffWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.iosGray4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Will immediately notify:',
              style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 8),
          _notifRow(Icons.business, 'NGO – ${widget.ngoId}'),
          _notifRow(Icons.person, 'Donor – ${widget.donorId}'),
          _notifRow(Icons.admin_panel_settings, 'Platform Admin'),
        ],
      ),
    );
  }

  Widget _notifRow(IconData icon, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon,
                color: Colors.redAccent.withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 8),
            Flexible(
                child: Text(label,
                    style:
                        const TextStyle(color: Colors.black45, fontSize: 12))),
          ],
        ),
      );

  Widget _buildConfirmationCheckbox() {
    return Semantics(
      label: context.l10n.confirmCancellation,
      checked: _hasConfirmed,
      child: CheckboxListTile(
        value: _hasConfirmed,
        onChanged: (v) => setState(() => _hasConfirmed = v ?? false),
        activeColor: Colors.redAccent,
        title: const Text(
          'I confirm that the food was unsafe and I have a valid reason for this cancellation.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCancelButton() {
    final canSubmit =
        _selectedReason != null && _hasConfirmed && !_isSubmitting;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceOffWhite,
        border: Border(top: BorderSide(color: AppTheme.iosGray4)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canSubmit ? _submitCancellation : null,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.textPrimary))
              : const Icon(Icons.dangerous),
          label: const Text('Submit Cancellation & Notify All',
              style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.iosGray5,
            disabledForegroundColor: AppTheme.textMuted,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }
}
