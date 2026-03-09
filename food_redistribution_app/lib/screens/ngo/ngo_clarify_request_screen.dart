import 'package:flutter/material.dart';
import 'package:food_redistribution_app/utils/app_theme.dart';
import '../../services/hygiene_service.dart';
import '../../models/hygiene_checklist.dart';

class NgoClarifyRequestScreen extends StatefulWidget {
  final String donationId;
  final String ngoId;
  final String donorId;
  final String donationTitle;

  const NgoClarifyRequestScreen({
    super.key,
    required this.donationId,
    required this.ngoId,
    required this.donorId,
    required this.donationTitle,
  });

  @override
  State<NgoClarifyRequestScreen> createState() =>
      _NgoClarifyRequestScreenState();
}

class _NgoClarifyRequestScreenState extends State<NgoClarifyRequestScreen> {
  final HygieneService _hygieneService = HygieneService();
  final TextEditingController _questionController = TextEditingController();
  bool _isSending = false;

  static const List<String> _quickQuestions = [
    'What was the exact preparation time?',
    'What temperature was the food stored at?',
    'Was the food tested for allergens?',
    'Can you confirm the exact quantity?',
    'What packaging was used?',
  ];

  Future<void> _sendClarification() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please write your question first.'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      await _hygieneService.sendClarificationRequest(
        donationId: widget.donationId,
        ngoId: widget.ngoId,
        donorId: widget.donorId,
        question: question,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✉️ Clarification request sent to donor.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceOffWhite,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Request Clarification',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Questions',
                      style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickQuestions
                        .map((q) => GestureDetector(
                              onTap: () =>
                                  setState(() => _questionController.text = q),
                              child: Chip(
                                label: Text(q,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.black54)),
                                backgroundColor: AppTheme.surfaceOffWhite,
                                side:
                                    const BorderSide(color: AppTheme.iosGray4),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Your Question *',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _questionController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Type your question for the donor...',
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
                        borderSide: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildExistingClarifications(),
                ],
              ),
            ),
          ),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      color: Colors.orange.withValues(alpha: 0.12),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'The donation status will change to "Pending Clarification". Donor will be notified.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingClarifications() {
    return StreamBuilder<List<ClarificationRequest>>(
      stream: _hygieneService.getClarifications(widget.donationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Previous Clarifications',
                style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 8),
            ...snapshot.data!.map((c) => _buildClarificationCard(c)),
          ],
        );
      },
    );
  }

  Widget _buildClarificationCard(ClarificationRequest c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOffWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: c.isResolved
              ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
              : Colors.orange.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: Colors.orange, size: 16),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(c.question,
                      style:
                          const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
            ],
          ),
          if (c.reply != null) ...[
            const SizedBox(height: 8),
            const Divider(color: AppTheme.iosGray4, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.reply, color: Color(0xFF4CAF50), size: 16),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(c.reply!,
                        style: const TextStyle(
                            color: Color(0xFF4CAF50), fontSize: 13))),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Chip(
            label: Text(c.isResolved ? 'Resolved' : 'Awaiting Reply',
                style: const TextStyle(fontSize: 10)),
            backgroundColor: c.isResolved
                ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                : Colors.orange.withValues(alpha: 0.2),
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
            labelStyle: TextStyle(
                color: c.isResolved ? const Color(0xFF4CAF50) : Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceOffWhite,
        border: Border(top: BorderSide(color: AppTheme.iosGray4)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSending ? null : _sendClarification,
          icon: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.textPrimary))
              : const Icon(Icons.send),
          label: const Text('Send Clarification Request',
              style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
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
    _questionController.dispose();
    super.dispose();
  }
}
