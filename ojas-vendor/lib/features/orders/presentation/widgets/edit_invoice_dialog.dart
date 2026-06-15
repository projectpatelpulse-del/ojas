import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/services/invoice_service.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class EditInvoiceDialog extends StatefulWidget {
  final Map<String, dynamic> order;

  const EditInvoiceDialog({super.key, required this.order});

  @override
  State<EditInvoiceDialog> createState() => _EditInvoiceDialogState();
}

class _EditInvoiceDialogState extends State<EditInvoiceDialog> {
  late Map<String, dynamic> editableOrder;
  bool _showPreview = false;
  
  late TextEditingController _orderIdController;
  late TextEditingController _invoiceNumberController;
  late TextEditingController _invoiceDateController;
  late TextEditingController _customerNameController;
  late TextEditingController _customerEmailController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _vendorNameController;
  late TextEditingController _vendorEmailController;
  late TextEditingController _vendorPhoneController;
  late TextEditingController _taxRateController;
  
  // Payment Controllers
  late TextEditingController _accNoController;
  late TextEditingController _accNameController;
  late TextEditingController _branchController;
  
  // Terms Controllers
  late TextEditingController _term1Controller;
  late TextEditingController _term2Controller;

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    editableOrder = Map<String, dynamic>.from(widget.order);
    
    final customerData = editableOrder['user'];
    final Map<String, dynamic> customer = (customerData is Map) ? Map<String, dynamic>.from(customerData) : {};
    
    final vendorData = editableOrder['vendor'];
    final Map<String, dynamic> vendor = (vendorData is Map) ? Map<String, dynamic>.from(vendorData) : {};
    
    final String oId = editableOrder['orderId'] ?? 'N/A';
    _orderIdController = TextEditingController(text: oId);
    _invoiceNumberController = TextEditingController(text: '#INV-${oId.replaceAll('ORD-', '')}');
    
    final String dateStr = editableOrder['createdAt'] != null 
        ? DateFormat('MMMM dd, yyyy').format(DateTime.parse(editableOrder['createdAt']))
        : DateFormat('MMMM dd, yyyy').format(DateTime.now());
    _invoiceDateController = TextEditingController(text: dateStr);
    
    _customerNameController = TextEditingController(text: customer['name'] ?? '');
    _customerEmailController = TextEditingController(text: customer['email'] ?? '');
    _customerPhoneController = TextEditingController(text: customer['phone'] ?? '');
    
    _vendorNameController = TextEditingController(text: vendor['storeName'] ?? vendor['name'] ?? 'OJAS Vendor');
    _vendorEmailController = TextEditingController(text: vendor['email'] ?? 'vendor@ojas.com');
    _vendorPhoneController = TextEditingController(text: vendor['phone'] ?? '+91 9876543210');
    
    _taxRateController = TextEditingController(text: '10');
    
    _accNoController = TextEditingController(text: '');
    _accNameController = TextEditingController(text: '');
    _branchController = TextEditingController(text: '');
    
    _term1Controller = TextEditingController(text: '');
    _term2Controller = TextEditingController(text: '');

    final rawItems = editableOrder['items'] as List? ?? [];
    _items = rawItems.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _invoiceNumberController.dispose();
    _invoiceDateController.dispose();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _vendorNameController.dispose();
    _vendorEmailController.dispose();
    _vendorPhoneController.dispose();
    _taxRateController.dispose();
    _accNoController.dispose();
    _accNameController.dispose();
    _branchController.dispose();
    _term1Controller.dispose();
    _term2Controller.dispose();
    super.dispose();
  }

  void _updateEditableOrder() {
    editableOrder['orderId'] = _orderIdController.text;
    editableOrder['invoiceNumber'] = _invoiceNumberController.text;
    editableOrder['invoiceDate'] = _invoiceDateController.text;
    editableOrder['taxRate'] = double.tryParse(_taxRateController.text) ?? 10.0;
    
    editableOrder['user'] = {
      'name': _customerNameController.text,
      'email': _customerEmailController.text,
      'phone': _customerPhoneController.text,
    };
    
    editableOrder['vendor'] = {
      'storeName': _vendorNameController.text,
      'email': _vendorEmailController.text,
      'phone': _vendorPhoneController.text,
    };

    editableOrder['paymentAccNo'] = _accNoController.text;
    editableOrder['paymentAccName'] = _accNameController.text;
    editableOrder['paymentBranch'] = _branchController.text;
    editableOrder['term1'] = _term1Controller.text;
    editableOrder['term2'] = _term2Controller.text;

    editableOrder['items'] = _items;
  }

  Future<void> _generate() async {
    _updateEditableOrder();
    await InvoiceService.generateAndDownloadInvoice(editableOrder);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: _showPreview ? 1000 : 900,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.95),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: _showPreview ? _buildPreview() : _buildEditor(),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    _updateEditableOrder();
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: PdfPreview(
          build: (format) => InvoiceService.generateInvoiceBytes(editableOrder),
          allowPrinting: false,
          allowSharing: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          loadingWidget: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating Preview...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          previewPageMargin: const EdgeInsets.all(20),
          onError: (context, error) => Center(
            child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('Order & Tax Details'),
                const SizedBox(height: 16),
                _buildTextField('Order ID', _orderIdController, icon: Icons.tag),
                const SizedBox(height: 16),
                _buildTextField('Invoice Number', _invoiceNumberController, icon: Icons.receipt),
                const SizedBox(height: 16),
                _buildTextField('Invoice Date', _invoiceDateController, icon: Icons.calendar_today),
                const SizedBox(height: 16),
                _buildTextField('Tax Percentage (%)', _taxRateController, icon: Icons.percent, keyboardType: TextInputType.number),
                
                const SizedBox(height: 32),
                _sectionHeader('Customer Information'),
                const SizedBox(height: 16),
                _buildTextField('Name', _customerNameController, icon: Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField('Email', _customerEmailController, icon: Icons.email_outlined),
                const SizedBox(height: 16),
                _buildTextField('Phone', _customerPhoneController, icon: Icons.phone_outlined),

                const SizedBox(height: 32),
                _sectionHeader('Payment Details'),
                const SizedBox(height: 16),
                _buildTextField('Account No', _accNoController, icon: Icons.account_balance),
                const SizedBox(height: 16),
                _buildTextField('Account Name', _accNameController, icon: Icons.badge_outlined),
                const SizedBox(height: 16),
                _buildTextField('Branch Info', _branchController, icon: Icons.location_on_outlined),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('Product Details'),
                const SizedBox(height: 16),
                _buildItemsList(),
                
                const SizedBox(height: 32),
                _sectionHeader('Vendor Details'),
                const SizedBox(height: 16),
                _buildTextField('Store Name', _vendorNameController, icon: Icons.storefront),
                const SizedBox(height: 16),
                _buildTextField('Store Email', _vendorEmailController, icon: Icons.alternate_email),
                const SizedBox(height: 16),
                _buildTextField('Store Phone', _vendorPhoneController, icon: Icons.call_outlined),

                const SizedBox(height: 32),
                _sectionHeader('Terms & Conditions'),
                const SizedBox(height: 16),
                _buildTextField('Term 1', _term1Controller, icon: Icons.gavel),
                const SizedBox(height: 16),
                _buildTextField('Term 2', _term2Controller, icon: Icons.description_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _showPreview ? 'Invoice Preview' : 'Customize Invoice',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              _showPreview ? 'Review your invoice before finalizing.' : 'Edit products, prices, and payment info before generating PDF.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            if (_showPreview)
              TextButton.icon(
                onPressed: () => setState(() => _showPreview = false),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Back to Edit'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ..._items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final product = item['product'] is Map ? item['product'] : {'name': 'Item'};
            
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: idx == _items.length - 1 ? null : Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'] ?? 'Product', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSmallField(
                          label: 'Price', 
                          initialValue: '${item['price']}',
                          onChanged: (v) => item['price'] = double.tryParse(v) ?? 0.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSmallField(
                          label: 'Qty', 
                          initialValue: '${item['quantity']}',
                          onChanged: (v) => item['quantity'] = int.tryParse(v) ?? 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSmallField({required String label, required String initialValue, required Function(String) onChanged}) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: (v) {
        onChanged(v);
      },
      keyboardType: TextInputType.number,
      style: GoogleFonts.inter(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        isDense: true,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 16),
        if (!_showPreview)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() {
                _updateEditableOrder();
                _showPreview = true;
              }),
              icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
              label: Text('Preview Invoice', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.download, size: 20),
            label: Text(_showPreview ? 'Download PDF' : 'Generate & Download', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade200,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
    
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.0),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 16, color: Colors.grey.shade400) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            filled: true,
            fillColor: Colors.grey.shade50,
            isDense: true,
          ),
        ),
      ],
    );
  }
}
