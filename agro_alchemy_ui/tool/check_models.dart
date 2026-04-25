import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final apiKey = 'YOUR_API_KEY';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Available Models:');
      for (var model in data['models']) {
        print('- ${model['name']}');
      }
    } else {
      print('Error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
