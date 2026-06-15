import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_admin/features/orders/application/order_controller.dart';
import 'package:ojas_admin/core/services/api_service.dart';
import 'package:ojas_admin/core/utils/delivery_challan_helper.dart';

class AdminOrderDetailsDialog extends StatefulWidget {
  final dynamic order;
  final OrderController controller;

  const AdminOrderDetailsDialog({
    super.key,
    required this.order,
    required this.controller,
  });

  @override
  State<AdminOrderDetailsDialog> createState() => _AdminOrderDetailsDialogState();
}

class _AdminOrderDetailsDialogState extends State<AdminOrderDetailsDialog> {
  String _selectedPickupStatus = 'Pending';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedPickupStatus = widget.order['pickupStatus'] ?? 'Pending';
  }

  Future<void> _updatePickupStatus(String newStatus, {DateTime? scheduleDate}) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await ApiService().dio.put('/order/pickup-status', data: {
        'orderId': widget.order['_id'],
        'pickupStatus': newStatus,
        if (scheduleDate != null) 'pickupScheduleDate': scheduleDate.toUtc().toIso8601String(),
      });

      if (response.data['success']) {
        setState(() {
          _selectedPickupStatus = newStatus;
        });
        await widget.controller.fetchAllOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pickup status updated to $newStatus successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        throw response.data['message'] ?? 'Failed to update';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating pickup status: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['status'] ?? 'Pending';
    final isEscalated = widget.order['isEscalated'] ?? false;
    final pd = widget.order['pickupDetails'];
    final dimensions = pd != null ? pd['dimensions'] : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 24,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 900,
        height: 720,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Gorgeous Premium Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade500.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade400.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Color(0xFF818CF8), size: 24),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Admin Order Inspection',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
                              ),
                              child: Text(
                                widget.order['orderId'] ?? 'ID',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFC7D2FE),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fulfillment Vendor: ${widget.order['vendor'] != null ? (widget.order['vendor']['storeName'] ?? widget.order['vendor']['name']) : "Master Admin"}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => DeliveryChallanHelper.generateAndDownload(context, Map<String, dynamic>.from(widget.order)),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download Challan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white60),
                    hoverColor: Colors.white10,
                  ),
                ],
              ),
            ),

            // Dialog Main Body
            Expanded(
              child: Row(
                children: [
                  // Left Side: Order details, Escalations & Customer Details
                  Expanded(
                    flex: 4,
                    child: Container(
                      color: const Color(0xFFF8FAFC),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isEscalated) ...[
                              _buildEscalationBanner(),
                              const SizedBox(height: 24),
                            ],

                            // Customer Card
                            Text(
                              'Customer & Shipping Address',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildCustomerCard(),
                            const SizedBox(height: 24),
                            Text(
                              'Order Items',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildOrderItemsSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

                  // Right Side: Vendor Pickup details, image, & dropdown status updates
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Vendor Specs & Photo',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              _buildStatusTag(_selectedPickupStatus),
                            ],
                          ),
                          const SizedBox(height: 20),

                          if (pd == null) ...[
                            _buildEmptyPickupState()
                          ] else ...[
                            // Pickup Details Card
                            _buildPickupDetailsCard(pd, dimensions),
                            const SizedBox(height: 24),

                            // Image Verification Card
                            Text(
                              'Verification Photos',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildImageVerification(widget.order['shippingPhoto'], "Package Shipping Photo"),
                                    ),
                                    if (widget.order['dispatchPhoto'] != null) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildImageVerification(widget.order['dispatchPhoto'], "Parcel Sent Verification"),
                                      ),
                                    ],
                                    if (widget.order['pickedUpPhoto'] != null) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildImageVerification(widget.order['pickedUpPhoto'], "Picked Up Proof"),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            const Divider(color: Color(0xFFE2E8F0)),
                            const SizedBox(height: 20),

                            // Manual Pickup Coordination
                            Text(
                              'Arrange Pickup (Status Update)',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildStatusUpdater(),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscalationBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'DELIVERY WINDOW EXPIRED',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: const Color(0xFF991B1B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'This order was automatically escalated due to vendor non-confirmation within the 2-day delivery confirmation window.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.4,
              color: const Color(0xFF7F1D1D),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: Column(
              children: [
                _buildEscalationTimeRow('Delivered At', widget.order['deliveredAt']),
                const SizedBox(height: 6),
                _buildEscalationTimeRow('Escalated At', widget.order['escalatedAt']),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEscalationTimeRow(String label, dynamic value) {
    String dateStr = '-';
    if (value != null) {
      dateStr = DateTime.parse(value.toString()).toLocal().toString().split('.')[0];
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF991B1B))),
        Text(dateStr, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF7F1D1D))),
      ],
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                child: Text(
                  widget.order['user'] != null ? widget.order['user']['name'].substring(0, 1).toUpperCase() : 'G',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order['user'] != null ? widget.order['user']['name'] : 'Guest Customer',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.order['user'] != null ? widget.order['user']['email'] : '-',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 10),
              Text(
                widget.order['user'] != null ? widget.order['user']['mobile'] : '-',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(Icons.location_on, size: 16, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.order['shippingAddress']?['street'] ?? ""}, ${widget.order['shippingAddress']?['city'] ?? ""}, ${widget.order['shippingAddress']?['state'] ?? ""} - ${widget.order['shippingAddress']?['zipCode'] ?? ""}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);

    if (status == 'Pickup Requested') {
      bg = const Color(0xFFEEF2FF);
      fg = const Color(0xFF4F46E5);
    } else if (status == 'Pickup Scheduled') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else if (status == 'Picked Up') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPickupState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'Specs Pending',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            'The vendor has not submitted parcel details for pickup yet.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDetailsCard(dynamic pd, dynamic dimensions) {
    String scheduledDateStr = '-';
    if (widget.order['pickupScheduledAt'] != null) {
      scheduledDateStr = DateTime.parse(widget.order['pickupScheduledAt'].toString()).toLocal().toString().split('.')[0];
    }

    String choiceDateStr = '-';
    if (widget.order['pickupScheduleDate'] != null) {
      choiceDateStr = DateTime.parse(widget.order['pickupScheduleDate'].toString()).toLocal().toString().split('.')[0];
    }

    String pickedUpDateStr = '-';
    if (widget.order['pickedUpAt'] != null) {
      pickedUpDateStr = DateTime.parse(widget.order['pickedUpAt'].toString()).toLocal().toString().split('.')[0];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _buildSpecsRow('Parcel Weight', '${pd['weight'] ?? 0} kg', Icons.scale_outlined),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          _buildSpecsRow('Number of Parcels', '${pd['numberOfParcels'] ?? 1}', Icons.inventory_2_outlined),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          _buildSpecsRow(
            'Dimensions (L x W x H)',
            '${dimensions != null ? dimensions['length'] : 0} × ${dimensions != null ? dimensions['width'] : 0} × ${dimensions != null ? dimensions['height'] : 0} cm',
            Icons.square_foot_outlined,
          ),
          if (widget.order['pickupScheduleDate'] != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            _buildSpecsRow('Manual Scheduled Date/Time', choiceDateStr, Icons.calendar_month_outlined),
          ] else if (widget.order['pickupScheduledAt'] != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            _buildSpecsRow('Pickup Scheduled At', scheduledDateStr, Icons.calendar_today_outlined),
          ],
          if (widget.order['pickedUpAt'] != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            _buildSpecsRow('Picked Up At', pickedUpDateStr, Icons.task_alt_outlined),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecsRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF475569)),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildImageVerification(String? photoUrl, String label) {
    if (photoUrl == null) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported_outlined, size: 28, color: Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text(
              'No photo',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              photoUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 12),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusUpdater() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPickupStatus,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF475569)),
                  isExpanded: true,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                  items: ['Pending', 'Pickup Requested', 'Pickup Scheduled', 'Picked Up']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: _isUpdating
                      ? null
                      : (val) async {
                          if (val != null) {
                            if (val == "Pickup Scheduled") {
                              final DateTime? date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 60)),
                              );
                              if (date == null) return;
                              
                              final TimeOfDay? time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time == null) return;
                              
                              final selectedDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                              
                              _updatePickupStatus(val, scheduleDate: selectedDateTime);
                            } else {
                              _updatePickupStatus(val);
                            }
                          }
                        },
                ),
              ),
            ),
          ),
          if (_isUpdating) ...[
            const SizedBox(width: 14),
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6366F1),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    final items = List<dynamic>.from(widget.order['items'] ?? []);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    item['image'] ?? 'https://via.placeholder.com/50',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.shopping_bag, color: Colors.grey),
                    ),
                  ),
                ),
                title: Text(item['name'] ?? 'Product', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text('Qty: ${item['quantity']}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Text('₹${item['finalPrice'] ?? (item['price'] * item['quantity'])}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                    Text('₹${widget.order['subtotal'] ?? 0}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Tax (GST)', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                    Text('₹${widget.order['totalGst'] ?? 0}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Grand Total', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('₹${widget.order['totalAmount'] ?? 0}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
