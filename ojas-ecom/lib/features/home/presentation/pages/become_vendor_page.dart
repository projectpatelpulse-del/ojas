import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';

class BecomeVendorPage extends StatefulWidget {
  const BecomeVendorPage({super.key});

  @override
  State<BecomeVendorPage> createState() => _BecomeVendorPageState();
}

class _BecomeVendorPageState extends State<BecomeVendorPage> {
  int _currentStep = 0;
  bool _isLogin = true;
  final Set<String> _selectedCategories = {};
  String? _selectedFileName;
  PlatformFile? _selectedFile;

  // Login Controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

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
  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;

  // Form Keys for validation
  final _personalFormKey = GlobalKey<FormState>();
  final _businessFormKey = GlobalKey<FormState>();
  final _productsFormKey = GlobalKey<FormState>();
  final _documentsFormKey = GlobalKey<FormState>();

  // Validation States
  bool _showFileError = false;
  bool _showCategoryError = false;

  @override
  void initState() {
    super.initState();
    _zipCodeController.addListener(_onZipCodeChanged);

    // Listeners for Personal Info validation
    _firstNameController.addListener(() => setState(() {}));
    _lastNameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _zipCodeController.removeListener(_onZipCodeChanged);
    _cityController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _businessNameController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
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
      final response = await http.get(
        Uri.parse('https://api.postalpincode.in/pincode/$zip'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffice = data[0]['PostOffice'][0];
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.single;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to the Terms & Conditions and Privacy Policy to proceed.',
          ),
          backgroundColor: Color(0xFFF01B6B),
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFF01B6B)),
      ),
    );

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/vendor/signup'),
      );
      // Fields
      request.fields['firstName'] = _firstNameController.text;
      request.fields['lastName'] = _lastNameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['phone'] = _phoneController.text;
      request.fields['password'] = _passwordController.text;
      request.fields['businessName'] = _businessNameController.text;
      request.fields['businessType'] = _businessType;
      request.fields['website'] = _websiteController.text;
      request.fields['address'] = _addressController.text;
      request.fields['city'] = _cityController.text;
      request.fields['state'] = _stateController.text;
      request.fields['zipCode'] = _zipCodeController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['categories'] = jsonEncode(_selectedCategories.toList());
      request.fields['avgOrderValue'] = _avgOrderValueController.text;
      request.fields['monthlyVolume'] = _monthlyVolume;
      request.fields['productDetails'] = _productDetailsController.text;
      request.fields['gstNumber'] = _gstController.text;
      request.fields['bankAccount'] = _bankAccountController.text;
      request.fields['bankName'] = _bankNameController.text;
      request.fields['ifscCode'] = _ifscController.text;

      // File
      if (_selectedFile != null && _selectedFile!.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'license',
            _selectedFile!.bytes!,
            filename: _selectedFileName,
          ),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      Navigator.pop(context); // Remove loading

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(
              data['message'] ?? 'Application submitted successfully!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _toggleMode(true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Error submitting application'),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _loginVendor() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFF01B6B)),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/vendor/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _loginEmailController.text,
          'password': _loginPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      Navigator.pop(context);

      if (response.statusCode == 200) {
        // Handle successful login - redirect to vendor panel
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful! Redirecting to Vendor Panel...'),
          ),
        );

        final token = data['token'];

        // Define vendor panel URLs for dev and prod
        final vendorPanelUrl =
            // kDebugMode
            //     ? 'http://localhost:5000/#/?token=$token':
            'https://vendor.ojasindia.com/#/?token=$token';
        Future.delayed(const Duration(seconds: 1), () {
          html.window.location.href = vendorPanelUrl;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
            const SnackBar(content: Text('Please select a business type')),
          );
          isValid = false;
        }
        break;
      case 2:
        isValid = _productsFormKey.currentState?.validate() ?? false;
        if (_selectedCategories.isEmpty) {
          setState(() => _showCategoryError = true);
          isValid = false;
        } else {
          setState(() => _showCategoryError = false);
        }
        if (isValid && _monthlyVolume == 'Select volume') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select expected monthly volume'),
            ),
          );
          isValid = false;
        }
        break;
      case 3:
        isValid = _documentsFormKey.currentState?.validate() ?? false;
        if (_selectedFile == null) {
          setState(() => _showFileError = true);
          isValid = false;
        } else {
          setState(() => _showFileError = false);
        }
        break;
      case 4:
        _submitApplication();
        return;
    }

    if (isValid) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _toggleMode(bool login) {
    setState(() {
      _isLogin = login;
      if (!login) _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return OjasLayout(
      activeTitle: 'BECOME VENDOR',
      child: Container(
        color: const Color(0xFFF8FAFC),
        padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 80),
        child: CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: Column(
            children: [
              if (!_isLogin)
                Text(
                  'Become a vendor',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 32 : 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              if (!_isLogin) SizedBox(height: isMobile ? 12 : 16),
              Text(
                _isLogin
                    ? 'Access your vendor dashboard to manage your products, orders, and business analytics.'
                    : 'Join thousands of successful vendors and grow your business with us.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 15 : 18,
                  color: const Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              SizedBox(height: isMobile ? 32 : 48),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Flex(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _toggleMode(false),
                      child: _ToggleButton(
                        title: 'Become a Vendor',
                        isActive: !_isLogin,
                        fullWidth: isMobile,
                      ),
                    ),
                    if (isMobile) const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _toggleMode(true),
                      child: _ToggleButton(
                        title: 'Login',
                        isActive: _isLogin,
                        fullWidth: isMobile,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 40 : 60),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLogin
                    ? _buildLoginForm(isMobile)
                    : _buildRegistrationFlow(isMobile),
              ),

              SizedBox(height: isMobile ? 60 : 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 500,
      padding: EdgeInsets.all(isMobile ? 24 : 48),
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
      child: Column(
        children: [
          CircleAvatar(
            radius: isMobile ? 32 : 40,
            backgroundColor: const Color(0xFFFCE7F3),
            child: Icon(
              Icons.person_outline,
              size: isMobile ? 28 : 36,
              color: const Color(0xFFF01B6B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Vendor Login',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 32),
          _FormField(
            label: 'Email Address *',
            hintText: 'demo@example.com',
            controller: _loginEmailController,
          ),
          const SizedBox(height: 20),
          _FormField(
            label: 'Password *',
            hintText: '••••••••',
            isPassword: true,
            isObscured: _obscureLoginPassword,
            onToggleVisibility: () =>
                setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            controller: _loginPasswordController,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loginVendor,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF01B6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Sign In',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => _toggleMode(false),
            child: Text(
              'New here? Become a Vendor',
              style: GoogleFonts.inter(
                color: const Color(0xFFF01B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationFlow(bool isMobile) {
    return ListenableBuilder(
      listenable: HomeController.instance,
      builder: (context, _) {
        return Column(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _BenefitCard(
                  icon: Icons.attach_money,
                  title: 'Commission',
                  desc: 'Low fees',
                  isMobile: isMobile,
                ),
                _BenefitCard(
                  icon: Icons.public,
                  title: 'Global',
                  desc: 'Reach 25+ countries',
                  isMobile: isMobile,
                ),
                _BenefitCard(
                  icon: Icons.security,
                  title: 'Secure',
                  desc: 'Safe payments',
                  isMobile: isMobile,
                ),
              ],
            ),
            SizedBox(height: isMobile ? 40 : 60),
            Container(
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  if (isMobile)
                    _MobileProgress(currentStep: _currentStep)
                  else
                    _DesktopProgress(currentStep: _currentStep),
                  SizedBox(height: isMobile ? 32 : 48),
                  const Divider(),
                  SizedBox(height: isMobile ? 32 : 48),
                  _buildStepContent(isMobile),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        _NavBtn(
                          label: 'Back',
                          icon: Icons.arrow_back,
                          onPressed: _previousStep,
                          isPrimary: false,
                        )
                      else
                        const SizedBox(),
                      _NavBtn(
                        label: _currentStep == 4
                            ? 'Submit Application'
                            : 'Next',
                        icon: _currentStep == 4
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward,
                        onPressed: _nextStep,
                        isPrimary: true,
                        color: _currentStep == 4
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFF01B6B),
                        textColor: _currentStep == 4
                            ? Colors.white
                            : Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
        return const Center(child: Text('Form Section Coming Soon'));
    }
  }

  Widget _buildPersonalInfo(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'First Name *',
                hintText: 'First Name',
                controller: _firstNameController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _FormField(
                label: 'Last Name *',
                hintText: 'Last Name',
                controller: _lastNameController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'Email Address *',
                hintText: 'Email Address',
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
            const SizedBox(width: 24),
            Expanded(
              child: _FormField(
                label: 'Phone Number *',
                hintText: '1234567890',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixText: '+91 ',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (val.length != 10) return 'Must be 10 digits';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _FormField(
          label: 'Password *',
          hintText: 'Create a strong password',
          isPassword: true,
          isObscured: _obscureSignupPassword,
          onToggleVisibility: () =>
              setState(() => _obscureSignupPassword = !_obscureSignupPassword),
          controller: _passwordController,
          validator: (val) {
            if (val == null || val.isEmpty) return 'Required';
            if (val.length < 8) return 'Password must be at least 8 characters';
            if (!RegExp(r'[A-Z]').hasMatch(val)) {
              return 'Must contain at least one uppercase letter';
            }
            if (!RegExp(r'[a-z]').hasMatch(val)) {
              return 'Must contain at least one lowercase letter';
            }
            if (!RegExp(r'[0-9]').hasMatch(val)) {
              return 'Must contain at least one number';
            }
            if (!RegExp(r'[!@#\$&*~%^()_+=|<>?{}]').hasMatch(val)) {
              return 'Must contain at least one special character';
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
        Text(
          'Business Information',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'Business Name *',
                hintText: 'Enter business name',
                controller: _businessNameController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _DropdownField(
                label: 'Business Type *',
                items: const [
                  'Select type',
                  'Individual',
                  'Partnership',
                  'LLC',
                  'Corporation',
                  'Other',
                ],
                value: _businessType,
                onChanged: (val) => setState(() => _businessType = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _FormField(
          label: 'Business Website (Optional)',
          hintText: 'https://www.example.com',
          controller: _websiteController,
        ),
        const SizedBox(height: 24),
        _FormField(
          label: 'Business Address *',
          hintText: 'Enter street address',
          controller: _addressController,
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'City *',
                hintText: 'City',
                controller: _cityController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FormField(
                label: 'State *',
                hintText: 'State',
                controller: _stateController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FormField(
                label: 'Zip Code *',
                hintText: 'Zip Code',
                controller: _zipCodeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
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
        Text(
          'Product Information',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
          child: Column(
            children: [
              _buildCategoryGrid(
                HomeController.instance.categories.isNotEmpty
                    ? HomeController.instance.categories
                          .map((c) => c['name'].toString())
                          .toList()
                    : [
                        'Electronics',
                        'Fashion & Clothing',
                        'Home & Garden',
                        'Beauty & Personal Care',
                        'Sports & Outdoors',
                        'Books & Media',
                        'Toys & Games',
                        'Automotive',
                        'Health & Wellness',
                        'Food & Beverages',
                      ],
                isMobile,
              ),
            ],
          ),
        ),
        if (_showCategoryError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Please select at least one category',
              style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 24),
        if (isMobile) ...[
          _FormField(
            label: 'Average Order Value (₹) *',
            hintText: 'e.g. 500',
            controller: _avgOrderValueController,
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          _DropdownField(
            label: 'Expected Monthly Volume',
            items: const [
              'Select volume',
              '1-10 orders',
              '11-50 orders',
              '51-100 orders',
              '101-500 orders',
              '500+ orders',
            ],
            value: _monthlyVolume,
            onChanged: (val) => setState(() => _monthlyVolume = val!),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FormField(
                  label: 'Average Order Value (₹) *',
                  hintText: 'e.g. 500',
                  controller: _avgOrderValueController,
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _DropdownField(
                  label: 'Expected Monthly Volume',
                  items: const [
                    'Select volume',
                    '1-10 orders',
                    '11-50 orders',
                    '51-100 orders',
                    '101-500 orders',
                    '500+ orders',
                  ],
                  value: _monthlyVolume,
                  onChanged: (val) => setState(() => _monthlyVolume = val!),
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),
        _FormField(
          label: 'Product Types & Details *',
          hintText: 'Describe details...',
          maxLines: 4,
          controller: _productDetailsController,
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(List<String> categories, bool isMobile) {
    if (isMobile) {
      return Column(
        children: categories
            .map(
              (cat) => _CheckboxItem(
                label: cat,
                value: _selectedCategories.contains(cat),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedCategories.add(cat);
                    } else {
                      _selectedCategories.remove(cat);
                    }
                  });
                },
              ),
            )
            .toList(),
      );
    }

    List<Widget> rows = [];
    for (int i = 0; i < categories.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _buildCheckbox(categories[i])),
            if (i + 1 < categories.length)
              Expanded(child: _buildCheckbox(categories[i + 1])),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildCheckbox(String label) {
    return _CheckboxItem(
      label: label,
      value: _selectedCategories.contains(label),
      onChanged: (val) {
        setState(() {
          if (val == true) {
            _selectedCategories.add(label);
          } else {
            _selectedCategories.remove(label);
          }
        });
      },
    );
  }

  Widget _buildDocumentsInfo(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Documents',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _DashedUploadBox(
          label: 'Business License/Registration/GST Certificate *',
          hint:
              _selectedFileName ??
              'Upload your business license, registration, or GST certificate',
          onTap: _pickFile,
          hasError: _showFileError,
        ),
        const SizedBox(height: 24),
        if (isMobile) ...[
          _FormField(
            label: 'GST Number *',
            hintText: 'Enter GST number',
            controller: _gstController,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required';
              if (!RegExp(
                r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
              ).hasMatch(val)) {
                return 'Enter a valid GST number e.g. 29ABCDE1234F1Z5';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _FormField(
            label: 'Bank Name *',
            hintText: 'Enter bank name',
            controller: _bankNameController,
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Account Number *',
                  hintText: 'Enter account number',
                  controller: _bankAccountController,
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FormField(
                  label: 'IFSC Code *',
                  hintText: 'Enter IFSC code',
                  controller: _ifscController,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(val)) {
                      return 'Enter a valid IFSC code e.g. SBIN0000001';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'GST Number *',
                  hintText: 'Enter GST number',
                  controller: _gstController,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (!RegExp(
                      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
                    ).hasMatch(val)) {
                      return 'Enter a valid GST number e.g. 29ABCDE1234F1Z5';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _FormField(
                  label: 'Bank Name *',
                  hintText: 'Enter bank name',
                  controller: _bankNameController,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Bank Account Number *',
                  hintText: 'Enter full bank account number',
                  controller: _bankAccountController,
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _FormField(
                  label: 'IFSC Code *',
                  hintText: 'Enter IFSC code',
                  controller: _ifscController,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(val)) {
                      return 'Enter a valid IFSC code e.g. SBIN0000001';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF3B82F6),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Note: All documents will be securely stored and used only for verification purposes. We support PDF, JPG, JPEG, and PNG formats up to 10MB.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF1E40AF),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewInfo(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Application',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),

        _buildReviewSection(
          title: 'Personal Information',
          content:
              '${_firstNameController.text} ${_lastNameController.text} • ${_emailController.text} • ${_phoneController.text}',
        ),
        const SizedBox(height: 24),
        _buildReviewSection(
          title: 'Business Information',
          content:
              '${_businessNameController.text} • $_businessType • ${_cityController.text}, ${_stateController.text}',
        ),
        const SizedBox(height: 24),
        _buildReviewSection(
          title: 'Product Categories',
          content: _selectedCategories.isEmpty
              ? 'None selected'
              : _selectedCategories.join(', '),
        ),
        const SizedBox(height: 24),
        _buildReviewSection(
          title: 'Documents & Banking',
          content:
              'GST: ${_gstController.text} • Bank: ${_bankNameController.text} • A/C: ${_bankAccountController.text} • IFSC: ${_ifscController.text}',
        ),

        const SizedBox(height: 40),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                activeColor: const Color(0xFFF01B6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF475569),
                    ),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF01B6B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF01B6B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreedToMarketing,
                onChanged: (v) =>
                    setState(() => _agreedToMarketing = v ?? false),
                activeColor: const Color(0xFFF01B6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _agreedToMarketing = !_agreedToMarketing),
                child: Text(
                  'I consent to receive marketing communications and updates about vendor opportunities',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool fullWidth;
  const _ToggleButton({
    required this.title,
    required this.isActive,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : 200,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF01B6B) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

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
      width: isMobile ? double.infinity : 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFF01B6B), size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
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

  static const steps = [
    {
      'icon': Icons.person_outline,
      'title': 'Personal Info',
      'desc': 'Your personal details',
    },
    {
      'icon': Icons.domain,
      'title': 'Business Info',
      'desc': 'Business information',
    },
    {
      'icon': Icons.inventory_2_outlined,
      'title': 'Products',
      'desc': 'Product details',
    },
    {
      'icon': Icons.description_outlined,
      'title': 'Documents',
      'desc': 'Required documents',
    },
    {
      'icon': Icons.check_circle_outline,
      'title': 'Review',
      'desc': 'Review & submit',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        5,
        (index) => _StepIcon(
          index: index,
          active: currentStep >= index,
          icon: steps[index]['icon'] as IconData,
          title: steps[index]['title'] as String,
          desc: steps[index]['desc'] as String,
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
                ? const Color(0xFFF01B6B)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final int index;
  final bool active;
  final IconData icon;
  final String title;
  final String desc;

  const _StepIcon({
    required this.index,
    required this.active,
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: active
              ? const Color(0xFFF01B6B)
              : const Color(0xFFF1F5F9),
          child: Icon(
            icon,
            color: active ? Colors.white : const Color(0xFF64748B),
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: active ? const Color(0xFFF01B6B) : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
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
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: hasError
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFFDFDFD),
            ),
            child: CustomPaint(
              painter: _DashPainter(
                color: hasError ? Colors.red : const Color(0xFFCBD5E1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 54,
                    color: hasError ? Colors.red : _hintColor(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    hint,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: hasError ? Colors.red : _hintColor(),
                      fontWeight: _selectedFileName()
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      _selectedFileName() ? 'Change File' : 'Choose File',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _hintColor() {
    return _selectedFileName()
        ? const Color(0xFFF01B6B)
        : const Color(0xFF64748B);
  }

  bool _selectedFileName() {
    return !hint.contains('Upload your business license');
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter({this.color = const Color(0xFFCBD5E1)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DropdownField extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  const _DropdownField({
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
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
          initialValue: value ?? items.first,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.expand_more, color: Color(0xFF64748B)),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFF01B6B),
                width: 1.5,
              ),
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
  final ValueChanged<bool?> onChanged;
  const _CheckboxItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF3B82F6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF475569),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DocumentUploadField extends StatelessWidget {
  final String title;
  final String desc;
  const _DocumentUploadField({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Text(
              'Browse',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hintText;
  final bool isPassword;
  final bool isObscured;
  final VoidCallback? onToggleVisibility;
  final int maxLines;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final String? Function(String?)? validator;

  const _FormField({
    required this.label,
    required this.hintText,
    this.isPassword = false,
    this.isObscured = true,
    this.onToggleVisibility,
    this.maxLines = 1,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.prefixText,
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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && isObscured,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: GoogleFonts.inter(
            color: const Color(0xFF1E293B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            prefixStyle: GoogleFonts.inter(
              color: const Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 14,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isObscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF64748B),
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFF01B6B),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
  final bool isDisabled;
  final Color? color;
  final Color? textColor;

  const _NavBtn({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
    this.isDisabled = false,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDisabled
        ? Colors.grey.shade300
        : (color ?? (isPrimary ? const Color(0xFFF01B6B) : Colors.white));
    final fgColor = isDisabled
        ? Colors.grey.shade500
        : (textColor ?? (isPrimary ? Colors.white : const Color(0xFF0F172A)));

    return ElevatedButton.icon(
      onPressed: isDisabled ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        disabledBackgroundColor: Colors.grey.shade200,
        disabledForegroundColor: Colors.grey.shade500,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isPrimary || isDisabled
                ? Colors.transparent
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }
}
