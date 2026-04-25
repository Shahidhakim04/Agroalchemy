import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_alchemy_ui/config.dart';

class CropHealthAnalysisPage extends StatefulWidget {
  const CropHealthAnalysisPage({super.key});

  @override
  State<CropHealthAnalysisPage> createState() => _CropHealthAnalysisPageState();
}

class _CropHealthAnalysisPageState extends State<CropHealthAnalysisPage> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _cropsList = [
    'Arecanut',
    'Arhar/Tur',
    'Bajra',
    'Banana',
    'Barley',
    'Black pepper',
    'Cardamom',
    'Cashewnut',
    'Castor seed',
    'Coconut',
    'Coriander',
    'Cotton',
    'Cotton(lint)',
    'Cowpea(Lobia)',
    'Dry chillies',
    'Garlic',
    'Ginger',
    'Gram',
    'Grapes',
    'Groundnut',
    'Guar seed',
    'Horse-gram',
    'Jowar',
    'Jute',
    'Khesari',
    'Linseed',
    'Maize',
    'Masoor',
    'Mesta',
    'Moong',
    'Moong(Green Gram)',
    'Moth',
    'Niger seed',
    'Oilseeds total',
    'Onion',
    'Peas',
    'beans (Pulses)',
    'Potato',
    'Ragi',
    'Rapeseed',
    'Mustard',
    'Rice',
    'Safflower',
    'Sannhamp',
    'Sesamum',
    'Small millets',
    'Soybean',
    'Sugarcane',
    'Sunflower',
    'Sweet potato',
    'Tapioca',
    'Tobacco',
    'Tur',
    'Turmeric',
    'Urad',
    'Wheat',
  ];
  final List<String> _seasonsList = ['Rabi', 'Kharif', 'Summer', 'Whole Year', 'Winter'];
  
  // Form controllers
  String? _selectedCrop;
  String? _selectedSeason;
  final TextEditingController _cropYearController = TextEditingController();
  final TextEditingController _productionController = TextEditingController();
  final TextEditingController _fertilizerController = TextEditingController();

  // Server URL from config
  String get apiBaseUrl => AppConfig.instance.apiBaseUrl;

  // User data that will be fetched from Firestore
  double? _annualRainfall;
  double? _areaOfPlot;
  String? _state;

  // Results
  String _yieldResult = "";
  String _pesticideResult = "";
  bool _isLoading = false;
  bool _userDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _cropYearController.dispose();
    _productionController.dispose();
    _fertilizerController.dispose();
    super.dispose();
  }

  // Load user data from Firestore - keeping the same logic
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Get current user
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          setState(() {
            // Round to 2 decimal places when loading user data
            final rainfall =
                double.tryParse(userData['annualRainfall'].toString()) ?? 0.0;
            final area =
                double.tryParse(userData['areaOfPlot'].toString()) ?? 0.0;

            _annualRainfall = double.parse(rainfall.toStringAsFixed(2));
            _areaOfPlot = double.parse(area.toStringAsFixed(2));
            _state = userData['state'] ?? '';
            _userDataLoaded = true;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Format the yield value - keeping the same logic
  String _formatYieldValue(dynamic value) {
    if (value == null) return 'Not available';

    try {
      double doubleValue = double.parse(value.toString());
      return doubleValue.toStringAsFixed(2);
    } catch (e) {
      return value.toString();
    }
  }

  // Helper method to round double values - keeping the same logic
  double _roundToTwoDecimalPlaces(dynamic value) {
    if (value == null) return 0.0;

    try {
      double doubleValue = double.parse(value.toString());
      return double.parse(doubleValue.toStringAsFixed(2));
    } catch (e) {
      return 0.0;
    }
  }

  // Send prediction request to Flask API - keeping the same logic
  Future<void> _estimateYield() async {
    if (!_formKey.currentState!.validate() || !_userDataLoaded) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse and round all numeric values to 2 decimal places before sending
      final double rainfall = _roundToTwoDecimalPlaces(_annualRainfall);
      final double area = _roundToTwoDecimalPlaces(_areaOfPlot);
      final double fertilizer = _roundToTwoDecimalPlaces(
        _fertilizerController.text,
      );
      final double production = _roundToTwoDecimalPlaces(
        _productionController.text,
      );

      // Prepare request payload with rounded values
      final Map<String, dynamic> requestData = {
        'rainfall': rainfall,
        'area': area,
        'crop': _selectedCrop,
        'crop_year':
            int.tryParse(_cropYearController.text) ?? DateTime.now().year,
        'fertilizer': fertilizer,
        'season': _selectedSeason,
        'state': _state,
        'production': production,
        // Could add additional soil parameters in the future
      };

      // Debug log for request data
      debugPrint('Sending request with data: $requestData');

      // Make API request
      final response = await http.post(
        Uri.parse('$apiBaseUrl/predict/yield'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('API Response: $responseData');

        setState(() {
          _yieldResult = _formatYieldValue(
            responseData['yield_tons_per_hectare'],
          );
          _pesticideResult =
              responseData['recommended_pesticide']?.toString() ?? 'Not available';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${response.statusCode} - ${response.reasonPhrase}',
            ),
          ),
        );
      }
    } catch (e) {
      // Demo Mode Fallback
      setState(() {
        _yieldResult = "4.50 (Demo Result)";
        _pesticideResult = "Use Biocontrol Agents (Demo Result)";
      });
      
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network Error. Showing DEMO results.'),
            backgroundColor: Colors.orange,
          ),
        );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image and header
          Column(
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?q=80&w=1000',
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.4),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _formKey.currentState?.reset();
                                setState(() {
                                  _selectedCrop = null;
                                  _selectedSeason = null;
                                  _cropYearController.clear();
                                  _productionController.clear();
                                  _fertilizerController.clear();
                                  _yieldResult = "";
                                  _pesticideResult = "";
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Yield Estimation',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                          ),
                        ),
                        const Text(
                          'Recommendation',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(
                    0xFFF5F5F5,
                  ), // Light background for the form area
                ),
              ),
            ],
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 130), // Space for the header text
                  // Form Card with rounded corners
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child:
                        _isLoading && !_userDataLoaded
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF008F11),
                              ),
                            )
                            : Form(
                              key: _formKey,
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Enter Crop & Soil Details Section
                                    _buildSectionHeader(
                                      icon: Icons.eco,
                                      title: 'Enter Crop & Soil Details',
                                    ),
                                    const SizedBox(height: 20),

                                    // Crop dropdown with proper implementation
                                    _buildDropdownField(
                                      icon: Icons.grass,
                                      label: 'Crop',
                                      value: _selectedCrop,
                                      items: _cropsList,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCrop = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Season dropdown with proper implementation
                                    _buildDropdownField(
                                      icon: Icons.wb_sunny,
                                      label: 'Season',
                                      value: _selectedSeason,
                                      items: _seasonsList,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedSeason = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Existing year field
                                    _buildInputField(
                                      icon: Icons.calendar_today,
                                      label: 'Crop Year',
                                      controller: _cropYearController,
                                      keyboardType: TextInputType.number,
                                    ),

                                    const SizedBox(height: 24),
                                    const Divider(),
                                    const SizedBox(height: 20),

                                    // Farm Information - using original fields but with enhanced UI
                                    _buildSectionHeader(
                                      title: 'Farm Information',
                                      showIcon: false,
                                    ),
                                    const SizedBox(height: 20),

                                    // Display existing user data in a nice format
                                    _buildInfoTile(
                                      icon: Icons.water_drop,
                                      label: 'Annual Rainfall',
                                      value:
                                          '${_annualRainfall ?? 'Loading...'} mm',
                                    ),
                                    const SizedBox(height: 12),

                                    _buildInfoTile(
                                      icon: Icons.agriculture,
                                      label: 'Area of Plot',
                                      value:
                                          '${_areaOfPlot ?? 'Loading...'} hectare',
                                    ),
                                    const SizedBox(height: 12),

                                    _buildInfoTile(
                                      icon: Icons.location_on,
                                      label: 'State',
                                      value: _state ?? 'Loading...',
                                    ),

                                    const SizedBox(height: 24),
                                    const Divider(),
                                    const SizedBox(height: 20),

                                    // Additional input fields - using original fields
                                    _buildSectionHeader(
                                      title: 'Production Details',
                                      showIcon: false,
                                    ),
                                    const SizedBox(height: 20),

                                    _buildInputField(
                                      icon: Icons.agriculture,
                                      label: 'Production (tonnes)',
                                      controller: _productionController,
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 16),

                                    _buildInputField(
                                      icon: Icons.science,
                                      label: 'Fertilizer used (kg)',
                                      controller: _fertilizerController,
                                      keyboardType: TextInputType.number,
                                    ),

                                    const SizedBox(height: 30),

                                    // Submit button - Full width and styled like the image
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _estimateYield,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF008F11,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                          ),
                                          elevation: 3,
                                        ),
                                        child: Text(
                                          _isLoading
                                              ? "Processing..."
                                              : "GET RECOMMENDATION",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Results display
                                    if (_yieldResult.isNotEmpty ||
                                        _pesticideResult.isNotEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF008F11),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Recommendation Results:",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF008F11),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            _buildResultItem(
                                              icon: Icons.agriculture,
                                              label: "Estimated Yield",
                                              value:
                                                  "$_yieldResult tonnes/hectare",
                                            ),
                                            const SizedBox(height: 8),
                                            _buildResultItem(
                                              icon: Icons.science,
                                              label: "Recommended Pesticide",
                                              value: _pesticideResult,
                                            ),
                                          ],
                                        ),
                                      ),

                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section header with optional icon
  Widget _buildSectionHeader({
    required String title,
    IconData? icon,
    bool showIcon = true,
  }) {
    return Row(
      children: [
        if (showIcon && icon != null) ...[
          Icon(icon, color: const Color(0xFF008F11), size: 24),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF008F11),
          ),
        ),
      ],
    );
  }

  // Info tile for read-only information
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF008F11).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF008F11), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dropdown field with icon - Updated implementation with proper dropdown
  Widget _buildDropdownField({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF008F11).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF008F11), size: 20),
            ),
            border: InputBorder.none,
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          icon: const Icon(
            Icons.arrow_drop_down_circle,
            color: Color(0xFF008F11),
          ),
          isExpanded: true,
          hint: Text('Select $label'),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select $label';
            }
            return null;
          },
        ),
      ),
    );
  }

  // Styled input field
  Widget _buildInputField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF008F11).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF008F11), size: 20),
            ),
            border: InputBorder.none,
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            helperText: helperText,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ),
    );
  }

  // Result item with icon
  Widget _buildResultItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF008F11).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF008F11), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}