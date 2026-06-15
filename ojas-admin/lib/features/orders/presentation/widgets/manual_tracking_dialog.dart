import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManualTrackingDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(Map<String, String>) onConfirm;

  const ManualTrackingDialog({
    super.key,
    required this.order,
    required this.onConfirm,
  });

  @override
  State<ManualTrackingDialog> createState() => _ManualTrackingDialogState();
}

class _ManualTrackingDialogState extends State<ManualTrackingDialog> {
  late TextEditingController _awbController;
  late TextEditingController _courierController;
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _awbController = TextEditingController(text: widget.order['awb'] ?? '');
    _courierController = TextEditingController(text: widget.order['courierPartner'] ?? 'Delhivery');
    _urlController = TextEditingController(text: widget.order['trackingUrl'] ?? '');
  }

  @override
  void dispose() {
    _awbController.dispose();
    _courierController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_location_alt_outlined, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Update Tracking Info',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              'Order ID: ${widget.order['orderId']}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            _buildField('Courier Partner', _courierController, 'e.g. BlueDart, Delhivery, FedEx'),
            const SizedBox(height: 16),
            _buildField('AWB / Tracking Number', _awbController, 'Enter tracking ID'),
            const SizedBox(height: 16),
            _buildField('Tracking URL (Optional)', _urlController, 'https://track.example.com/...'),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onConfirm({
                      'awb': _awbController.text.trim(),
                      'courierPartner': _courierController.text.trim(),
                      'trackingUrl': _urlController.text.trim(),
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Save Tracking Info', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
