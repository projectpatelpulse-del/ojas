import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignDelhiveryDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(Map<String, dynamic>) onConfirm;

  const AssignDelhiveryDialog({
    super.key,
    required this.order,
    required this.onConfirm,
  });

  @override
  State<AssignDelhiveryDialog> createState() => _AssignDelhiveryDialogState();
}

class _AssignDelhiveryDialogState extends State<AssignDelhiveryDialog> {
  late TextEditingController pickupNameController;
  late TextEditingController pickupAddressController;
  late TextEditingController pickupCityController;
  late TextEditingController pickupPinController;
  late TextEditingController pickupPhoneController;

  late TextEditingController shippingNameController;
  late TextEditingController shippingAddressController;
  late TextEditingController shippingCityController;
  late TextEditingController shippingPinController;
  late TextEditingController shippingPhoneController;
  String _realShippingPhone = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final vendor = widget.order['vendor'] ?? {};
    final vendorProfile = vendor['vendorProfile'] ?? vendor; // Try both structures
    final shipping = widget.order['shippingAddress'] ?? {};
    final user = widget.order['user'] ?? {};

    // Default Pickup from Vendor Profile/User
    pickupNameController = TextEditingController(
      text: vendorProfile['businessName'] ?? vendor['shopName'] ?? vendor['name'] ?? ''
    );
    
    // Construct full address string
    final addr = vendorProfile['address'] ?? {};
    final street = addr['street'] ?? vendor['address'] ?? '';
    final city = addr['city'] ?? '';
    final state = addr['state'] ?? '';
    
    pickupAddressController = TextEditingController(text: street);
    pickupCityController = TextEditingController(text: city);
    pickupPinController = TextEditingController(text: addr['zipCode']?.toString() ?? '');
    pickupPhoneController = TextEditingController(text: vendor['mobile']?.toString() ?? '');

    // Default Shipping from Order
    shippingNameController = TextEditingController(text: user['name'] ?? '');
    shippingAddressController = TextEditingController(text: shipping['street'] ?? '');
    shippingCityController = TextEditingController(text: shipping['city'] ?? '');
    shippingPinController = TextEditingController(text: shipping['zipCode']?.toString() ?? '');
    
    final rawPhone = user['mobile']?.toString() ?? '';
    _realShippingPhone = rawPhone;
    shippingPhoneController = TextEditingController(
      text: rawPhone.length >= 10
          ? '${rawPhone.substring(0, 2)}******${rawPhone.substring(rawPhone.length - 2)}'
          : rawPhone
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 600,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 16),
                    Text(
                      'Assign Delhivery Shipment',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Pickup Details (From Warehouse)'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Warehouse Name', pickupNameController, Icons.store)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Phone', pickupPhoneController, Icons.phone)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Street Address', pickupAddressController, Icons.location_on),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('City', pickupCityController, Icons.location_city)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Pincode', pickupPinController, Icons.pin_drop)),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Delivery Details (To Customer)'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Customer Name', shippingNameController, Icons.person)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Phone', shippingPhoneController, Icons.phone_android, readOnly: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Street Address', shippingAddressController, Icons.home),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('City', shippingCityController, Icons.location_city)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Pincode', shippingPinController, Icons.mark_as_unread_sharp)),
                      ],
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 16),
                    isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: CircularProgressIndicator(),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              setState(() => isLoading = true);
                              try {
                                final data = {
                                    'customShipping': {
                                      'name': shippingNameController.text,
                                      'add': shippingAddressController.text,
                                      'city': shippingCityController.text,
                                      'pin': shippingPinController.text,
                                      'phone': _realShippingPhone,
                                    },
                                  'dimensions': {
                                    'weight': 0.5,
                                    'length': 10,
                                    'breadth': 10,
                                    'height': 10,
                                  }
                                };
                                await widget.onConfirm(data);
                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => isLoading = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Confirm Shipment',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade900,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.blue.shade400),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
            ),
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ],
    );
  }
}
