import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ojas_vendor/core/services/shipping_label_service.dart';

class ShippingLabelDialog extends StatefulWidget {
  final Map<String, dynamic> order;

  const ShippingLabelDialog({super.key, required this.order});

  @override
  State<ShippingLabelDialog> createState() => _ShippingLabelDialogState();
}

class _ShippingLabelDialogState extends State<ShippingLabelDialog> {
  late TextEditingController _shipToNameController;
  late TextEditingController _shipToAddressController;
  late TextEditingController _shipToPhoneController;
  late TextEditingController _fromNameController;
  late TextEditingController _fromAddressController;
  late TextEditingController _fromPhoneController;
  late TextEditingController _weightController;
  late TextEditingController _dimensionsController;
  late TextEditingController _dateController;
  late TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();
    
    // Helper to handle cases where 'user' or 'vendor' might be returned as a List
    Map<String, dynamic> getMap(dynamic data) {
      if (data is Map) return Map<String, dynamic>.from(data);
      if (data is List && data.isNotEmpty && data[0] is Map) {
        return Map<String, dynamic>.from(data[0]);
      }
      return {};
    }

    final customer = getMap(widget.order['user']);
    final vendor = getMap(widget.order['vendor']);
    final vendorProfile = getMap(vendor['vendorProfile'] ?? vendor);
    final shipping = getMap(widget.order['shippingAddress']);

    // 1. Ship To (Customer)
    _shipToNameController = TextEditingController(text: (customer['name'] ?? '').toString());
    
    // Construct Shipping Address
    String fullShippingAddress = '';
    if (shipping.isNotEmpty) {
      fullShippingAddress = [
        shipping['street'],
        shipping['city'],
        shipping['state'],
        shipping['zipCode']
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    }
    _shipToAddressController = TextEditingController(text: fullShippingAddress);
    _shipToPhoneController = TextEditingController(text: (customer['mobile'] ?? '').toString());
    
    // 2. From (Vendor)
    _fromNameController = TextEditingController(
      text: (vendorProfile['businessName'] ?? vendor['shopName'] ?? vendor['name'] ?? '').toString()
    );

    // Construct Vendor Address
    String fullVendorAddress = '';
    final vAddr = getMap(vendorProfile['address'] ?? {});
    if (vAddr.isNotEmpty) {
      fullVendorAddress = [
        vAddr['street'],
        vAddr['city'],
        vAddr['state'],
        vAddr['zipCode']
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    } else {
      fullVendorAddress = (vendor['address'] ?? '').toString();
    }
    
    _fromAddressController = TextEditingController(text: fullVendorAddress);
    _fromPhoneController = TextEditingController(text: (vendor['mobile'] ?? '').toString());

    _weightController = TextEditingController(text: '0.5 KG');
    _dimensionsController = TextEditingController(text: '10x10x10 cm');
    _dateController = TextEditingController(text: widget.order['createdAt'] != null 
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.order['createdAt'].toString()))
        : DateFormat('yyyy-MM-dd').format(DateTime.now()));
    _remarksController = TextEditingController(text: 'HANDLE WITH CARE');
  }

  @override
  void dispose() {
    _shipToNameController.dispose();
    _shipToAddressController.dispose();
    _shipToPhoneController.dispose();
    _fromNameController.dispose();
    _fromAddressController.dispose();
    _fromPhoneController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _dateController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.local_shipping_outlined, color: Colors.orange.shade700, size: 24),
                ),
                const SizedBox(width: 16),
                Text('Customize Shipping Label', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSectionHeader('SHIP TO (Customer Details)'),
                    _buildTextField(_shipToNameController, 'Customer Name'),
                    _buildTextField(_shipToAddressController, 'Shipping Address', maxLines: 2),
                    _buildTextField(_shipToPhoneController, 'Customer Phone'),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader('FROM (Vendor Details)'),
                    _buildTextField(_fromNameController, 'Store/Vendor Name'),
                    _buildTextField(_fromAddressController, 'Store Address', maxLines: 2),
                    _buildTextField(_fromPhoneController, 'Store Phone'),

                    const SizedBox(height: 24),
                    _buildSectionHeader('PACKAGE & LOGISTICS'),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_weightController, 'Weight')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_dimensionsController, 'Dimensions')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_dateController, 'Shipping Date')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_remarksController, 'Remarks')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                    final customData = {
                      'shipToName': _shipToNameController.text,
                      'shipToAddress': _shipToAddressController.text,
                      'shipToPhone': _shipToPhoneController.text,
                      'fromName': _fromNameController.text,
                      'fromAddress': _fromAddressController.text,
                      'fromPhone': _fromPhoneController.text,
                      'weight': _weightController.text,
                      'dimensions': _dimensionsController.text,
                      'date': _dateController.text,
                      'remarks': _remarksController.text,
                    };
                    ShippingLabelService.generateAndDownloadLabel(widget.order, customData: customData);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Download Label', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.orange.shade700)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
