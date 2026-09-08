import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/services/api_service.dart';
import 'package:ojas_vendor/features/orders/application/order_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class DimensionInput {
  final TextEditingController lengthController;
  final TextEditingController widthController;
  final TextEditingController heightController;

  DimensionInput({String length = '', String width = '', String height = ''})
    : lengthController = TextEditingController(text: length),
      widthController = TextEditingController(text: width),
      heightController = TextEditingController(text: height);

  void dispose() {
    lengthController.dispose();
    widthController.dispose();
    heightController.dispose();
  }
}

class OrderDetailsDialog extends StatefulWidget {
  final dynamic order;
  final OrderController controller;

  const OrderDetailsDialog({
    super.key,
    required this.order,
    required this.controller,
  });

  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _weightController = TextEditingController();
  final _parcelController = TextEditingController(text: "1");
  final List<DimensionInput> _dimensions = [];
  String _weightUnit = 'kg';
  String _dimensionsUnit = 'cm';

  XFile? _selectedImage;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;
  String? _uploadedImageUrl;
  bool _isSubmittingDetails = false;

  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      if (kIsWeb) {
        final response = await Dio().get<List<int>>(
          fileUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = response.data;
        if (bytes != null) {
          final blob = html.Blob([bytes], 'application/pdf');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..style.display = 'none';
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
        }
      } else {
        final url = Uri.parse(fileUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Download error: $e');
      final url = Uri.parse(fileUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }
  bool _isConfirmingDelivery = false;
  bool _isAcceptingOrder = false;

  // Picked up photo
  String? _pickedUpPhotoUrl;
  bool _isUploadingPickedUpPhoto = false;

  // Dispatch photo
  String? _dispatchPhotoUrl;
  bool _isUploadingDispatchPhoto = false;

  // Vendor Invoice
  String? _vendorInvoiceUrl;
  bool _isUploadingInvoice = false;

  // Delhivery Challan
  String? _delhiveryChallanUrl;

  // Countdown timer
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();

    _pickedUpPhotoUrl = widget.order['pickedUpPhoto'];
    _dispatchPhotoUrl = widget.order['dispatchPhoto'];
    _vendorInvoiceUrl = widget.order['vendorInvoiceUrl'];
    _delhiveryChallanUrl = widget.order['delhiveryChallanUrl'];

    // Prefill form if details exist
    if (widget.order['pickupDetails'] != null) {
      final pd = widget.order['pickupDetails'];
      _weightController.text = (pd['weight'] ?? '').toString();
      _parcelController.text = (pd['numberOfParcels'] ?? '1').toString();
      _uploadedImageUrl = widget.order['shippingPhoto'];

      final List? dList = pd['dimensionsList'];
      if (dList != null && dList.isNotEmpty) {
        for (var d in dList) {
          _dimensions.add(
            DimensionInput(
              length: (d['length'] ?? '').toString(),
              width: (d['width'] ?? '').toString(),
              height: (d['height'] ?? '').toString(),
            ),
          );
        }
      } else {
        // Fallback to legacy single dimension
        final dim = pd['dimensions'] ?? {};
        _dimensions.add(
          DimensionInput(
            length: (dim['length'] ?? '').toString(),
            width: (dim['width'] ?? '').toString(),
            height: (dim['height'] ?? '').toString(),
          ),
        );
      }
    } else {
      _dimensions.add(DimensionInput());
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _weightController.dispose();
    _parcelController.dispose();
    for (var d in _dimensions) {
      d.dispose();
    }
    super.dispose();
  }

  void _calculateRemainingTime() {
    if (widget.order['confirmationExpiryTime'] != null) {
      final expiry = DateTime.parse(
        widget.order['confirmationExpiryTime'].toString(),
      );
      final now = DateTime.now();
      if (expiry.isAfter(now)) {
        setState(() {
          _remainingTime = expiry.difference(now);
        });
      } else {
        setState(() {
          _remainingTime = Duration.zero;
        });
      }
    }
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative || duration == Duration.zero)
      return "Expired / Escalate";

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    return "${days}d ${hours}h ${minutes}m ${seconds}s";
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = image;
        _isUploadingImage = true;
        _uploadProgress = 0.1;
      });

      Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (_uploadProgress < 0.8) {
          setState(() {
            _uploadProgress += 0.1;
          });
        } else {
          t.cancel();
        }
      });

      final bytes = await image.readAsBytes();
      FormData formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: image.name),
      });

      final response = await ApiService().dio.post(
        '/upload/image',
        data: formData,
      );

      setState(() {
        _uploadProgress = 1.0;
      });

      if (response.data['success']) {
        setState(() {
          _uploadedImageUrl = response.data['url'];
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipping photo uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw response.data['message'] ?? 'Upload failed';
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload shipping photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickPickedUpPhoto(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() {
        _isUploadingPickedUpPhoto = true;
      });

      final bytes = await image.readAsBytes();
      FormData formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: image.name),
      });

      final response = await ApiService().dio.post(
        '/upload/image',
        data: formData,
      );

      if (response.data['success']) {
        final url = response.data['url'];
        final success = await widget.controller.submitPickedUpPhoto(
          widget.order['_id'],
          url,
        );
        if (success) {
          setState(() {
            _pickedUpPhotoUrl = url;
            _isUploadingPickedUpPhoto = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Picked Up photo verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw 'Failed to update order record';
        }
      } else {
        throw response.data['message'] ?? 'Upload failed';
      }
    } catch (e) {
      setState(() {
        _isUploadingPickedUpPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit Picked Up Photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickDispatchPhoto(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() {
        _isUploadingDispatchPhoto = true;
      });

      final bytes = await image.readAsBytes();
      FormData formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: image.name),
      });

      final response = await ApiService().dio.post(
        '/upload/image',
        data: formData,
      );

      if (response.data['success']) {
        final url = response.data['url'];
        final success = await widget.controller.submitDispatchPhoto(
          widget.order['_id'],
          url,
        );
        if (success) {
          setState(() {
            _dispatchPhotoUrl = url;
            _isUploadingDispatchPhoto = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dispatch parcel photo uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw 'Failed to update order record';
        }
      } else {
        throw response.data['message'] ?? 'Upload failed';
      }
    } catch (e) {
      setState(() {
        _isUploadingDispatchPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit Dispatch Photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadInvoice() async {
    // Commented out: previous ImagePicker flow
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(
    //   source: ImageSource.gallery,
    //   imageQuality: 85,
    // );
    // if (image != null) {
    //   setState(() => _isUploadingInvoice = true);
    //   try {
    //     final bytes = await image.readAsBytes();
    //     final fileName = image.name;
    //     final formData = FormData.fromMap({
    //       'image': MultipartFile.fromBytes(bytes, filename: fileName),
    //     });
    //     final response = await ApiService().dio.post(
    //       '/upload/image',
    //       data: formData,
    //     );
    //     if (response.data['success'] == true) {
    //       final url = response.data['url'];
    //       await ApiService().dio.put(
    //         '/order/vendor-invoice',
    //         data: {'orderId': widget.order['_id'], 'invoiceUrl': url},
    //       );
    //       setState(() {
    //         _vendorInvoiceUrl = url;
    //         _isUploadingInvoice = false;
    //       });
    //       if (mounted) {
    //         ScaffoldMessenger.of(context).showSnackBar(
    //           const SnackBar(
    //             content: Text('Tax Invoice uploaded successfully!'),
    //             backgroundColor: Colors.green,
    //           ),
    //         );
    //       }
    //     }
    //   } catch (e) {
    //     setState(() => _isUploadingInvoice = false);
    //     if (mounted) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(
    //           content: Text('Failed to upload invoice: $e'),
    //           backgroundColor: Colors.red,
    //         ),
    //       );
    //     }
    //   }
    // }

    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() => _isUploadingInvoice = true);
      try {
        final bytes = result.files.single.bytes!;
        final fileName = result.files.single.name;
        final isPdf = fileName.toLowerCase().endsWith('.pdf');
        
        final formData = FormData.fromMap({
          isPdf ? 'pdf' : 'image': MultipartFile.fromBytes(bytes, filename: fileName),
        });
        
        final response = await ApiService().dio.post(
          isPdf ? '/upload/pdf' : '/upload/image',
          data: formData,
        );
        if (response.data['success'] == true) {
          final url = response.data['url'];
          await ApiService().dio.put(
            '/order/vendor-invoice',
            data: {'orderId': widget.order['_id'], 'invoiceUrl': url},
          );
          setState(() {
            _vendorInvoiceUrl = url;
            _isUploadingInvoice = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tax Invoice uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isUploadingInvoice = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload invoice: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _submitPickup() async {
    if (_formKey.currentState!.validate()) {
      final double weightVal = double.tryParse(_weightController.text.trim()) ?? 0;
      final double finalWeight = _weightUnit == 'g' ? weightVal / 1000 : weightVal;

      if (finalWeight <= 0 || finalWeight > 25) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _weightUnit == 'g'
                  ? 'Parcel weight must be greater than 0 and cannot exceed 25000 g'
                  : 'Parcel weight must be greater than 0 and cannot exceed 25 kg',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_uploadedImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a shipping/package photo first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isSubmittingDetails = true;
      });

      final dimsData = _dimensions
          .map(
            (d) {
              final double length = double.tryParse(d.lengthController.text.trim()) ?? 0;
              final double width = double.tryParse(d.widthController.text.trim()) ?? 0;
              final double height = double.tryParse(d.heightController.text.trim()) ?? 0;

              final double finalLength = _dimensionsUnit == 'in' ? length * 2.54 : length;
              final double finalWidth = _dimensionsUnit == 'in' ? width * 2.54 : width;
              final double finalHeight = _dimensionsUnit == 'in' ? height * 2.54 : height;

              return {
                'length': finalLength.toStringAsFixed(2),
                'width': finalWidth.toStringAsFixed(2),
                'height': finalHeight.toStringAsFixed(2),
              };
            },
          )
          .toList();

      final success = await widget.controller
          .submitPickupDetails(widget.order['_id'], {
            'weight': finalWeight.toStringAsFixed(3),
            'weightUnit': _weightUnit,
            'dimensionsUnit': _dimensionsUnit,
            'numberOfParcels': _parcelController.text.trim(),
            'shippingPhoto': _uploadedImageUrl,
            'dimensionsList': dimsData,
          });

      setState(() {
        _isSubmittingDetails = false;
      });

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup details submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit pickup details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptOrder() async {
    setState(() {
      _isAcceptingOrder = true;
    });

    final success = await widget.controller.updateOrderStatus(
      widget.order['_id'],
      'PROCESSING',
    );

    setState(() {
      _isAcceptingOrder = false;
    });

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept order.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelivery() async {
    setState(() {
      _isConfirmingDelivery = true;
    });

    final success = await widget.controller.confirmDelivery(
      widget.order['_id'],
    );

    setState(() {
      _isConfirmingDelivery = false;
    });

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery confirmed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to confirm delivery.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['status'] ?? 'Pending';
    final confirmed = widget.order['deliveryConfirmedByVendor'] ?? false;
    final isEscalated = widget.order['isEscalated'] ?? false;
    final pickupStatus = widget.order['pickupStatus'] ?? 'Pending';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 850,
        height: 720,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // Premium Dialog Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details: ${widget.order['orderId']}',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Created on: ${widget.order['createdAt'] != null ? DateTime.parse(widget.order['createdAt']).toString().split(' ')[0] : '-'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isUploadingInvoice ? null : _uploadInvoice,
                    icon: _isUploadingInvoice
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _vendorInvoiceUrl != null
                                ? Icons.check_circle
                                : Icons.upload_file,
                            size: 16,
                          ),
                    label: Text(
                      _vendorInvoiceUrl != null
                          ? 'Invoice Uploaded ✓'
                          : 'Upload Invoice',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _vendorInvoiceUrl != null
                          ? Colors.green.shade700
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                   if (_delhiveryChallanUrl != null && _delhiveryChallanUrl!.isNotEmpty) ...[
                    ..._delhiveryChallanUrl!.split(',').asMap().entries.map((entry) {
                      final index = entry.key;
                      final singleUrl = entry.value.trim();
                      final challanList = _delhiveryChallanUrl!.split(',');
                      final label = challanList.length == 1 ? 'Delhivery Challan' : 'Challan ${index + 1}';
                      return Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final fileName = challanList.length == 1
                                ? 'challan_${widget.order['orderId']}.pdf'
                                : 'challan_${widget.order['orderId']}_${index + 1}.pdf';
                            await _downloadFile(singleUrl, fileName);
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: Text(label),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],

                  // const SizedBox(width: 12),
                  // OutlinedButton.icon(
                  //   onPressed: () => DeliveryChallanHelper.generateAndDownload(
                  //     context,
                  //     Map<String, dynamic>.from(widget.order),
                  //   ),
                  //   icon: const Icon(Icons.receipt_long, size: 16),
                  //   label: const Text('Download Challan'),
                  //   style: OutlinedButton.styleFrom(
                  //     foregroundColor: AppColors.textPrimary,
                  //     side: BorderSide(color: AppColors.info),
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 16,
                  //       vertical: 12,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //   ),
                  // ),
                  
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            Expanded(
              child: Row(
                children: [
                  // Left Column: Order items, summary, timeline
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom Order Timeline Progress
                          _buildTimeline(status, isEscalated),
                          const SizedBox(height: 24),

                          // Delivery Confirmation Banner
                          if (status == "DELIVERED") ...[
                            _buildDeliveryConfirmationSection(
                              confirmed,
                              isEscalated,
                            ),
                            const SizedBox(height: 24),
                          ] else if (status == "ESCALATED") ...[
                            _buildEscalatedSection(),
                            const SizedBox(height: 24),
                          ],

                          // Dispatch/Send Photo Upload Section
                          if (status == "READY_TO_DISPATCH" ||
                              status == "SHIPPED" ||
                              status == "PROCESSING" ||
                              status == "OUT_FOR_DELIVERY") ...[
                            // _buildDispatchPhotoSection(),
                            // const SizedBox(height: 24),
                          ],

                          // Products Card
                          Text(
                            'Order Items',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  (widget.order['items'] as List? ?? []).length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: Color(0xFFE2E8F0),
                              ),
                              itemBuilder: (context, index) {
                                final item = widget.order['items'][index];
                                return ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      item['image'] ??
                                          'https://via.placeholder.com/50',
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade200,
                                        width: 44,
                                        height: 44,
                                        child: const Icon(
                                          Icons.shopping_bag,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    item['name'] ?? 'Product name',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Builder(
                                    builder: (context) {
                                      final prod = item['product'];
                                      final varObj = item['variation'];
                                      String sku = '-';
                                      if (varObj is Map &&
                                          varObj['sku'] != null &&
                                          varObj['sku']
                                              .toString()
                                              .trim()
                                              .isNotEmpty) {
                                        sku = varObj['sku'].toString();
                                      } else if (prod is Map &&
                                          prod['sku'] != null &&
                                          prod['sku']
                                              .toString()
                                              .trim()
                                              .isNotEmpty) {
                                        sku = prod['sku'].toString();
                                      }
                                      return Text(
                                        'Qty: ${item['quantity']} • SKU: $sku',
                                        style: GoogleFonts.inter(fontSize: 12),
                                      );
                                    },
                                  ),
                                  trailing: Text(
                                    '₹${((item['sellingPrice'] ?? item['price'] ?? 0) * (item['quantity'] ?? 1))}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Customer details card
                          Text(
                            'Delivery Address',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text(widget.order['user'] != null ? widget.order['user']['name'] : 'Guest Customer', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                                // const SizedBox(height: 6),
                                // Text(widget.order['user'] != null ? widget.order['user']['email'] : '-', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                // Text(widget.order['user'] != null ? widget.order['user']['mobile'] : '-', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                // const SizedBox(height: 8),
                                // const Divider(height: 1),
                                // const SizedBox(height: 8),
                                Text(
                                  [
                                            widget
                                                .order['shippingAddress']?['buildingName'],
                                            widget
                                                .order['shippingAddress']?['street'],
                                            widget
                                                .order['shippingAddress']?['area'],
                                            widget
                                                .order['shippingAddress']?['landmark'],
                                            widget
                                                .order['shippingAddress']?['city'],
                                            widget
                                                .order['shippingAddress']?['state'],
                                          ]
                                          .where(
                                            (e) =>
                                                e != null &&
                                                e.toString().trim().isNotEmpty,
                                          )
                                          .toSet()
                                          .join(', ') +
                                      (widget.order['shippingAddress']?['zipCode'] !=
                                                  null &&
                                              widget
                                                  .order['shippingAddress']!['zipCode']
                                                  .toString()
                                                  .isNotEmpty
                                          ? ' - ${widget.order['shippingAddress']?['zipCode']}'
                                          : ''),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

                  // Right Column: Pickup Details submission or Order Acceptance
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (status == "CREATED" || status == "PAID") ...[
                            Text(
                              'Order Action',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.deepPurple.shade100,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.new_releases_outlined,
                                    size: 48,
                                    color: Colors.deepPurple.shade700,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Accept This Order',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Please accept this order to acknowledge receipt and start package fulfillment/pickup processes.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.deepPurple.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: _isAcceptingOrder
                                          ? null
                                          : _acceptOrder,
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                        size: 18,
                                      ),
                                      label: _isAcceptingOrder
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Accept Order',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Pickup Details Title
                            Row(
                              children: [
                                Text(
                                  'Manual Pickup Details',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildPickupStatusBadge(pickupStatus),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (pickupStatus != 'Pending' &&
                                pickupStatus != 'Pickup Requested') ...[
                              // Display Submitted details securely
                              _buildSubmittedPickupCard(pickupStatus),
                            ] else ...[
                              // Fill Form to submit details
                              _buildPickupDetailsForm(),
                            ],
                          ],
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

  Widget _buildTimeline(String status, bool isEscalated) {
    final stages = [
      widget.order['paymentMethod'] == 'COD' ? 'Placed' : 'Paid',
      'Processing',
      'Shipped',
      'Delivered',
    ];
    int currentStage = 0;
    if (status == 'PROCESSING') currentStage = 1;
    if (status == 'SHIPPED') currentStage = 2;
    if (status == 'DELIVERED') currentStage = 3;
    if (isEscalated) currentStage = 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Status Timeline',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(stages.length * 2 - 1, (index) {
            if (index.isOdd) {
              final isPassed = (index ~/ 2) < currentStage;
              return Expanded(
                child: Container(
                  height: 3,
                  color: isPassed ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              );
            } else {
              final stageIndex = index ~/ 2;
              final isPassed = stageIndex <= currentStage;
              final label = stages[stageIndex];
              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isPassed ? AppColors.primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPassed
                            ? AppColors.primary
                            : const Color(0xFFCBD5E1),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isPassed
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              '${stageIndex + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: isPassed
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isPassed
                          ? AppColors.primary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              );
            }
          }),
        ),
      ],
    );
  }

  Widget _buildDeliveryConfirmationSection(bool confirmed, bool isEscalated) {
    if (confirmed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Confirmed',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.green.shade900,
                    ),
                  ),
                  Text(
                    'You have successfully confirmed delivery of this order.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isEscalated) {
      return _buildEscalatedSection();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.orange, size: 22),
              const SizedBox(width: 8),
              Text(
                'Mandatory Delivery Confirmation',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: const Color(0xFF7C2D12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'After delivery, you have exactly 2 days to confirm. Failure to confirm will result in automatic admin escalation.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF9A3412),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time Remaining:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7C2D12),
                  ),
                ),
                Text(
                  _formatDuration(_remainingTime),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: _isConfirmingDelivery ? null : _confirmDelivery,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: _isConfirmingDelivery
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Confirm Delivery Now',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalatedSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Delivery Escalated to Admin',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The 2-day delivery confirmation window has expired. This order has been automatically escalated to Master Admin for inspection.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchPhotoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF4F46E5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Parcel Dispatch Photo Verification',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.indigo.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_dispatchPhotoUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _dispatchPhotoUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ] else if (_isUploadingDispatchPhoto) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            ),
          ] else ...[
            Text(
              'Upload a photo of the parcel as you send/dispatch it to verify shipment contents.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.indigo.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library, size: 14),
                    label: const Text(
                      'Upload Photo',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _pickDispatchPhoto(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt, size: 14),
                    label: const Text(
                      'Take Pic',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _pickDispatchPhoto(ImageSource.camera),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPickupStatusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade700;

    if (status == 'Pickup Requested') {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF1D4ED8);
    } else if (status == 'Pickup Scheduled') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else if (status == 'Picked Up') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF047857);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildSubmittedPickupCard(String pickupStatus) {
    final pd = widget.order['pickupDetails'] ?? {};
    final dimensions = pd['dimensions'] ?? {};

    String scheduledDateStr = '-';
    if (widget.order['pickupScheduledAt'] != null) {
      scheduledDateStr = DateTime.parse(
        widget.order['pickupScheduledAt'].toString(),
      ).toLocal().toString().split('.')[0];
    }

    String scheduledDateTimeChoice = '-';
    if (widget.order['pickupScheduleDate'] != null) {
      scheduledDateTimeChoice = DateTime.parse(
        widget.order['pickupScheduleDate'].toString(),
      ).toLocal().toString().split('.')[0];
    }

    String pickedUpDateStr = '-';
    if (widget.order['pickedUpAt'] != null) {
      pickedUpDateStr = DateTime.parse(
        widget.order['pickedUpAt'].toString(),
      ).toLocal().toString().split('.')[0];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pickup request is arranged!',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Total Weight', '${pd['weight'] ?? 0} kg'),
          _buildDetailRow('No. of Parcels', '${pd['numberOfParcels'] ?? 1}'),
          if (pd['dimensionsList'] != null &&
              (pd['dimensionsList'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Dimensions list:',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            ...(pd['dimensionsList'] as List).asMap().entries.map((entry) {
              final idx = entry.key;
              final d = entry.value;
              return Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  'Size #${idx + 1}: ${d['length']}x${d['width']}x${d['height']} cm',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ] else ...[
            _buildDetailRow(
              'Dimensions (L x W x H)',
              '${dimensions['length'] ?? 0} x ${dimensions['width'] ?? 0} x ${dimensions['height'] ?? 0} cm',
            ),
          ],
          const SizedBox(height: 6),
          if (widget.order['pickupScheduleDate'] != null) ...[
            const SizedBox(height: 6),
            _buildDetailRow(
              'Scheduled Pickup Date/Time',
              scheduledDateTimeChoice,
            ),
          ] else if (widget.order['pickupScheduledAt'] != null) ...[
            const SizedBox(height: 6),
            _buildDetailRow('Pickup Scheduled Date', scheduledDateStr),
          ],
          if (widget.order['pickedUpAt'] != null) ...[
            const SizedBox(height: 6),
            _buildDetailRow('Picked Up Date', pickedUpDateStr),
          ],

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Mandatory Shipping Photo:',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (widget.order['shippingPhoto'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.order['shippingPhoto'],
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          if (pickupStatus == 'Picked Up') ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Verification Picked Up Photo *',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.deepPurple.shade900,
              ),
            ),
            const SizedBox(height: 8),
            if (_pickedUpPhotoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _pickedUpPhotoUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ] else if (_isUploadingPickedUpPhoto) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else ...[
              Text(
                'Upload picked up verification photo to complete pickup sequence.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library, size: 14),
                      label: const Text(
                        'From Gallery',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _pickPickedUpPhoto(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt, size: 14),
                      label: const Text(
                        'Use Camera',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _pickPickedUpPhoto(ImageSource.camera),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDetailsForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please input parcel specifications to request manual pickup from admin.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parcel Weight *', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: _weightUnit == 'kg' ? 'e.g. 1.5' : 'e.g. 1500',
                              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final val = double.tryParse(v);
                              if (val == null || val <= 0) return 'Must be > 0';
                              final weightInKg = _weightUnit == 'g' ? val / 1000 : val;
                              if (weightInKg > 25) return 'Max 25 kg';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: DropdownButton<String>(
                            value: _weightUnit,
                            underline: const SizedBox(),
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            items: ['kg', 'g'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _weightUnit = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Number of Parcels *', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _parcelController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'e.g. 1',
                              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final val = int.tryParse(v);
                              if (val == null || val < 1) return 'Must be >= 1';
                              return null;
                            },
                          ),
                        ),
                        // const SizedBox(width: 8),
                        // Container(
                        //   padding: const EdgeInsets.symmetric(horizontal: 8),
                        //   decoration: BoxDecoration(
                        //     border: Border.all(color: Colors.grey.shade300),
                        //     borderRadius: BorderRadius.circular(6),
                        //   ),
                        //   child: DropdownButton<String>(
                        //     value: _dimensionsUnit,
                        //     underline: const SizedBox(),
                        //     style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                        //     items: ['cm', 'in'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        //     onChanged: (val) {
                        //       if (val != null) {
                        //         setState(() {
                        //           _dimensionsUnit = val;
                        //         });
                        //       }
                        //     },
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ...List.generate(_dimensions.length, (index) {
            final dim = _dimensions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dimension Set #${index + 1} (L x W x H in $_dimensionsUnit) *',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade900,
                        ),
                      ),
                      if (_dimensions.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _dimensions.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: 'Length',
                          hint: _dimensionsUnit,
                          controller: dim.lengthController,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            final val = double.tryParse(v);
                            if (val == null || val <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: 'Width',
                          hint: _dimensionsUnit,
                          controller: dim.widthController,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            final val = double.tryParse(v);
                            if (val == null || val <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: 'Height',
                          hint: _dimensionsUnit,
                          controller: dim.heightController,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            final val = double.tryParse(v);
                            if (val == null || val <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          if (_dimensions.length < 10) ...[
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _dimensions.add(DimensionInput());
                  });
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Another Dimension Set'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          Text(
            'Mandatory Shipping Photo *',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_uploadedImageUrl != null) ...[
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            _uploadedImageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _uploadedImageUrl = null),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_isUploadingImage) ...[
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Uploading Shipping Photo: ${(_uploadProgress * 100).toInt()}%',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ] else ...[
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 36,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Camera or gallery upload required',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: const Text('Gallery'),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Camera'),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_uploadedImageUrl == null || _isSubmittingDetails)
                  ? null
                  : _submitPickup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isSubmittingDetails
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Request Pickup From Admin',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}
