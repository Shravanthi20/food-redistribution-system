import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_localizations_ext.dart';

/// Screen for recipients/beneficiaries to submit feedback on
/// deliveries they have received.
class RecipientFeedbackScreen extends StatefulWidget {
  final String donationId;
  final String recipientId;

  const RecipientFeedbackScreen({
    super.key,
    required this.donationId,
    required this.recipientId,
  });

  @override
  State<RecipientFeedbackScreen> createState() =>
      _RecipientFeedbackScreenState();
}

class _RecipientFeedbackScreenState extends State<RecipientFeedbackScreen> {
  final TextEditingController _commentsController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  // Rating categories (1-5 stars)
  int _foodQuality = 0;
  int _deliveryTimeliness = 0;
  int _volunteerBehavior = 0;
  int _overallSatisfaction = 0;

  bool get _isFormValid =>
      _foodQuality > 0 &&
      _deliveryTimeliness > 0 &&
      _volunteerBehavior > 0 &&
      _overallSatisfaction > 0;

  Future<void> _submitFeedback() async {
    if (!_isFormValid) return;
    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(widget.donationId)
          .collection('feedback')
          .add({
        'recipientId': widget.recipientId,
        'foodQuality': _foodQuality,
        'deliveryTimeliness': _deliveryTimeliness,
        'volunteerBehavior': _volunteerBehavior,
        'overallSatisfaction': _overallSatisfaction,
        'comments': _commentsController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also update the donation document with feedback summary
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(widget.donationId)
          .update({
        'recipientFeedback': {
          'foodQuality': _foodQuality,
          'deliveryTimeliness': _deliveryTimeliness,
          'volunteerBehavior': _volunteerBehavior,
          'overallSatisfaction': _overallSatisfaction,
          'comments': _commentsController.text.trim(),
          'submittedAt': FieldValue.serverTimestamp(),
        },
      });

      if (!mounted) return;
      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.feedbackSubmitted),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deliveryFeedback),
        elevation: 0,
      ),
      body: _submitted ? _buildThankYou(l10n) : _buildForm(l10n),
    );
  }

  Widget _buildThankYou(dynamic l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 80),
            const SizedBox(height: 24),
            Text(
              l10n.feedbackSubmitted,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(dynamic l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.rate_review,
                      color: Color(0xFF4CAF50), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.rateExperience,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Food Quality
          Semantics(
            label: l10n.foodQuality,
            child: _buildRatingRow(
              label: l10n.foodQuality,
              icon: Icons.restaurant,
              color: Colors.orange,
              value: _foodQuality,
              onChanged: (v) => setState(() => _foodQuality = v),
            ),
          ),
          const SizedBox(height: 16),

          // Delivery Timeliness
          Semantics(
            label: l10n.deliveryTimeliness,
            child: _buildRatingRow(
              label: l10n.deliveryTimeliness,
              icon: Icons.timer,
              color: Colors.blue,
              value: _deliveryTimeliness,
              onChanged: (v) => setState(() => _deliveryTimeliness = v),
            ),
          ),
          const SizedBox(height: 16),

          // Volunteer Behavior
          Semantics(
            label: l10n.volunteerBehavior,
            child: _buildRatingRow(
              label: l10n.volunteerBehavior,
              icon: Icons.person,
              color: Colors.purple,
              value: _volunteerBehavior,
              onChanged: (v) => setState(() => _volunteerBehavior = v),
            ),
          ),
          const SizedBox(height: 16),

          // Overall Satisfaction
          Semantics(
            label: l10n.overallSatisfaction,
            child: _buildRatingRow(
              label: l10n.overallSatisfaction,
              icon: Icons.star,
              color: Colors.amber,
              value: _overallSatisfaction,
              onChanged: (v) => setState(() => _overallSatisfaction = v),
            ),
          ),
          const SizedBox(height: 24),

          // Comments
          Text(
            l10n.feedbackComments,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.feedbackComments,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Submit Button
          Semantics(
            button: true,
            label: l10n.submitFeedback,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isFormValid && !_isSubmitting)
                    ? _submitFeedback
                    : null,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(l10n.submitFeedback,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow({
    required String label,
    required IconData icon,
    required Color color,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () => onChanged(starIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      starIndex <= value ? Icons.star : Icons.star_border,
                      color: starIndex <= value ? Colors.amber : Colors.grey,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }
}
