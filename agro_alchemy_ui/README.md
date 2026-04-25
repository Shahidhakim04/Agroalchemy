# agro_alchemy_ui

A new Flutter project.

## Chatbot (Gemini API key)

The in-app chatbot uses **Google Gemini**. To enable it:

1. Get an API key from [Google AI Studio](https://aistudio.google.com/apikey).
2. In the project root (`agro_alchemy_ui`), create or edit `.env` and add:
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```
3. Restart the app. If the key is missing, the chatbot falls back to simple local replies.

See `.env.example` for other optional variables.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
