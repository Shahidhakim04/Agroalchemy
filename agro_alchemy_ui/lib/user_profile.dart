import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:agro_alchemy_ui/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:agro_alchemy_ui/locale_provider.dart';
import 'package:provider/provider.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = true;
  late final String _userId;
  
  // Theme colors
  final Color _primaryColor = const Color(0xFF115740);
  final Color _secondaryColor = const Color(0xFF4CAF50);
  final Color _accentColor = const Color(0xFF8BC34A);
  final Color _backgroundColor = const Color(0xFFF9F9F9);
  final Color _cardColor = Colors.white;
  
  // Animation controllers
  late AnimationController _pageLoadController;
  late Animation<double> _pageLoadAnimation;
  
  late AnimationController _editSaveController;
  late Animation<double> _editSaveAnimation;
  
  late AnimationController _formFieldController;
  late Animation<double> _formFieldAnimation;
  
  // User profile data
  String _displayName = '';
  String _email = '';
  String _phone = '';
  String _photoUrl = '';
  String _annualRainfall = '';
  String _plotArea = '';
  String _state = '';
  String _city = '';

  // Focus nodes
  final _displayNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _rainfallFocus = FocusNode();
  final _plotAreaFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _cityFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // Page load animation
    _pageLoadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _pageLoadAnimation = CurvedAnimation(
      parent: _pageLoadController,
      curve: Curves.easeOutQuint,
    );
    
    // Edit/Save button animation
    _editSaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _editSaveAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _editSaveController, curve: Curves.elasticOut),
    );
    
    // Form field animation
    _formFieldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _formFieldAnimation = CurvedAnimation(
      parent: _formFieldController,
      curve: Curves.easeInOut,
    );
    
    _loadUserData();
    
    // Start animations after load
    _pageLoadController.forward();
  }

  @override
  void dispose() {
    _pageLoadController.dispose();
    _editSaveController.dispose();
    _formFieldController.dispose();
    _displayNameFocus.dispose();
    _phoneFocus.dispose();
    _rainfallFocus.dispose();
    _plotAreaFocus.dispose();
    _stateFocus.dispose();
    _cityFocus.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First check Firebase Auth for Google account info
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _photoUrl = currentUser.photoURL ?? '';
        _email = currentUser.email ?? '';
        
        // If user signed in with Google, display name might be available
        if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
          _displayName = currentUser.displayName!;
        }
      }

      // Then load additional data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          // Only update displayName if it's not already set from Google auth
          if (_displayName.isEmpty) {
            _displayName = userData['displayName'] ?? '';
          }
          
          // Only update email if it's not already set from Google auth
          if (_email.isEmpty) {
            _email = userData['email'] ?? '';
          }
          
          _phone = userData['phone'] ?? '';
          
          // Only update photo URL if it's not already set from Google auth
          if (_photoUrl.isEmpty) {
            _photoUrl = userData['photoURL'] ?? '';
          }
          
          _annualRainfall = userData['annualRainfall'] ?? '';
          _plotArea = userData['areaOfPlot'] ?? '';
          _state = userData['state'] ?? '';
          _city = userData['city'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar(AppLocalizations.of(context)!.errorLoadingProfile);
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar("Network slow. Loading local data if available.");
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(AppLocalizations.of(context)!.errorLoadingProfile);
      }
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'displayName': _displayName,
        'phone': _phone,
        'annualRainfall': _annualRainfall,
        'areaOfPlot': _plotArea,
        'state': _state,
        'city': _city,
        'email': _email,
        'photoURL': _photoUrl,
      }).timeout(const Duration(seconds: 5));

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      _formFieldController.reverse();
      _showSnackBar(AppLocalizations.of(context)!.profileUpdated);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (e.toString().contains('TimeoutException')) {
        // Handle timeout as success (saved locally, will sync later)
        setState(() {
          _isEditing = false;
        });
        _formFieldController.reverse();
        _showSnackBar("Profile saved locally. Syncing when online.");
      } else {
        _showSnackBar('Error saving profile: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: _primaryColor,
        duration: const Duration(seconds: 3),
        elevation: 8,
        margin: EdgeInsets.all(10),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.ok,
          onPressed: () {},
          textColor: Colors.white,
        ),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
    
    if (_isEditing) {
      _formFieldController.forward();
      _editSaveController.forward().then((_) => _editSaveController.reverse());
    } else {
      _formFieldController.reverse();
      _editSaveController.forward().then((_) => _editSaveController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLangCode = localeProvider.locale?.languageCode ?? 'en';
    final loc = AppLocalizations.of(context)!;
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusColor: _secondaryColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(color: Colors.white),
          actions: [
            if (!_isEditing)
              AnimatedBuilder(
                animation: _pageLoadAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(30 * (1 - _pageLoadAnimation.value), 0),
                    child: Opacity(
                      opacity: _pageLoadAnimation.value,
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        tooltip: loc.logout,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingView()
            : FadeTransition(
                opacity: _pageLoadAnimation,
                child: Stack(
                  children: [
                    _buildHeaderBackground(),
                    SafeArea(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 100),
                                _buildProfileHeader(),
                                const SizedBox(height: 24),
                                _buildProfileBody(),
                                const SizedBox(height: 32),
ListTile(
  leading: Icon(Icons.language),
  title: Text(loc.language),
  subtitle: Text(
    currentLangCode == 'en'
        ? loc.english
        : currentLangCode == 'hi'
            ? loc.hindi
            : currentLangCode == 'mr'
                ? loc.marathi
                : loc.english,
  ),
  onTap: () {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            {'code': 'en', 'label': loc.english},
            {'code': 'hi', 'label': loc.hindi},
            {'code': 'mr', 'label': loc.marathi},
          ].map((lang) {
            return ListTile(
              title: Text(lang['label']!),
              onTap: () {
                localeProvider.setLocale(Locale(lang['code']!));
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  },
),
                                _buildActionButtons(),
                                const SizedBox(height: 24),
                              ],
                            ),
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

  Widget _buildLoadingView() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryColor.withOpacity(0.9),
            _secondaryColor.withOpacity(0.9),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 5,
                    ),
                  ),
                  Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 50,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              loc.loadingProfile,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 200,
              child: Shimmer.fromColors(
                baseColor: Colors.white.withOpacity(0.5),
                highlightColor: Colors.white,
                child: Container(
                  height: 8,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryColor,
            _secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            spreadRadius: 5,
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: PatternPainter(),
              ),
            ),
          ),
          // Gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _primaryColor.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.profile,  
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return AnimatedBuilder(
      animation: _pageLoadAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _pageLoadAnimation.value)),
          child: Opacity(
            opacity: _pageLoadAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _secondaryColor,
                          _accentColor,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _secondaryColor.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Hero(
                      tag: 'profile-image',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: ClipOval(
                          child: _photoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: _photoUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.withOpacity(0.3),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: _secondaryColor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => 
                                    _buildProfilePlaceholder(),
                                )
                              : _buildProfilePlaceholder(),
                        ),
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            _showSnackBar('Image upload functionality would be implemented here');
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _primaryColor,
                                  _secondaryColor,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                )
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _displayName.isNotEmpty ? _displayName : AppLocalizations.of(context)!.updateProfile,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              if (_email.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: _primaryColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _email,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (_state.isNotEmpty && _city.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: _primaryColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$_city, $_state",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.person,
          size: 60,
          color: _primaryColor.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildProfileBody() {
    final loc = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _pageLoadAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 70 * (1 - _pageLoadAnimation.value)),
          child: Opacity(
            opacity: _pageLoadAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loc.personalInfo,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                loc.yourBasicProfileDetails,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(
                  color: Colors.grey.shade200,
                  thickness: 1,
                ),
              ),
              _isEditing ? _buildEditableForm() : _buildViewOnlyProfile(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final loc = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _pageLoadAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 90 * (1 - _pageLoadAnimation.value)),
          child: Opacity(
            opacity: _pageLoadAnimation.value,
            child: child,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _editSaveAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _editSaveAnimation.value,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryColor,
                    _secondaryColor,
                  ],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  _editSaveController.forward().then((_) => _editSaveController.reverse());
                  if (_isEditing) {
                    _saveUserData();
                  } else {
                    _toggleEditMode();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isEditing ? Icons.save_outlined : Icons.edit_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isEditing ? loc.saveProfile : loc.editProfile,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewOnlyProfile() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        _infoTile(loc.name, _displayName, Icons.person_outline),
        _infoTile(loc.email, _email, Icons.email_outlined),
        _infoTile(loc.phone, _phone, Icons.phone_outlined),
        if (_annualRainfall.isNotEmpty)
          _infoTile(loc.annualRainfall, "${_annualRainfall} mm", Icons.water_drop_outlined),
        if (_plotArea.isNotEmpty)
          _infoTile(loc.areaOfPlot, "${_plotArea} sq.m", Icons.landscape_outlined),
        if (_state.isNotEmpty)
          _infoTile(loc.state, _state, Icons.location_city_outlined),
        if (_city.isNotEmpty)
          _infoTile(loc.city, _city, Icons.location_on_outlined),
      ],
    );
  }

  Widget _buildEditableForm() {
    final loc = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _formFieldAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _formFieldAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _formFieldAnimation.value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          _buildFloatingLabelField(
            label: loc.name,
            value: _displayName,
            onChanged: (value) => _displayName = value,
            icon: Icons.person_outline,
            focusNode: _displayNameFocus,
            nextFocus: _phoneFocus,
          ),
          _buildReadOnlyFormField(
            label: loc.email,
            value: _email,
            icon: Icons.email_outlined,
          ),
          _buildFloatingLabelField(
            label: loc.phone,
            value: _phone,
            onChanged: (value) => _phone = value,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            focusNode: _phoneFocus,
            nextFocus: _rainfallFocus,
          ),
          _buildFloatingLabelField(
            label: loc.annualRainfall,
            value: _annualRainfall,
            onChanged: (value) => _annualRainfall = value,
            icon: Icons.water_drop_outlined,
            keyboardType: TextInputType.number,
            focusNode: _rainfallFocus,
            nextFocus: _plotAreaFocus,
          ),
          _buildFloatingLabelField(
            label: loc.areaOfPlot,
            value: _plotArea,
            onChanged: (value) => _plotArea = value,
            icon: Icons.landscape_outlined,
            keyboardType: TextInputType.number,
            focusNode: _plotAreaFocus,
            nextFocus: _stateFocus,
          ),
          _buildFloatingLabelField(
            label: loc.state,
            value: _state,
            onChanged: (value) => _state = value,
            icon: Icons.location_city_outlined,
            focusNode: _stateFocus,
            nextFocus: _cityFocus,
          ),
          _buildFloatingLabelField(
            label: loc.city,
            value: _city,
            onChanged: (value) => _city = value,
            icon: Icons.location_on_outlined,
            focusNode: _cityFocus,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value.isEmpty ? AppLocalizations.of(context)!.notSet : value,
                  style: GoogleFonts.poppins(
                    fontWeight: value.isEmpty ? FontWeight.normal : FontWeight.w500,
                    color: value.isEmpty ? Colors.black38 : Colors.black87,
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

  Widget _buildReadOnlyFormField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.shade100,
      ),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.black54,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: _primaryColor,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: _primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }

  Widget _buildFloatingLabelField({
    required String label,
    required String value,
    required Function(String) onChanged,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
    FocusNode? nextFocus,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        focusNode: focusNode,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: _primaryColor,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: _primaryColor),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _secondaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade300, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          }
        },
        validator: (value) {
          if (label == AppLocalizations.of(context)!.name && (value == null || value.isEmpty)) {
            return AppLocalizations.of(context)!.nameRequired;
          }
          return null;
        },
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Create a pattern of small circles and shapes
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    const circleRadius = 3.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Draw small circles in a grid pattern
        canvas.drawCircle(Offset(x, y), circleRadius, paint);
      }
    }
    
    // Add some larger decorative elements
    final decorPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 20, decorPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 15, decorPaint);
    
    // Draw some random triangles
    final trianglePath1 = Path();
    trianglePath1.moveTo(size.width * 0.1, size.height * 0.5);
    trianglePath1.lineTo(size.width * 0.2, size.height * 0.4);
    trianglePath1.lineTo(size.width * 0.15, size.height * 0.7);
    trianglePath1.close();
    
    final trianglePath2 = Path();
    trianglePath2.moveTo(size.width * 0.75, size.height * 0.2);
    trianglePath2.lineTo(size.width * 0.9, size.height * 0.3);
    trianglePath2.lineTo(size.width * 0.85, size.height * 0.1);
    trianglePath2.close();
    
    canvas.drawPath(trianglePath1, decorPaint);
    canvas.drawPath(trianglePath2, decorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}