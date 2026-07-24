import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/features/auth/application/address_controller.dart';
import 'package:ojas_user/features/auth/domain/models/address_model.dart';

class AddressFormDialog extends StatefulWidget {
  final AddressModel? address;
  const AddressFormDialog({super.key, this.address});

  @override
  State<AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<AddressFormDialog> {
  late TextEditingController nameController;
  late TextEditingController mobileController;
  late TextEditingController buildingController;
  late TextEditingController streetController;
  late TextEditingController areaController;
  late TextEditingController landmarkController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController zipController;
  late TextEditingController gstController;
  late TextEditingController panController;
  bool _isFetchingPincode = false;
  String? _errorMessage;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.address?.name);
    mobileController = TextEditingController(text: widget.address?.mobile);
    
    // Parse individual or combined street fields (for backward compatibility)
    final hasNewFields = widget.address?.buildingName != null || widget.address?.area != null;
    String buildingVal = '';
    String streetVal = '';
    String areaVal = '';
    String landmarkVal = '';

    if (widget.address != null) {
      if (hasNewFields) {
        buildingVal = widget.address!.buildingName ?? '';
        streetVal = widget.address!.street;
        areaVal = widget.address!.area ?? '';
        landmarkVal = widget.address!.landmark ?? '';
      } else {
        final streetParts = (widget.address?.street ?? '').split(', ');
        buildingVal = streetParts.isNotEmpty ? streetParts[0] : '';
        streetVal = streetParts.length > 1 ? streetParts[1] : '';
        areaVal = streetParts.length > 2 ? streetParts[2] : '';
        landmarkVal = streetParts.length > 3 ? streetParts.sublist(3).join(', ') : '';
      }
    }

    buildingController = TextEditingController(text: buildingVal);
    streetController = TextEditingController(text: streetVal);
    areaController = TextEditingController(text: areaVal);
    landmarkController = TextEditingController(text: landmarkVal);

    cityController = TextEditingController(text: widget.address?.city);
    stateController = TextEditingController(text: widget.address?.state);
    zipController = TextEditingController(text: widget.address?.zipCode);
    gstController = TextEditingController(text: widget.address?.gstNumber);
    panController = TextEditingController(text: widget.address?.panNumber);
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    buildingController.dispose();
    streetController.dispose();
    areaController.dispose();
    landmarkController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipController.dispose();
    gstController.dispose();
    panController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCityAndState(String pincode) async {
    if (pincode.length != 6) return;

    setState(() {
      _isFetchingPincode = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/home/pincode/$pincode'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data[0]['Status'] == 'Success') {
          final postOffice = data[0]['PostOffice'][0];

          setState(() {
            cityController.text = postOffice['District'] ?? '';
            stateController.text = postOffice['State'] ?? '';
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid Pincode. Enter city & state manually.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch pincode details. Enter manually.';
        });
      }
    } catch (e) {
      debugPrint('Pincode fetch error: $e');
      setState(() {
        _errorMessage = 'Network or CORS issue. Please enter city & state manually.';
      });
    } finally {
      setState(() {
        _isFetchingPincode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.address == null ? 'Add New Address' : 'Edit Address',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide accurate delivery information',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    _buildModernField(
                      nameController,
                      'Full Name',
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildModernField(
                      mobileController,
                      'Mobile Number',
                      Icons.phone_android_outlined,
                      isPhone: true,
                    ),
                    const SizedBox(height: 16),
                    _buildModernField(
                      buildingController,
                      'Building Name',
                      Icons.business_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildModernField(
                      streetController,
                      'Street / Road Name',
                      Icons.add_road_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildModernField(
                      areaController,
                      'Area / Locality',
                      Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildModernField(
                      landmarkController,
                      'Landmark',
                      Icons.assistant_navigation,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernField(
                            cityController,
                            'City',
                            Icons.location_city_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernField(
                            stateController,
                            'State',
                            Icons.map_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildModernField(
                      zipController,
                      'Pincode',
                      Icons.pin_drop_outlined,
                      isPincode: true,
                      suffix: _isFetchingPincode
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryPink,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildModernField(
                      gstController,
                      'GST Number (Optional)',
                      Icons.business_outlined,
                      helperText: 'Add GST details for business purchases and tax invoices.',
                    ),
                    const SizedBox(height: 16),
                    _buildModernField(
                      panController,
                      'PAN Number (Optional)',
                      Icons.credit_card_outlined,
                      helperText: 'Enter 10-digit PAN details for validation.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                    color: AppColors.errorRed[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.grey[200]!),
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final mobile = mobileController.text.trim();
                      final building = buildingController.text.trim();
                      final street = streetController.text.trim();
                      final area = areaController.text.trim();
                      final landmark = landmarkController.text.trim();
                      final city = cityController.text.trim();
                      final state = stateController.text.trim();
                      final zip = zipController.text.trim();
                      final gst = gstController.text.trim().toUpperCase();
                      final pan = panController.text.trim().toUpperCase();

                      if (name.isEmpty) {
                        setState(() => _errorMessage = 'Please enter your full name');
                        return;
                      }
                      if (mobile.isEmpty || mobile.length < 10) {
                        setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number');
                        return;
                      }
                      if (building.isEmpty) {
                        setState(() => _errorMessage = 'Please enter building name');
                        return;
                      }
                      if (street.isEmpty) {
                        setState(() => _errorMessage = 'Please enter street / road name');
                        return;
                      }
                      if (area.isEmpty) {
                        setState(() => _errorMessage = 'Please enter area / locality');
                        return;
                      }
                      if (city.isEmpty) {
                        setState(() => _errorMessage = 'Please enter city');
                        return;
                      }
                      if (state.isEmpty) {
                        setState(() => _errorMessage = 'Please enter state');
                        return;
                      }
                      if (zip.isEmpty || zip.length != 6) {
                        setState(() => _errorMessage = 'Please enter a valid 6-digit pincode');
                        return;
                      }

                      if (gst.isNotEmpty) {
                        final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                        if (!gstRegex.hasMatch(gst)) {
                          setState(() => _errorMessage = 'Invalid GST format (e.g. 22AAAAA0000A1Z5)');
                          return;
                        }
                      }

                      if (pan.isNotEmpty) {
                        final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                        if (!panRegex.hasMatch(pan)) {
                          setState(() => _errorMessage = 'Invalid PAN format (e.g. ABCDE1234F)');
                          return;
                        }
                      }

                      final newAddress = AddressModel(
                        name: name,
                        mobile: mobile,
                        buildingName: building,
                        street: street,
                        area: area,
                        landmark: landmark.isEmpty ? null : landmark,
                        city: city,
                        state: state,
                        zipCode: zip,
                        gstNumber: gst.isEmpty ? null : gst,
                        panNumber: pan.isEmpty ? null : pan,
                        isDefault: widget.address?.isDefault ?? false,
                      );

                      bool success;
                      if (widget.address == null) {
                        success = await AddressController.instance.addAddress(
                          newAddress,
                        );
                      } else {
                        success = await AddressController.instance
                            .updateAddress(widget.address!.id!, newAddress);
                      }

                      if (success && mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'SAVE ADDRESS',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPhone = false,
    bool isPincode = false,
    Widget? suffix,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isPhone || isPincode
              ? TextInputType.number
              : TextInputType.text,
          inputFormatters: [
            if (isPincode) LengthLimitingTextInputFormatter(6),
            if (isPhone) LengthLimitingTextInputFormatter(10),
            if (isPhone || isPincode) FilteringTextInputFormatter.digitsOnly,
            if (label.contains('GST')) LengthLimitingTextInputFormatter(15),
            if (label.contains('PAN')) LengthLimitingTextInputFormatter(10),
          ],
          onChanged: (value) {
            if (isPincode && value.length == 6) {
              _fetchCityAndState(value);
            }
          },
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 20,
              color: AppColors.primaryBlue.withOpacity(0.7),
            ),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: suffix,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: AppColors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.inter(color: AppColors.grey[400], fontSize: 14),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
