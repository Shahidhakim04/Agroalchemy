import 'package:agro_alchemy_ui/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // For implementing cooldown periods

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  TextEditingController _messageController = TextEditingController();
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  String _userType = "farmer"; // Default user role
  bool _hasSentFirstMessage = false;
  String _roleGreeting = "Welcome to FarmAssist! How can I help with your farming questions today?";
  bool _isTyping = false; // Track if the AI is "typing"

  // Gemini API configuration (key from .env: GEMINI_API_KEY)
  String get _geminiApiKey => AppConfig.instance.geminiApiKey;
  final String _geminiApiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";

  // API rate limiting variables
  DateTime _lastApiCall = DateTime.now().subtract(Duration(minutes: 1));
  int _apiCallsInLastMinute = 0;
  int _maxCallsPerMinute = 5; // Adjust based on your API limits
  bool _isRateLimited = false;
  Timer? _rateLimitTimer;

  // Fallback settings for handling API issues
  bool _useLocalFallback = false; // Set to true to use local responses when API fails
  int _errorCount = 0; // Track consecutive API errors

  // Chat history for context
  List<Map<String, dynamic>> _chatHistory = [];
  
  // Seasonal farming tips to display in UI
  final List<String> _farmingTips = [
    "Crop rotation improves soil health and reduces pest pressure.",
    "Apply mulch to conserve moisture and suppress weeds.",
    "Consider companion planting to maximize space and deter pests.",
    "Monitor soil moisture regularly, especially during dry periods.",
    "Early morning is the best time to water plants to reduce evaporation.",
    "Test your soil annually to optimize fertilizer application.",
    "Integrated pest management reduces the need for chemical pesticides.",
  ];
  int _currentTipIndex = 0;
  Timer? _tipRotationTimer;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _fetchUserRole();
    
    // Rotate farming tips every 20 seconds
    _tipRotationTimer = Timer.periodic(Duration(seconds: 20), (timer) {
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _farmingTips.length;
      });
    });
  }

  @override
  void dispose() {
    _tipRotationTimer?.cancel();
    _rateLimitTimer?.cancel();
    super.dispose();
  }

  // Fetch user role from Firestore
  Future<void> _fetchUserRole() async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('role')) {
            var userRole = data['role'];
            if (userRole != null) {
              setState(() {
                _userType = userRole;
                _roleGreeting = 'Welcome, $userRole! How can I help with your farming today?';
              });
              print("User role: $_userType");
            }
          } else {
            print("User role not found in Firestore, defaulting to farmer.");
          }
        } else {
          print("User document not found.");
        }
      } catch (e) {
        print('Error fetching user role: $e');
      }
    } else {
      print("User not authenticated.");
    }
  }

  // Generate a fallback response locally when API is unavailable
  String _getFallbackResponse(String userMessage) {
    // Keyword matching for farming-related responses
    final String messageLower = userMessage.toLowerCase();

    if (messageLower.contains('hello') || messageLower.contains('hi')) {
      return 'Hello, farmer! How can I assist with your agricultural needs today?';
    } else if (messageLower.contains('soil') || messageLower.contains('dirt')) {
      return "Soil health is the foundation of successful farming. Good soil should have proper drainage, organic matter, and balanced pH. Would you like specific advice on improving your soil?";
    } else if (messageLower.contains('pest') || messageLower.contains('insect')) {
      return "Pests can be managed through integrated approaches including crop rotation, beneficial insects, and targeted treatments. Can you describe which pests you're dealing with?";
    } else if (messageLower.contains('water') || messageLower.contains('irrigation') || messageLower.contains('rain')) {
      return "Efficient water management is crucial. Consider drip irrigation for water conservation, and adjust watering based on plant needs and weather conditions.";
    } else if (messageLower.contains('crop') || messageLower.contains('plant') || messageLower.contains('grow')) {
      return "Crop selection should match your local climate, soil conditions, and market demand. What specific crops are you interested in growing?";
    } else if (messageLower.contains('fertilizer') || messageLower.contains('nutrient')) {
      return "Balanced fertilization based on soil tests is key to optimal plant growth. Over-fertilization can harm plants and contaminate water sources.";
    } else if (messageLower.contains('thank')) {
      return "You're welcome! Happy farming! Is there anything else I can help with?";
    } else {
      return "I'm currently operating in offline mode due to connection issues. For the best farming advice, please try again later when our connection is restored.";
    }
  }

  // Check if we can make an API call (rate limiting)
  bool _canMakeApiCall() {
    final now = DateTime.now();
    final timeSinceLastCall = now.difference(_lastApiCall);
    
    // Reset counter if it's been more than a minute since last API call
    if (timeSinceLastCall.inMinutes >= 1) {
      _apiCallsInLastMinute = 0;
      _isRateLimited = false;
      return true;
    }
    
    // Check if we've hit the rate limit
    if (_apiCallsInLastMinute >= _maxCallsPerMinute) {
      if (!_isRateLimited) {
        // Start a timer to reset rate limiting after 60 seconds
        _isRateLimited = true;
        _rateLimitTimer = Timer(Duration(seconds: 60), () {
          setState(() {
            _isRateLimited = false;
            _apiCallsInLastMinute = 0;
          });
        });
      }
      return false;
    }
    
    return true;
  }

  // Function to send a message and get AI response
  Future<void> sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    // Update state to hide greeting if first message
    if (!_hasSentFirstMessage) {
      setState(() {
        _hasSentFirstMessage = true;
      });
    }

    // Add user message to Firestore (non-blocking; don't fail chat if Firestore errors)
    try {
      await _firestore.collection('messages').add({
        'sender': _userType,
        'message': userMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'isAI': false,
      });
    } catch (_) {}

    try {
      // Add message to chat history for context
      _chatHistory.add({
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ]
      });

      // Set typing state to show AI is responding
      setState(() {
        _isTyping = true;
      });

      String aiResponse;

      // Check if we should use local fallback due to API issues, rate limiting, or missing API key
      if (_geminiApiKey.isEmpty) {
        aiResponse = "Chatbot API key is not set. Add GEMINI_API_KEY to your .env file (see README). For now: ${_getFallbackResponse(userMessage)}";
        await Future.delayed(Duration(seconds: 1));
      } else if (_useLocalFallback || !_canMakeApiCall()) {
        // Use local response generator
        if (_isRateLimited) {
          aiResponse = "I'm currently handling too many requests. Please wait a moment before asking another question. In the meantime, here's some advice: ${_getFallbackResponse(userMessage)}";
        } else {
          aiResponse = _getFallbackResponse(userMessage);
        }
        await Future.delayed(Duration(seconds: 1)); // Simulate processing time
      } else {
        // Try to get response from Gemini API with exponential backoff
        try {
          // Update API call tracking
          _lastApiCall = DateTime.now();
          _apiCallsInLastMinute++;
          
          aiResponse = await _getGeminiResponse();
          _errorCount = 0; // Reset error count on success
        } catch (apiError) {
          print("API Error: $apiError");
          _errorCount++;
          final errStr = apiError.toString();

          // If we've had multiple consecutive errors, switch to fallback mode
          if (_errorCount >= 3) {
            setState(() {
              _useLocalFallback = true;
              Timer(Duration(minutes: 5), () {
                if (mounted) setState(() {
                  _useLocalFallback = false;
                  _errorCount = 0;
                });
              });
            });
            aiResponse = "I'm having trouble connecting to my knowledge base. I'll switch to offline mode for now. ${_getFallbackResponse(userMessage)}";
          } else {
            // Show helpful message on first failure (e.g. network, API key)
            final isNetwork = errStr.contains('ClientException') || errStr.contains('SocketException') || errStr.contains('Failed to fetch');
            aiResponse = isNetwork
                ? "Could not reach the AI service. Check your internet connection. Here's a quick tip: ${_getFallbackResponse(userMessage)}"
                : "Something went wrong (${errStr.length > 80 ? '${errStr.substring(0, 80)}...' : errStr}). Trying fallback: ${_getFallbackResponse(userMessage)}";
          }
        }
      }

      // Add AI response to Firestore (non-blocking)
      try {
        await _firestore.collection('messages').add({
          'sender': _useLocalFallback ? 'FarmAssist (Offline)' : 'FarmAssist AI',
          'message': aiResponse,
          'timestamp': FieldValue.serverTimestamp(),
          'isAI': true,
        });
      } catch (_) {}

      // Add AI response to chat history
      _chatHistory.add({
        'role': 'model',
        'parts': [
          {'text': aiResponse}
        ]
      });

      // Update UI to show AI is done typing
      setState(() {
        _isTyping = false;
      });
    } catch (e) {
      print("Error in message flow: $e");
      setState(() {
        _isTyping = false;
      });

      // Show error message in chat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message. Please check your connection.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Function to get response from Gemini API
  Future<String> _getGeminiResponse() async {
    try {
      // Create full conversation context including system message
      List<Map<String, dynamic>> contents = [];

      // Add system message as the first user message (Gemini handles system prompts differently)
      if (_chatHistory.isEmpty || (_chatHistory.isNotEmpty && _chatHistory[0]['role'] != 'system')) {
        contents.add({
          'role': 'user',
          'parts': [
            {
              'text': 'You are FarmAssist, a concise and helpful agricultural assistant. Provide practical, relevant farming advice with an emphasis on sustainable practices. Focus on crops, soil health, pest management, weather considerations, irrigation, and farming equipment. Keep responses informative yet brief. Avoid medical advice or non-agricultural topics.'
            }
          ]
        });

        // Add model response to acknowledge the system prompt
        contents.add({
          'role': 'model',
          'parts': [
            {
              'text': "I understand. I'll act as FarmAssist, providing practical farming advice focused on sustainable agriculture practices while keeping my responses informative and concise."
            }
          ]
        });
      }

      // Add the actual conversation history (limit to last 5 messages to save tokens)
      int historyStartIndex = _chatHistory.length > 5 ? _chatHistory.length - 5 : 0;
      contents.addAll(_chatHistory.sublist(historyStartIndex));

      // Create the request body for Gemini API
      final Map<String, dynamic> requestBody = {
        'contents': contents,
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 0.95,
          'maxOutputTokens': 200, // Slightly increased for more complete farming advice
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      // Add API key as query parameter
      final uri = Uri.parse('$_geminiApiUrl?key=$_geminiApiKey');

      // Send request to Gemini API
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Extract text from the response
        String text = '';
        if (responseData.containsKey('candidates') &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0].containsKey('content') &&
            responseData['candidates'][0]['content'].containsKey('parts') &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          text = responseData['candidates'][0]['content']['parts'][0]['text'];
        }

        return text.isNotEmpty ? text : "I'm sorry, I don't have farming advice for that specific query.";
      } else {
        // Parse the error response
        Map<String, dynamic> errorResponse = {};
        try {
          errorResponse = jsonDecode(response.body);
        } catch (e) {
          // If we can't parse the JSON, just use the raw response
          print('Failed to parse error response: $e');
        }

        // Check for specific error types based on Gemini API error format
        if (errorResponse.containsKey('error')) {
          final error = errorResponse['error'];
          final errorCode = error['code'];
          final errorMessage = error['message'];

          print('Gemini API Error: Code $errorCode - $errorMessage');

          // Handle specific errors
          if (errorCode == 429) {
            // Implement exponential backoff for rate limiting issues
            setState(() {
              _isRateLimited = true;
              _apiCallsInLastMinute = _maxCallsPerMinute; // Force timeout
            });
            return "I'm receiving too many requests right now. Let me share some general farming advice while I recover: ${_farmingTips[_currentTipIndex]}";
          } else if (errorCode == 403) {
            return "I'm unable to respond due to API access limitations. Please check your API key configuration.";
          }
        }

        // Generic error handling
        print('API Error: ${response.statusCode} - ${response.body}');
        return "I'm having trouble connecting to my agricultural knowledge base. Please try again later.";
      }
    } catch (e) {
      print('Gemini API Error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.eco, color: Colors.white),
            SizedBox(width: 8),
            Text('FarmAssist', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Color(0xFF388E3C), // Forest green for farming theme
        elevation: 2,
        actions: [
          // Show API status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _useLocalFallback || _isRateLimited ? Colors.orange : Colors.lightGreenAccent,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _useLocalFallback ? "Offline" : (_isRateLimited ? "Limited" : "Online"),
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        // Light textured background
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          // Background pattern removed to prevent ImageCodecException
        ),
        child: Column(
          children: [
            // Farming tip banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Color(0xFFEFF7E1),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Color(0xFF689F38), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Tip: ${_farmingTips[_currentTipIndex]}",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF33691E),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
            // Display greeting if no messages have been sent yet
            if (!_hasSentFirstMessage)
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFDCEDC8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFAED581), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFF558B2F),
                          child: Icon(Icons.agriculture, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "FarmAssist",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF33691E),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      _roleGreeting,
                      style: TextStyle(fontSize: 15),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Ask me about crops, soil health, pest management, weather considerations, and more!",
                      style: TextStyle(fontSize: 13, color: Color(0xFF689F38)),
                    ),
                  ],
                ),
              ),

            // Show "typing" indicator when AI is responding
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text("FarmAssist is thinking",
                        style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF558B2F))),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF558B2F)),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF558B2F)),
                    ));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final messages = snapshot.data?.docs ?? [];

                  return ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var messageData = messages[index].data() as Map<String, dynamic>;
                      var message = messageData['message'] ?? '';
                      var sender = messageData['sender'] ?? '';
                      var timestamp = messageData['timestamp'];
                      var isAI = messageData['isAI'] ?? false;

                      // Determine message alignment based on who sent it
                      bool isSentByUser = !isAI;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Column(
                          crossAxisAlignment: isSentByUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            // Message bubble with improved styling
                            Row(
                              mainAxisAlignment: isSentByUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar for AI messages
                                if (!isSentByUser) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(0xFF558B2F),
                                    child: Icon(Icons.agriculture, color: Colors.white, size: 18),
                                  ),
                                  SizedBox(width: 8),
                                ],
                                
                                // Message content
                                Flexible(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSentByUser 
                                          ? Color(0xFF8BC34A) // Green for user messages
                                          : Colors.white,     // White for AI messages
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                      border: !isSentByUser ? Border.all(color: Color(0xFFDCEDC8), width: 1) : null,
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Sender name for AI messages
                                        if (!isSentByUser) ...[
                                          Text(
                                            sender,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF33691E),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                        ],
                                        
                                        // Message text
                                        Text(
                                          message,
                                          style: TextStyle(
                                            fontSize: 15, 
                                            color: isSentByUser ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Avatar for user messages
                                if (isSentByUser) ...[
                                  SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(0xFF689F38),
                                    child: Icon(Icons.person, color: Colors.white, size: 18),
                                  ),
                                ],
                              ],
                            ),

                            // Timestamp
                            Padding(
                              padding: EdgeInsets.only(
                                top: 4.0, 
                                left: isSentByUser ? 0 : 40,
                                right: isSentByUser ? 40 : 0,
                              ),
                              child: Text(
                                timestamp != null ? _formatTimestamp(timestamp.toDate()) : '',
                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            // Enhanced input area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, -2),
                    blurRadius: 5,
                  )
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Color(0xFFAED581)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask a farming question...',
                          hintStyle: TextStyle(color: Color(0xFF7CB342)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: _isTyping
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7CB342)),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _isTyping ? null : sendMessage(),
                        enabled: !_isTyping,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8BC34A), Color(0xFF689F38)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF8BC34A).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: _isTyping ? null : sendMessage,
                      tooltip: _isRateLimited ? "Please wait before sending another message" : "Send message",
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

  // Helper function to format timestamp
  String _formatTimestamp(DateTime dateTime) {
    // Format: Today at 2:30 PM or Apr 28 at 2:30 PM
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today at ${_formatTimeOfDay(dateTime)}';
    } else {
      return '${dateTime.month}/${dateTime.day} at ${_formatTimeOfDay(dateTime)}';
    }
  }

  String _formatTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}