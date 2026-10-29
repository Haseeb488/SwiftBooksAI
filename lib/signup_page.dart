import 'dart:async';
import 'dart:convert';
import 'package:edge_alerts/edge_alerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:swiftbook_ai/login_page.dart';

import 'EmailVerificationScreen.dart';
import 'Global.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool isObscure = true;
  bool _isLoading = false;
  final String _apiKey = 'HpERVw3kg6rNy3PyTdh2Dq340lqpPJ1d';
  List<Map<String, dynamic>> _availableAddresses = [];
  String? _selectedAddressLabel;

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _postCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel(); // Always clean up timers
    _postCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _contactNumberController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPostCodeChanged(String value) {
    // Clear any existing timer if the user keeps typing
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Remove spaces to accurately check the character length
    final cleanValue = value.replaceAll(' ', '');

    // UK postcodes are generally between 5 and 7 characters
    if (cleanValue.length >= 5 && cleanValue.length <= 7) {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _fetchAddresses();
      });
    } else {
      // Optional: Clear the dropdown if the postcode becomes too short/invalid
      if (_availableAddresses.isNotEmpty) {
        setState(() {
          _availableAddresses = [];
          _selectedAddressLabel = null;
        });
      }
    }
  }

  Future formValidation() async {
    if (_firstNameController.text.isEmpty ||
        _middleNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _businessNameController.text.isEmpty ||
        _postCodeController.text.isEmpty ||
        _contactNumberController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      edgeAlert(
        context,
        title: 'All Fields Required',
        description: "Please fill all fields",
        gravity: Gravity.bottom,
        duration: 1,
        backgroundColor: Colors.blue,
        icon: Icons.warning,
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      edgeAlert(
        context,
        title: 'Password Mismatched',
        description: "Re_enter passwords and try again",
        gravity: Gravity.bottom,
        duration: 1,
        backgroundColor: Colors.blue,
        icon: Icons.warning,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EmailVerificationScreen()),
    );
  }

  /// Fetches general address details for a UK postcode.
  /// 100% Free, No API Key required.
  Future<Map<String, dynamic>?> lookupFreeUKPostcode(String postcode) async {
    // 1. Clean up the input (remove spaces and convert to uppercase)
    final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();

    final url = Uri.parse('https://api.postcodes.io/postcodes/$cleanPostcode');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 200 && data['result'] != null) {
          final res = data['result'];

          // Extract the most useful location details
          final String townCity = res['admin_district'] ?? '';
          final String county = res['admin_county'] ?? res['region'] ?? '';
          final String country = res['country'] ?? '';
          final String ward = res['admin_ward'] ?? '';

          // Combine non-empty values for a clean output
          final List<String> addressLines = [
            ward,
            townCity,
            county,
            country,
          ].where((line) => line.isNotEmpty).toList();

          return {
            'postcode': res['postcode'],
            'city_or_town': townCity,
            'county': county,
            'country': country,
            'district_ward': ward,
            'latitude': res['latitude'],
            'longitude': res['longitude'],
            'formatted_address': addressLines.join(', '),
          };
        }
      } else if (response.statusCode == 404) {
        print('Invalid UK Postcode.');
      }
    } catch (e) {
      print('Error connecting to postcode service: $e');
    }

    return null; // Return null if invalid or request failed
  }

  void showCircularProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      // Prevent the user from dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator(color: Colors.blueGrey));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(90, 20, 0, 0),
                  child: Image.asset('assets/images/grad2.png'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 100, 0),
                  child: Image.asset('assets/images/grad1.png'),
                ),
                Positioned(
                  top: 60,
                  left: 110,
                  child: Text(
                    'Swift Books AI',
                    style: GoogleFonts.lato(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: 120,
                  left: 10,
                  right: 10,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: 350,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.blueAccent.shade100,
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              "Create an account to continue!",
                              style: GoogleFonts.lato(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 30),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                controller: _firstNameController,
                                cursorColor: Colors.white,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z\s]'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                      width: 0.8,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 0.8,
                                    ),
                                  ),
                                  labelText: "First Name*",
                                  labelStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                controller: _middleNameController,
                                cursorColor: Colors.white,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z\s]'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                      width: 0.8,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 0.8,
                                    ),
                                  ),
                                  labelText: "Middle Name*",
                                  labelStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                controller: _lastNameController,
                                cursorColor: Colors.white,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,

                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z\s]'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                      width: 0.8,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 0.8,
                                    ),
                                  ),
                                  labelText: "Last Name*",
                                  labelStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                controller: _businessNameController,
                                cursorColor: Colors.white,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,

                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z\s]'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                      width: 0.8,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 0.8,
                                    ),
                                  ),
                                  labelText: "Business Name*",
                                  labelStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Postcode Search Input
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),

                              child: TextField(
                                controller: _postCodeController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                onChanged: _onPostCodeChanged,
                                // Trigger the auto-lookup here
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                      width: 0.8,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 0.8,
                                    ),
                                  ),
                                  labelText: "Post Code*",
                                  labelStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                  // Nice UX: Show a small spinner inside the text field while loading
                                  suffixIcon: _isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white60,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            if (_availableAddresses.isNotEmpty) ...[
                              const SizedBox(height: 16),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                // Matches your TextField padding
                                child: DropdownButtonFormField<String>(
                                  value: _selectedAddressLabel,
                                  isExpanded: true,
                                  // 1. Style the internal menu properties
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                  hint: const Text('Select your address'),

                                  // 2. Mirror your TextField's decoration exactly
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    // Ensures matching internal height
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                        width: 0.8,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.blue,
                                        width: 0.8,
                                      ),
                                    ),
                                    labelText: "Select Your Address*",
                                    // Floating label style matches "Post Code*"
                                    labelStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                  ),

                                  // 3. Map your items
                                  items: _availableAddresses.map((addr) {
                                    return DropdownMenuItem<String>(
                                      value: addr['display_name'],
                                      child: Text(
                                        addr['display_name'],
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() => _selectedAddressLabel = val);
                                  },
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                controller: _emailController,
                                cursorColor: Colors.white,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                      width: 0.8,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 0.8,
                                    ),
                                  ),
                                  labelText: " Email* ",
                                  labelStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextField(
                                controller: _contactNumberController,
                                cursorColor: Colors.white,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                      width: 0.8,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 0.8,
                                    ),
                                  ),
                                  labelText: " Contact#* ",
                                  labelStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                            _buildPasswordField(
                              controller: _passwordController,
                              label: " Password* ",
                            ),
                            const SizedBox(height: 20),
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              label: " Confirm Password*",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: GestureDetector(
                onTap: () async {
                  setState(() {
                    firstName = _firstNameController.text;
                    middleName = _middleNameController.text;
                    lastName = _lastNameController.text;
                    businessName = _businessNameController.text;
                    postCode = _postCodeController.text;
                    clientEmail = _emailController.text;
                    address = _selectedAddressLabel.toString();
                    clientContact = _contactNumberController.text;
                    password = _passwordController.text;
                  });

                  formValidation();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset('assets/icons/ic_button.png'),
                    Text(
                      "Sign Up",
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: Text(
                    "Login",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAddresses() async {
    final postcode = _postCodeController.text
        .trim()
        .replaceAll(' ', '')
        .toUpperCase();

    if (postcode.isEmpty) return;

    setState(() {
      _isLoading = true;
      _availableAddresses = [];
      _selectedAddressLabel = null;
    });

    final url = Uri.parse(
      'https://api.openpostcodes.com/v1/postcodes/$postcode?api_key=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(
          utf8.decode(response.bodyBytes),
        );

        // OpenPostcodes status code 2000 means Success
        if (body['code'] == 2000 && body['result'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.blue,
              content: Text(
                "Post Code Found",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );

          _isLoading = false;

          final List<dynamic> results = body['result'];
          List<Map<String, dynamic>> tempParsed = [];

          for (var addr in results) {
            final String line1 = addr['line_1'] ?? '';
            final String line2 = addr['line_2'] ?? '';
            final String line3 = addr['line_3'] ?? '';
            final String town = addr['post_town'] ?? '';
            final String pc = addr['postcode'] ?? postcode;

            final String printableAddress = [
              line1,
              line2,
              line3,
              town,
              pc,
            ].where((line) => line.trim().isNotEmpty).join(', ');

            tempParsed.add({
              'line_1': line1,
              'line_2': line2,
              'line_3': line3,
              'town': town,
              'postcode': pc,
              'display_name': printableAddress,
            });
          }

          setState(() {
            _availableAddresses = tempParsed;
          });

          if (tempParsed.isEmpty) {
            _showSnackbar('No address found for this postcode.');
          }
        } else {
          _showSnackbar(body['message'] ?? 'Unable to find postcode.');
        }
      } else if (response.statusCode == 404) {
        _showSnackbar('Make sure post code is complete and correct');
      } else {
        _showSnackbar('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print("catch block: $e");
      _showSnackbar('Failed to connect to Open Postcodes.');
    } finally {
      if (mounted) {
        setState(() {
          address = _selectedAddressLabel!;
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        cursorColor: Colors.white,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 0.8),
          ),
          labelText: label,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                isObscure = !isObscure;
              });
            },
            icon: Icon(
              isObscure
                  ? Icons.lock
                  : Icons.no_encryption_gmailerrorred_rounded,
            ),
          ),
        ),
      ),
    );
  }
}
