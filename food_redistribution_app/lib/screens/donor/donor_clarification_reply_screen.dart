import 'package:flutter/material.dart';
import '../../services/hygiene_service.dart';
import '../../models/hygiene_checklist.dart';

/// Screen for the DONOR to view and reply to NGO clarification requests.
class DonorClarificationReplyScreen extends StatefulWidget {
  final String donationId;
  final String donorId;
  final String donationTitle;

  const DonorClarificationReplyScreen({
    super.key,
    required this.donationId,
    required this.donorId,
    required this.donationTitle,
  });

  @override
  State<DonorClarificationReplyScreen> createState() =>
      _DonorClarificationReplyScreenState();
}

class _DonorClarificationReplyScreenState
    extends State<DonorClarificationReplyScreen> {
  final HygieneService _hygieneService = HygieneService();
  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, bool> _submitting = {};

  Future<void> _submitReply(String clarificationId, String reply) async {
    if (reply.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please write a reply before submitting.'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _submitting[clarificationId] = true);
    try {
      await _hygieneService.replyClarification(
        donationId: widget.donationId,
        clarificationId: clarificationId,
        reply: reply.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reply sent to the NGO.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _submitting[clarificationId] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2535),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clarification Requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.donationTitle,
                style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<ClarificationRequest>>(
        stream: _hygieneService.getClarifications(widget.donationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final requests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) =>
                _buildClarificationCard(requests[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read_outlined, color: Colors.white24, size: 60),
          SizedBox(height: 12),
          Text('No clarification requests yet',
              style: TextStyle(color: Colors.white38, fontSize: 16)),
          SizedBox(height: 4),
          Text('The NGO will contact you here if they need more info.',
              style: TextStyle(color: Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildClarificationCard(ClarificationRequest c) {
    _replyControllers.putIfAbsent(c.id, () => TextEditingController());
    final controller = _replyControllers[c.id]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2535),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: c.isResolved
              ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
              : Colors.orange.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(c.isResolved ? 'Replied ✓' : '⏳ Awaiting Reply',
                    style: TextStyle(
                        fontSize: 10,
                        color: c.isResolved
                            ? const Color(0xFF4CAF50)
                            : Colors.orange)),
                backgroundColor: c.isResolved
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                _formatDate(c.createdAt),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // NGO question
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.help_outline, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NGO Question',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(c.question,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // If already replied, show reply
          if (c.reply != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply, color: Color(0xFF4CAF50), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Reply',
                            style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(c.reply!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // If not replied, show reply input
          if (!c.isResolved) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type your reply...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0F1923),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2D3748)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2D3748)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_submitting[c.id] == true)
                    ? null
                    : () => _submitReply(c.id, controller.text),
                icon: (_submitting[c.id] == true)
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, size: 16),
                label: const Text('Send Reply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    for (final c in _replyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
