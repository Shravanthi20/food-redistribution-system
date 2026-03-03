import 'package:flutter/material.dart';
import '../../models/hygiene_checklist.dart';
import '../../services/hygiene_service.dart';
import 'ngo_reject_donation_screen.dart';
import 'ngo_clarify_request_screen.dart';

class HygieneChecklistScreen extends StatefulWidget {
  final String donationId;
  final String ngoId;
  final String donorId;
  final String donationTitle;

  const HygieneChecklistScreen({
    super.key,
    required this.donationId,
    required this.ngoId,
    required this.donorId,
    required this.donationTitle,
  });

  @override
  State<HygieneChecklistScreen> createState() => _HygieneChecklistScreenState();
}

class _HygieneChecklistScreenState extends State<HygieneChecklistScreen> {
  final HygieneService _hygieneService = HygieneService();
  late List<HygieneChecklistItem> _items;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _items = HygieneChecklistTemplate.defaultItems;
    _loadExistingChecklist();
  }

  Future<void> _loadExistingChecklist() async {
    setState(() => _isLoading = true);
    try {
      final existing =
          await _hygieneService.getHygieneChecklist(widget.donationId);
      if (existing != null && existing.items.isNotEmpty) {
        setState(() {
          _items = existing.items;
          _notesController.text = existing.notes ?? '';
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  bool get _allMandatoryChecked =>
      _items.where((i) => i.isMandatory).every((i) => i.isChecked);

  Future<void> _acceptDonation() async {
    setState(() => _isSubmitting = true);
    try {
      final checklist = HygieneChecklist(
        donationId: widget.donationId,
        ngoId: widget.ngoId,
        items: _items,
        isComplete: true,
        completedAt: DateTime.now(),
        notes: _notesController.text.trim(),
      );
      await _hygieneService.acceptDonation(
        donationId: widget.donationId,
        ngoId: widget.ngoId,
        checklist: checklist,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Donation accepted & record locked.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _rejectDonation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NgoRejectDonationScreen(
          donationId: widget.donationId,
          ngoId: widget.ngoId,
          donorId: widget.donorId,
        ),
      ),
    );
  }

  void _requestClarification() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NgoClarifyRequestScreen(
          donationId: widget.donationId,
          ngoId: widget.ngoId,
          donorId: widget.donorId,
          donationTitle: widget.donationTitle,
        ),
      ),
    );
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
            const Text('Hygiene Checklist',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.donationTitle,
                style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : Column(
              children: [
                _buildProgressHeader(),
                Expanded(child: _buildChecklistItems()),
                _buildNotesField(),
                _buildActionButtons(),
              ],
            ),
    );
  }

  Widget _buildProgressHeader() {
    final checked = _items.where((i) => i.isMandatory && i.isChecked).length;
    final total = _items.where((i) => i.isMandatory).length;
    final progress = total == 0 ? 0.0 : checked / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2535),
        border: Border(bottom: BorderSide(color: Color(0xFF2D3748))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mandatory Items',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('$checked / $total checked',
                  style: TextStyle(
                      color: _allMandatoryChecked
                          ? const Color(0xFF4CAF50)
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF2D3748),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? const Color(0xFF4CAF50) : Colors.orange,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          if (!_allMandatoryChecked)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ Complete all mandatory items to enable acceptance.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistItems() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2535),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isChecked
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                  : const Color(0xFF2D3748),
            ),
          ),
          child: CheckboxListTile(
            value: item.isChecked,
            onChanged: (val) {
              setState(() => _items[index].isChecked = val ?? false);
            },
            activeColor: const Color(0xFF4CAF50),
            checkColor: Colors.white,
            title: Text(
              item.question,
              style: TextStyle(
                color: item.isChecked ? Colors.white : Colors.white70,
                fontSize: 14,
              ),
            ),
            subtitle: item.isMandatory
                ? const Text('Mandatory',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11))
                : const Text('Optional',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
            controlAffinity: ListTileControlAffinity.leading,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  Widget _buildNotesField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _notesController,
        style: const TextStyle(color: Colors.white),
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'Additional notes (optional)...',
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF1A2535),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D3748)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D3748)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4CAF50)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2535),
        border: Border(top: BorderSide(color: Color(0xFF2D3748))),
      ),
      child: Column(
        children: [
          // Accept button — enabled only when all mandatory items are checked
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_allMandatoryChecked && !_isSubmitting)
                  ? _acceptDonation
                  : null,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Accept Donation',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF2D3748),
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Request Clarification
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _requestClarification,
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Clarify', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Reject
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rejectDonation,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Reject', style: TextStyle(fontSize: 12)),
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
