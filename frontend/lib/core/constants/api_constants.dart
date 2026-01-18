class ApiConstants {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator
  static const String baseUrl = "http://10.0.2.2:8000";
  
  // Auth
  static const String login = "$baseUrl/auth/login";
  static const String signup = "$baseUrl/auth/signup";
  
  // Chat & Voice
  static const String chatSend = "$baseUrl/chat/send";
  static const String chatHistory = "$baseUrl/chat/history";
  static const String uploadAudio = "$baseUrl/chat/upload-audio"; // The new endpoint
  
  // Data
  static const String dashboard = "$baseUrl/dashboard";
  static const String memories = "$baseUrl/memories"; // Note: You might need to add this route to backend if missing, or use /chat/history with filters
  static const String predict = "$baseUrl/predict"; // If you implement the prediction endpoint
}