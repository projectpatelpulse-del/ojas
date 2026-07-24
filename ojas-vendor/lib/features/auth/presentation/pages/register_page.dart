import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'dart:convert';
import 'package:ojas_vendor/core/services/api_service.dart';
import 'package:ojas_vendor/core/services/service_locator.dart';
import 'package:ojas_vendor/features/categories/data/services/category_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentStep = 0;
  final Set<String> _selectedCategories = {};
  String? _selectedFileName;
  PlatformFile? _selectedFile;
  List<String> _categories = [];
  bool _isLoadingCategories = true;

  // Signup Controllers - Personal
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Signup Controllers - Business
  final TextEditingController _businessNameController = TextEditingController();
  String _businessType = 'Select type';
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Signup Controllers - Products
  final TextEditingController _avgOrderValueController =
      TextEditingController();
  String _monthlyVolume = 'Select volume';
  final TextEditingController _productDetailsController =
      TextEditingController();

  // Signup Controllers - Documents
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  bool _agreedToTerms = false;
  bool _agreedToMarketing = false;
  bool _obscureSignupPassword = true;

  // Form Keys for validation
  final _personalFormKey = GlobalKey<FormState>();
  final _businessFormKey = GlobalKey<FormState>();
  final _productsFormKey = GlobalKey<FormState>();
  final _documentsFormKey = GlobalKey<FormState>();

  bool _showFileError = false;
  bool _showCategoryError = false;

  @override
  void initState() {
    super.initState();
    _zipCodeController.addListener(_onZipCodeChanged);
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await sl<CategoryService>().getPublicCategories();
      setState(() {
        _categories = cats.map((e) => e['name'].toString()).toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _categories = [
          'Electronics',
          'Fashion',
          'Home & Garden',
          'Beauty',
          'Sports',
        ];
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _zipCodeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _descriptionController.dispose();
    _avgOrderValueController.dispose();
    _productDetailsController.dispose();
    _gstController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  void _onZipCodeChanged() {
    final zip = _zipCodeController.text.trim();
    if (zip.length == 6) {
      _fetchAddressFromZip(zip);
    }
  }

  Future<void> _fetchAddressFromZip(String zip) async {
    try {
      final dio = dio_pkg.Dio();
      final response = await dio.get(
        'https://api.postalpincode.in/pincode/$zip',
      );
      if (response.statusCode == 200 &&
          response.data is List &&
          response.data.isNotEmpty) {
        final status = response.data[0]['Status'];
        if (status == 'Success') {
          final postOffice = response.data[0]['PostOffice'][0];
          setState(() {
            _cityController.text = postOffice['District'] ?? '';
            _stateController.text = postOffice['State'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching address: $e');
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null) {
      setState(() {
        _selectedFile = result.files.single;
        _selectedFileName = result.files.single.name;
        _showFileError = false;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms to proceed.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF5C0B1B)),
      ),
    );

    try {
      final formData = dio_pkg.FormData.fromMap({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'businessName': _businessNameController.text,
        'businessType': _businessType,
        'website': _websiteController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zipCode': _zipCodeController.text,
        'description': _descriptionController.text,
        'categories': jsonEncode(_selectedCategories.toList()),
        'avgOrderValue': _avgOrderValueController.text,
        'monthlyVolume': _monthlyVolume,
        'productDetails': _productDetailsController.text,
        'gstNumber': _gstController.text,
        'bankAccount': _bankAccountController.text,
        'bankName': _bankNameController.text,
        'ifscCode': _ifscController.text,
      });

      if (_selectedFile != null && _selectedFile!.bytes != null) {
        formData.files.add(
          MapEntry(
            'license',
            dio_pkg.MultipartFile.fromBytes(
              _selectedFile!.bytes!,
              filename: _selectedFileName,
            ),
          ),
        );
      }

      final response = await sl<ApiService>().dio.post(
        '/vendor/signup',
        data: formData,
      );
      Navigator.pop(context);

      if (response.statusCode == 201) {
        String? otp;
        if (response.data != null && response.data is Map) {
          final data = response.data['data'];
          if (data != null && data is Map) {
            otp = data['whatsappOtp']?.toString();
          }
        }
        _showOTPDialog(_phoneController.text, otp);
      }
    } catch (e) {
      Navigator.pop(context);
      final message = _getErrorMessage(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _getErrorMessage(dynamic e) {
    if (e is dio_pkg.DioException) {
      final responseData = e.response?.data;
      if (responseData != null) {
        if (responseData is Map && responseData.containsKey('message')) {
          return responseData['message'].toString();
        } else if (responseData is Map && responseData.containsKey('error')) {
          return responseData['error'].toString();
        } else if (responseData is String) {
          return responseData;
        }
      }
      return e.message ?? 'An unexpected network error occurred.';
    }
    return e.toString();
  }

  void _showOTPDialog(String phone, String? otp) {
    final TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Verify WhatsApp OTP', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the 6-digit OTP sent to your WhatsApp number +91 $phone'),
            if (otp != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C0B1B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'OTP: $otp',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5C0B1B),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'Enter OTP',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final otp = otpController.text.trim();
              if (otp.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
                );
                return;
              }

              try {
                final response = await sl<ApiService>().dio.post(
                  '/vendor/verify-otp',
                  data: {'phone': phone, 'otp': otp},
                );

                if (response.statusCode == 200) {
                  Navigator.pop(context); // Close OTP dialog
                  
                  // Show success dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Success'),
                      content: const Text(
                        'WhatsApp number verified successfully! Please wait for admin approval.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close success dialog
                            Navigator.pop(context); // Go back to login
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                final message = _getErrorMessage(e);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Verification failed: $message')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C0B1B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    bool isValid = false;
    switch (_currentStep) {
      case 0:
        isValid = _personalFormKey.currentState?.validate() ?? false;
        break;
      case 1:
        isValid = _businessFormKey.currentState?.validate() ?? false;
        if (isValid && _businessType == 'Select type') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select business type')),
          );
          isValid = false;
        }
        break;
      case 2:
        isValid = _productsFormKey.currentState?.validate() ?? false;
        if (_selectedCategories.isEmpty) {
          setState(() => _showCategoryError = true);
          isValid = false;
        } else if (_monthlyVolume == 'Select volume') {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please select volume')));
          isValid = false;
        }
        break;
      case 3:
        isValid = _documentsFormKey.currentState?.validate() ?? false;
        if (_selectedFile == null) {
          setState(() => _showFileError = true);
          isValid = false;
        }
        break;
      case 4:
        _submitApplication();
        return;
    }
    if (isValid) setState(() => _currentStep++);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
    final Color ojasMaroon = const Color(0xFF5C0B1B);

    Widget formContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMobile) ...[
          _MobileProgress(currentStep: _currentStep),
        ] else ...[
          _DesktopProgress(currentStep: _currentStep),
        ],

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),

        _buildStepContent(isMobile),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0)
              _NavBtn(
                label: 'Back',
                icon: Icons.arrow_back,
                onPressed: () => setState(() => _currentStep--),
                isPrimary: false,
              )
            else
              const SizedBox(),
            _NavBtn(
              label: _currentStep == 4
                  ? 'Submit Application'
                  : 'Next Step',
              icon: _currentStep == 4
                  ? Icons.check_circle_outline
                  : Icons.arrow_forward,
              onPressed: _nextStep,
              isPrimary: true,
              color: _currentStep == 4
                  ? const Color(0xFF10B981)
                  : ojasMaroon,
            ),
          ],
        ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFFFBECEB),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Premium Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  children: [
                    Text(
                      'Become a Vendor',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: ojasMaroon,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join thousands of successful vendors and grow your business with Ojas India.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Benefit Cards
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _BenefitCard(
                    icon: Icons.attach_money,
                    title: 'Commission',
                    desc: 'Low platform fees',
                    isMobile: isMobile,
                  ),
                  _BenefitCard(
                    icon: Icons.public,
                    title: 'Global',
                    desc: 'Reach customers worldwide',
                    isMobile: isMobile,
                  ),
                  _BenefitCard(
                    icon: Icons.security,
                    title: 'Secure',
                    desc: 'Safe & timely payments',
                    isMobile: isMobile,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Form Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: formContent,
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/auth.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Row(
          children: [
            const Spacer(flex: 58),
            Expanded(
              flex: 38,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: formContent,
                  ),
                ),
              ),
            ),
            const Spacer(flex: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isMobile) {
    switch (_currentStep) {
      case 0:
        return Form(key: _personalFormKey, child: _buildPersonalInfo(isMobile));
      case 1:
        return Form(key: _businessFormKey, child: _buildBusinessInfo(isMobile));
      case 2:
        return Form(key: _productsFormKey, child: _buildProductsInfo(isMobile));
      case 3:
        return Form(
          key: _documentsFormKey,
          child: _buildDocumentsInfo(isMobile),
        );
      case 4:
        return _buildReviewInfo(isMobile);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPersonalInfo(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Personal Information'),
        const SizedBox(height: 10),
        _rowOrCol(isMobile, [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _FormField(
              label: 'First Name *',
              hintText: 'First Name',
              controller: _firstNameController,
            ),
          ),
          SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 10 : 0),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _FormField(
              label: 'Last Name *',
              hintText: 'Last Name',
              controller: _lastNameController,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        _rowOrCol(isMobile, [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _FormField(
              label: 'Email Address *',
              hintText: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(val)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
          ),
          SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 10 : 0),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _FormField(
              label: 'Phone Number *',
              hintText: '1234567890',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixText: '+91 ',
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (val.length != 10) return 'Must be 10 digits';
                return null;
              },
            ),
          ),
        ]),
        const SizedBox(height: 10),
        _FormField(
          label: 'Password *',
          hintText: 'Create password',
          isPassword: true,
          isObscured: _obscureSignupPassword,
          onToggleVisibility: () =>
              setState(() => _obscureSignupPassword = !_obscureSignupPassword),
          controller: _passwordController,
          validator: (val) {
            if (val == null || val.isEmpty) return 'Required';
            if (val.length < 8) return 'Min 8 characters';
            if (!RegExp(r'[A-Z]').hasMatch(val)) {
              return 'Add an uppercase letter';
            }
            if (!RegExp(r'[a-z]').hasMatch(val)) {
              return 'Add a lowercase letter';
            }
            if (!RegExp(r'[0-9]').hasMatch(val)) return 'Add a number';
            if (!RegExp(r'[!@#\$&*~]').hasMatch(val)) {
              return 'Add a special character';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBusinessInfo(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Business Information'),
        const SizedBox(height: 24),
        _rowOrCol(isMobile, [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _FormField(
              label: 'Business Name *',
              hintText: 'Business Name',
              controller: _businessNameController,
            ),
          ),
          SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 24 : 0),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _DropdownField(
              label: 'Business Type *',
              items: const [
                'Select type',
                'Individual',
                'Partnership',
                'LLC',
                'Corporation',
              ],
              value: _businessType,
              onChanged: (v) => setState(() => _businessType = v!),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _FormField(
          label: 'Business Website (Optional)',
          hintText: 'https://www.example.com',
          controller: _websiteController,
          validator: (val) {
            if (val == null || val.isEmpty) return null;
            if (!RegExp(r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$').hasMatch(val)) {
              return 'Enter a valid URL';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        _FormField(
          label: 'Business Address *',
          hintText: 'Street address',
          controller: _addressController,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'City *',
                hintText: 'City',
                controller: _cityController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FormField(
                label: 'State *',
                hintText: 'State',
                controller: _stateController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FormField(
                label: 'Zip Code *',
                hintText: '123456',
                controller: _zipCodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (val.length != 6) return 'Must be 6 digits';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _FormField(
          label: 'Business Description',
          hintText: 'Briefly describe your business...',
          maxLines: 3,
          controller: _descriptionController,
        ),
      ],
    );
  }

  Widget _buildProductsInfo(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Product Information'),
        const SizedBox(height: 24),
        Text(
          'Product Categories * (Select all that apply)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _showCategoryError ? Colors.red : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoadingCategories
              ? const Center(child: CircularProgressIndicator())
              : _buildCategoryGrid(_categories, isMobile),
        ),
        if (_showCategoryError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one category',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 24),
        _rowOrCol(isMobile, [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _FormField(
              label: 'Average Order Value (₹) *',
              hintText: 'e.g. 500',
              controller: _avgOrderValueController,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 24 : 0),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _DropdownField(
              label: 'Monthly Volume',
              items: const [
                'Select volume',
                '1-10 orders',
                '11-50 orders',
                '51-100 orders',
                '100+ orders',
              ],
              value: _monthlyVolume,
              onChanged: (v) => setState(() => _monthlyVolume = v!),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _FormField(
          label: 'Product Types & Details *',
          hintText: 'Tell us what you sell...',
          maxLines: 4,
          controller: _productDetailsController,
        ),
      ],
    );
  }

  Widget _buildDocumentsInfo(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Required Documents'),
        const SizedBox(height: 24),
        _DashedUploadBox(
          label: 'Trade License / GST Certificate *',
          hint: _selectedFileName ?? 'Upload business license (PDF/JPG)',
          onTap: _pickFile,
          hasError: _showFileError,
        ),
        const SizedBox(height: 24),
        _rowOrCol(isMobile, [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _FormField(
              label: 'GST Number *',
              hintText: 'Enter GST',
              controller: _gstController,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (!RegExp(
                  r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
                ).hasMatch(val)) {
                  return 'Invalid GST format e.g. 29ABCDE1234F1Z5';
                }
                return null;
              },
            ),
          ),
          SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 24 : 0),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _FormField(
              label: 'Bank Name *',
              hintText: 'Enter bank name',
              controller: _bankNameController,
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _rowOrCol(isMobile, [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _FormField(
              label: 'Account Number *',
              hintText: 'Enter account',
              controller: _bankAccountController,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 24 : 0),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _FormField(
              label: 'IFSC Code *',
              hintText: 'Enter IFSC',
              controller: _ifscController,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(val)) {
                  return 'Invalid IFSC format e.g. SBIN0000001';
                }
                return null;
              },
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildReviewInfo(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Review Your Application'),
        const SizedBox(height: 32),
        _buildReviewSection(
          title: 'Personal Info',
          content:
              '${_firstNameController.text} ${_lastNameController.text} • ${_emailController.text}',
        ),
        _buildReviewSection(
          title: 'Business Details',
          content:
              '${_businessNameController.text} • ${_cityController.text}, ${_stateController.text}',
        ),
        _buildReviewSection(
          title: 'Categories',
          content: _selectedCategories.join(', '),
        ),
        _buildReviewSection(
          title: 'Banking',
          content:
              'GST: ${_gstController.text} • Bank: ${_bankNameController.text}',
        ),
        const SizedBox(height: 40),
        _CheckboxItem(
          label: 'I agree to the Terms & Conditions and Privacy Policy',
          value: _agreedToTerms,
          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
        ),
        _CheckboxItem(
          label: 'I consent to receive marketing communications',
          value: _agreedToMarketing,
          onChanged: (v) => setState(() => _agreedToMarketing = v ?? false),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(List<String> categories, bool isMobile) {
    int crossAxisCount = isMobile ? 1 : 2;
    List<Widget> rows = [];
    for (int i = 0; i < categories.length; i += crossAxisCount) {
      List<Widget> rowChildren = [];
      for (int j = 0; j < crossAxisCount; j++) {
        if (i + j < categories.length) {
          final cat = categories[i + j];
          rowChildren.add(
            Expanded(
              child: _CheckboxItem(
                label: cat,
                value: _selectedCategories.contains(cat),
                onChanged: (val) => setState(
                  () => val == true
                      ? _selectedCategories.add(cat)
                      : _selectedCategories.remove(cat),
                ),
              ),
            ),
          );
        } else if (!isMobile) {
          rowChildren.add(const Expanded(child: SizedBox()));
        }
      }
      rows.add(Row(children: rowChildren));
    }
    return Column(children: rows);
  }

  Widget _buildReviewSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTitle(String title) => Text(
    title,
    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
  );

  Widget _rowOrCol(bool isMobile, List<Widget> children) =>
      isMobile ? Column(children: children) : Row(children: children);
}

// Helper Widgets
class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool isMobile;
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.isMobile,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF5C0B1B), size: 36),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopProgress extends StatelessWidget {
  final int currentStep;
  const _DesktopProgress({required this.currentStep});
  @override
  Widget build(BuildContext context) {
    final steps = ['Personal', 'Business', 'Products', 'Documents', 'Review'];
    final icons = [
      Icons.person_outline,
      Icons.domain,
      Icons.inventory_2_outlined,
      Icons.description_outlined,
      Icons.check_circle_outline,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        5,
        (index) => _StepIcon(
          active: currentStep >= index,
          icon: icons[index],
          title: steps[index],
        ),
      ),
    );
  }
}

class _MobileProgress extends StatelessWidget {
  final int currentStep;
  const _MobileProgress({required this.currentStep});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: CircleAvatar(
            radius: 4,
            backgroundColor: currentStep >= index
                ? const Color(0xFF5C0B1B)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String title;
  const _StepIcon({
    required this.active,
    required this.icon,
    required this.title,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: active
              ? const Color(0xFF5C0B1B)
              : const Color(0xFFF1F5F9),
          child: Icon(
            icon,
            color: active ? Colors.white : const Color(0xFF64748B),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? const Color(0xFF5C0B1B) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool isPassword;
  final bool isObscured;
  final VoidCallback? onToggleVisibility;
  final TextInputType? keyboardType;
  final String? prefixText;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _FormField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.isPassword = false,
    this.isObscured = false,
    this.onToggleVisibility,
    this.keyboardType,
    this.prefixText,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.validator,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: isPassword && isObscured,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            counterText: "",
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isObscured ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          validator:
              validator ??
              (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final List<String> items;
  final String value;
  final Function(String?) onChanged;
  const _DropdownField({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckboxItem extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool?) onChanged;
  const _CheckboxItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF5C0B1B),
        ),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14))),
      ],
    );
  }
}

class _DashedUploadBox extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback onTap;
  final bool hasError;
  const _DashedUploadBox({
    required this.label,
    required this.hint,
    required this.onTap,
    this.hasError = false,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: hasError ? Colors.red.shade50 : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError ? Colors.red : const Color(0xFFCBD5E1),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: Color(0xFF5C0B1B),
                ),
                const SizedBox(height: 16),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? color;
  const _NavBtn({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = true,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            color ?? (isPrimary ? const Color(0xFF5C0B1B) : Colors.white),
        foregroundColor: isPrimary ? Colors.white : const Color(0xFF475569),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
