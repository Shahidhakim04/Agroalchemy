import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:agro_alchemy_ui/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:agro_alchemy_ui/config.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class PestManagementPage extends StatefulWidget {
  const PestManagementPage({super.key});

  @override
  State<PestManagementPage> createState() => _PestManagementPageState();
}

class _PestManagementPageState extends State<PestManagementPage> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  XFile? _pickedFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  String _diseaseName = "";
  String _treatment = "";
  String _errorMessage = "";
  bool _showResults = false;
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  
  String get apiBaseUrl => AppConfig.instance.apiBaseUrl;

  // Additional disease details
  final Map<String, Color> _severityColors = {
    'Low': Colors.green.shade300,
    'Medium': Colors.orange.shade300,
    'High': Colors.red.shade300
  };
  
  String _severity = "Medium";
  List<String> _preventionTips = [];
  List<Map<String, String>> _similarDiseases = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Set system UI overlay style for immersive experience
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    // Sample prevention tips for demo purposes
    // Delay localization loading until the widget is fully built
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setState(() {
      // Now it's safe to use context to get localized strings
      _preventionTips = [
        AppLocalizations.of(context)!.tip_one,
        AppLocalizations.of(context)!.tip_two,
        AppLocalizations.of(context)!.tip_three,
        AppLocalizations.of(context)!.tip_four,
      ];
    });
    });
    
    // Sample similar diseases for demo purposes
    _similarDiseases = [
      {
        "name": "Early Blight",
        "similarity": "87%"
      },
      {
        "name": "Septoria Leaf Spot",
        "similarity": "62%"
      }
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _pickedFile = pickedFile;
            _diseaseName = "";
            _treatment = "";
            _errorMessage = "";
            _showResults = false;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
            _pickedFile = pickedFile;
            _diseaseName = "";
            _treatment = "";
            _errorMessage = "";
            _showResults = false;
          });
        }
        
        // Subtle haptic feedback to confirm selection
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error accessing image: $e";
      });
    }
  }

  Future<void> _identifyDisease() async {
    if (_pickedFile == null) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pleaseSelectImageFirst;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
      _showResults = false;
    });

    try {
      _animationController.repeat();
      
      // Create multipart request with the correct endpoint
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$apiBaseUrl/predict/disease')
      );
      
      // Add file to request
      if (kIsWeb) {
        var multipartFile = http.MultipartFile.fromBytes(
          'image',
          _webImageBytes!,
          filename: 'leaf_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      } else {
        var fileStream = http.ByteStream(_imageFile!.openRead());
        var fileLength = await _imageFile!.length();
        
        var multipartFile = http.MultipartFile(
          'image',
          fileStream,
          fileLength,
          filename: 'leaf_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          _diseaseName = jsonResponse['disease'] ?? "Unknown disease";
          // If your API returns treatment info, capture it here
          _treatment = jsonResponse['treatment'] ?? 
                      "Consult with an agricultural expert for appropriate treatment options.";
          
          // Use severity from API response
          _severity = jsonResponse['severity'] ?? "Medium";
          
          _isLoading = false;
          _showResults = true;
        });
        
        // Scroll to results after a short delay to allow animations to complete
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuint,
            );
          }
        });
      } else {
        setState(() {
          _errorMessage = "Server error: ${response.statusCode}\n${response.body}";
          _isLoading = false;
        });
      }
    } catch (e) {
      // Demo mode fallback
      setState(() {
        _diseaseName = "Leaf Blight (Demo Result)";
        _treatment = "Apply fungicide every 10-14 days. Ensure good air circulation (Demo Advice).";
        _severity = "Medium";
        _isLoading = false;
        _showResults = true;
        _errorMessage = "Network Error: Switched to Demo Mode";
      });
      
      // Scroll to results
         Future.delayed(const Duration(milliseconds: 500), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuint,
            );
          }
        });
    } finally {
      _animationController.stop();
      _animationController.reset();
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.chooseAnOption,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSourceOption(
                icon: Icons.camera_alt_rounded,
                title: AppLocalizations.of(context)!.takePhoto,
                subtitle: AppLocalizations.of(context)!.takePhotoSubtitle,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 16),
              _buildSourceOption(
                icon: Icons.photo_library_rounded,
                title: AppLocalizations.of(context)!.chooseFromGallery,
                subtitle: AppLocalizations.of(context)!.chooseFromGallerySubtitle,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2E7D32),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
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
              const Color(0xFF2E7D32), 
              const Color(0xFF1B5E20).withOpacity(0.9), 
              Colors.white
            ],
            stops: const [0.0, 0.3, 0.5],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    loc.plantDiseaseIdentifierTitle,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2E7D32),
                          const Color(0xFF1B5E20).withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    onPressed: () {
                      // Show info dialog
                      _showInfoDialog();
                    },
                  ),
                ],
              ),
              
              // Main Content
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Header text
                    if (_pickedFile == null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24, top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.identifyPlantDiseasesHeader,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              loc.identifyPlantDiseasesDescription,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                    // Animated image upload card
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _pickedFile == null
                          ? _buildUploadCard()
                          : _buildImagePreviewCard(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Image Selection Button
                    if (_pickedFile == null)
                      _buildSelectImageButton(),
                      
                    // Action Row when image is selected
                    if (_pickedFile != null)
                      _buildActionRow(),
                    
                    const SizedBox(height: 16),
                    
                    // Error message
                    if (_errorMessage.isNotEmpty)
                      _buildErrorCard(),
                      
                    // Results section
                    if (_showResults)
                      _buildResultsSection(),
                      
                    // Empty space at bottom for scrolling
                    if (_showResults)
                      const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _pickedFile != null && !_showResults && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _identifyDisease,
              backgroundColor: const Color(0xFF388E3C),
              icon: const Icon(Icons.biotech_rounded),
              label:  Text(loc.analyzeLeaf),
              elevation: 4,
            )
          : null,
    );
  }
  
  Widget _buildUploadCard() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey('upload'),
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation would go here in a real app
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_enhance_rounded,
              size: 50,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            loc.uploadLeafImage,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              loc.uploadLeafImageHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImagePreviewCard() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey('preview'),
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: kIsWeb
                ? Image.memory(
                    _webImageBytes!,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  ),
          ),
          
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.7, 1.0],
              ),
            ),
          ),
          
          // Bottom text
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.readyToAnalyze,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.tapAnalyzeToIdentify,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // Change image button
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _showImageSourceDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSelectImageButton() {
    final loc = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _showImageSourceDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.black26,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_rounded, size: 24),
            const SizedBox(width: 12),
            Text(
              loc.selectLeafImage,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionRow() {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        // Change image button
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: _showImageSourceDialog,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_rounded,
                    size:0,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.change,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Analyze button
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _identifyDisease,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white.withOpacity(0.8),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          loc.analyzing,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.biotech_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          loc.analyzeLeaf,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
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
  
  Widget _buildErrorCard() {
     final loc = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.errorOccurred,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.red[800],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage,
                  style: GoogleFonts.poppins(
                    color: Colors.red[800],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsSection() {
     final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                loc.analysisComplete,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        
        // Main results card
        _buildDiseaseCard(),
        
        const SizedBox(height: 20),
        
        // Treatment card
        _buildTreatmentCard(),
        
        const SizedBox(height: 20),
        
        // Prevention tips card
        _buildPreventionCard(),
        
        const SizedBox(height: 20),
        
        // Similar diseases
        _buildSimilarDiseasesCard(),
      ],
    );
  }
  
  Widget _buildDiseaseCard() {
     final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Disease image - using the uploaded image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 180,
              child: kIsWeb
                  ? Image.memory(
                      _webImageBytes!,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          
          // Disease name and severity
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Diagnosis label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    loc.diagnosis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Disease name
                Text(
                  _diseaseName,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Severity indicator
                Row(
                  children: [
                    Text(
                      loc.severity,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _severityColors[_severity]!.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _severity == "Low" 
                                ? Icons.check_circle_outline
                                : _severity == "Medium"
                                    ? Icons.warning_amber_rounded
                                    : Icons.error_outline,
                            color: _severityColors[_severity],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _severity,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _severityColors[_severity],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTreatmentCard() {
     final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Treatment header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.healing_rounded,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                loc.recommendedTreatment,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Treatment text
          Text(
            _treatment,
            style: GoogleFonts.poppins(
              fontSize:15,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreventionCard() {
     final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prevention header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                loc.preventionTips,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Prevention tips list
          ..._preventionTips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: const Color(0xFF4CAF50),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildSimilarDiseasesCard() {
     final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Similar diseases header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.compare_rounded,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                loc.similarDiseases,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Similar diseases list
          ..._similarDiseases.map((disease) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bug_report_outlined,
                  color: Color(0xFF5D4037),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    disease["name"]!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D4037).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    disease["similarity"]!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5D4037),
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          // View all button if there are many diseases
          if (_similarDiseases.length > 3)
            Padding(
              padding: const EdgeInsets.only(top:8),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // View all similar diseases
                  },
                  child: Text(
                    loc.viewAllSimilarDiseases,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppLocalizations.of(context)!.aboutPlantDiseaseIdentifier,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.aboutPlantDiseaseIdentifierDescription,
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.brightness_7_rounded,
              text: AppLocalizations.of(context)!.infoUseWellLitImages,
            ),
            _buildInfoItem(
              icon: Icons.crop_free_rounded,
              text: AppLocalizations.of(context)!.infoAffectedAreaVisible,
            ),
            _buildInfoItem(
              icon: Icons.photo_size_select_actual_rounded,
              text: AppLocalizations.of(context)!.infoCloseUpShots,
            ),
            _buildInfoItem(
              icon: Icons.warning_amber_rounded,
              text: AppLocalizations.of(context)!.infoConsultExpert,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context)!.gotIt,
              style: GoogleFonts.poppins(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}