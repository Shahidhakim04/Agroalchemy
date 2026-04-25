import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:agro_alchemy_ui/config.dart';
import 'package:agro_alchemy_ui/flutter_gen/gen_l10n/app_localizations.dart';

class FertilizerPredictionPage extends StatefulWidget {
  const FertilizerPredictionPage({super.key});

  @override
  State<FertilizerPredictionPage> createState() => _FertilizerPredictionPageState();
}

class _FertilizerPredictionPageState extends State<FertilizerPredictionPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Define dropdowns options
  final List<String> _districts = ['Kolhapur', 'Pune', 'Solapur', 'Satara', 'Sangli'];
  final List<String> _soilColors = ['Black', 'Red', 'Medium Brown', 'Dark Brown', 'Light Brown', 'Reddish Brown'];
  final List<String> _cropsList = [
    'Cotton','Ginger','Gram','Grapes','Groundnut','Jowar','Jowar','Maize','Masoor','Moong','Rice','Soybean','Sugarcane','Tur','Turmeric','Urad','Wheat'
  ];
  
  // Selected values for dropdowns
  String? _selectedDistrict;
  String? _selectedSoilColor;
  String? _selectedCrop;
  
  // Controllers for each text field
  final _nitrogenController = TextEditingController();
  final _potassiumController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _phController = TextEditingController();
  final _rainfallController = TextEditingController();
  final _temperatureController = TextEditingController();
  
  // Animation controller (kept for managing animations if needed)
  late AnimationController _animationController;
  
  // UI state
  String _recommendedFertilizer = "No prediction yet";
  bool _isLoading = false;
  bool _showResult = false;
  String _errorMessage = "";
  
  // API configuration
  String get apiBaseUrl => AppConfig.instance.apiBaseUrl;
  String? authToken;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _nitrogenController.dispose();
    _potassiumController.dispose();
    _phosphorusController.dispose();
    _phController.dispose();
    _rainfallController.dispose();
    _temperatureController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _predictFertilizer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
      _showResult = false;
    });

    try {
      // Prepare request payload
      final Map<String, dynamic> requestData = {
        "district_name": _selectedDistrict,
        "soil_color": _selectedSoilColor,
        "nitrogen": int.parse(_nitrogenController.text.trim()),
        "phosphorus": int.parse(_phosphorusController.text.trim()),
        "potassium": int.parse(_potassiumController.text.trim()),
        "ph": double.parse(_phController.text.trim()),
        "rainfall": double.parse(_rainfallController.text.trim()),
        "temperature": double.parse(_temperatureController.text.trim()),
        "crop": _selectedCrop
      };

      // Create headers map
      final headers = {
        'Content-Type': 'application/json',
      };
      
      // Add auth token if available
      if (authToken != null) {
        headers['X-Auth-Token'] = authToken!;
      }

      // Send POST request to Flask endpoint
      final response = await http.post(
        Uri.parse('$apiBaseUrl/predict/fertilizer'),
        headers: headers,
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _recommendedFertilizer = responseData['fertilizer'] ?? 
              "No specific fertilizer recommended";
          _isLoading = false;
          _showResult = true;
        });
        
        // Animation trigger (optional)
        _animationController.reset();
        _animationController.forward();
        
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.authenticationRequired;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Server error: ${response.statusCode}";
          try {
            final errorData = jsonDecode(response.body);
            if (errorData['error'] != null) {
              _errorMessage += " - ${errorData['error']}";
            }
          } catch (_) {}
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to demo mode for presentation purposes
      setState(() {
        _recommendedFertilizer = "Urea: 50kg/ha, DAP: 25kg/ha (Demo Result)";
        _errorMessage = "Network Error: Switched to Demo Mode";
        _isLoading = false;
        _showResult = true;
      });
      
      _animationController.reset();
      _animationController.forward();
    }
  }

  String? _validateNumericField(String? value, String fieldName, {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    try {
      final numValue = double.parse(value.trim());
      
      if (min != null && numValue < min) {
        return '$fieldName should be at least $min';
      }
      
      if (max != null && numValue > max) {
        return '$fieldName should not exceed $max';
      }
      
      return null;
    } catch (e) {
      return '${AppLocalizations.of(context)!.validNumber} $fieldName';
    }
  }

  void _resetForm() {
    setState(() {
      _selectedDistrict = null;
      _selectedSoilColor = null;
      _selectedCrop = null;
      _nitrogenController.clear();
      _potassiumController.clear();
      _phosphorusController.clear();
      _phController.clear();
      _rainfallController.clear();
      _temperatureController.clear();
      _showResult = false;
      _errorMessage = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[50]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1B5E20),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    loc.fertilizerPredictionTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        "https://images.unsplash.com/photo-1464226184884-fa280b87c399",
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: loc.resetForm,
                    onPressed: _resetForm,
                  ),
                ],
              ),
              
              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                children: [
                                  const Icon(FontAwesomeIcons.leaf, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 12),
                                  Text(
                                    loc.enterCropSoilDetails,
                                    style: TextStyle(
                                      fontSize: 20, 
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // District Dropdown
                            _buildDropdownField(
                              label: loc.district,
                              icon: Icons.location_city,
                              value: _selectedDistrict,
                              items: _districts.map((district) {
                                return DropdownMenuItem<String>(
                                  value: district,
                                  child: Text(district),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDistrict = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return loc.selectDistrict;
                                }
                                return null;
                              },
                            ),
                            
                            // Soil Color Dropdown
                            _buildDropdownField(
                              label: loc.soilColor,
                              icon: FontAwesomeIcons.palette,
                              value: _selectedSoilColor,
                              items: _soilColors.map((color) {
                                return DropdownMenuItem<String>(
                                  value: color,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: _getSoilColor(color),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(color),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSoilColor = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return loc.selectSoilColor;
                                }
                                return null;
                              },
                            ),
                            
                            // Crop Dropdown (replaced TypeAhead with standard dropdown)
                            _buildDropdownField(
                              label:loc.crop,
                              icon: FontAwesomeIcons.seedling,
                              value: _selectedCrop,
                              items: _cropsList.map((crop) {
                                return DropdownMenuItem<String>(
                                  value: crop,
                                  child: Text(crop),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCrop = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return loc.selectCrop;
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 10),
                            
                            // Soil Parameters Section
                            Text(
                              loc.soilParameters,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 15),
                            
                            // Row for NPK values
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    controller: _nitrogenController,
                                    label:loc.nutrientNitrogen,
                                    icon: FontAwesomeIcons.n,
                                    keyboardType: TextInputType.number,
                                    validator: (value) => _validateNumericField(value, loc.nutrientNitrogen, min: 0, max: 200),
                                    helperText: "kg/ha",
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    controller: _phosphorusController,
                                    label: loc.nutrientPhosphorus,
                                    icon: FontAwesomeIcons.p,
                                    keyboardType: TextInputType.number,
                                    validator: (value) => _validateNumericField(value, loc.nutrientPhosphorus, min: 0, max: 200),
                                    helperText: "kg/ha",
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    controller: _potassiumController,
                                    label: loc.nutrientPotassium,
                                    icon: FontAwesomeIcons.k,
                                    keyboardType: TextInputType.number,
                                    validator: (value) => _validateNumericField(value, loc.nutrientPotassium, min: 0, max: 200),
                                    helperText: "kg/ha",
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 10),
                            
                            // pH Input
                            _buildInputField(
                              controller: _phController,
                              label: loc.phLevel,
                              icon: FontAwesomeIcons.water,
                              keyboardType: TextInputType.number,
                              validator: (value) => _validateNumericField(value, loc.ph, min: 0, max: 14),
                              helperText: "Range: 0-14",
                            ),
                            
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 10),
                            
                            // Environmental Parameters Section
                             Text(
                              loc.environmentalParameters,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 15),
                            
                            // Row for environmental parameters
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    controller: _rainfallController,
                                    label: loc.rainfall,
                                    icon: FontAwesomeIcons.cloudRain,
                                    keyboardType: TextInputType.number,
                                    validator: (value) => _validateNumericField(value, loc.rainfall, min: 0),
                                    helperText: "mm",
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    controller: _temperatureController,
                                    label: loc.temperature,
                                    icon: FontAwesomeIcons.temperatureHalf,
                                    keyboardType: TextInputType.number,
                                    validator: (value) => _validateNumericField(value,loc.temperature),
                                    helperText: "°C",
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // Submit Button
                            Center(
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Color(0xFF2E7D32))
                                : ElevatedButton.icon(
                                    onPressed: _predictFertilizer,
                                    icon: const Icon(Icons.agriculture),
                                    label: Text(
                                      loc.getFertilizerRecommendation,
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 5,
                                    ),
                                  ),
                            ),
                            
                            // Error message
                            if (_errorMessage.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Results Section (replaced Lottie with static UI)
              if (_showResult) SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: const Color(0xFF1B5E20),
                    child: Column(
                      children: [
                        // Static header instead of animation
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            color: const Color(0xFF2E7D32),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    loc.analysisComplete,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Result card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.recommendedFertilizer,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF81C784)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      FontAwesomeIcons.flask,
                                      color: Color(0xFF2E7D32),
                                      size: 36,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _recommendedFertilizer,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "For ${_selectedCrop ?? 'your crop'} in ${_selectedDistrict ?? 'your region'}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              const Divider(),
                              const SizedBox(height: 15),
                              Text(
                                loc.applicationGuidelines,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildGuidelineItem(
                                icon: FontAwesomeIcons.calendarCheck,
                                title: loc.timing,
                                description: loc.timingDesc,
                              ),
                              _buildGuidelineItem(
                                icon: FontAwesomeIcons.handHoldingDroplet,
                                title: loc.method,
                                description: loc.methodDesc,
                              ),
                              _buildGuidelineItem(
                                icon: FontAwesomeIcons.triangleExclamation,
                                title: loc.caution,
                                description: loc.cautionDesc,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer Section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: const Text(
                    "© 2025 AgroAlchemy - Smart Fertilizer Recommendations",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label, 
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    String? Function(T?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFF2E7D32)),
        isExpanded: true,
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get color representation for soil colors
  Color _getSoilColor(String colorName) {
    switch (colorName) {
      case 'Black':
        return Colors.black87;
      case 'Red':
        return Colors.red[900]!;
      case 'Medium Brown':
        return const Color(0xFF8B4513);
      case 'Dark Brown':
        return const Color(0xFF5D4037);
      case 'Light Brown':
        return const Color(0xFFA1887F);
      case 'Reddish Brown':
        return const Color(0xFF8D6E63);
      default:
        return Colors.brown;
    }
  }
}