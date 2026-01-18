import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_container.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conversation Archives"),
        actions: [
          IconButton(icon: const Icon(Icons.sort, color: AppTheme.primaryMint), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search logs by keyword...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E2630),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // Filter Chips
            Row(
              children: [
                _buildFilterChip("All Sessions", true),
                _buildFilterChip("Emails", false),
                _buildFilterChip("Coding", false),
              ],
            ),
            const SizedBox(height: 20),

            // List Items
            _buildHistoryItem("Prep for Interview", "10m ago • 14 messages", Icons.mic, Colors.green),
            _buildHistoryItem("Drafting Resignation", "2h ago • 3 versions", Icons.edit_document, Colors.blue),
            const SizedBox(height: 20),
            
            const Align(
              alignment: Alignment.centerLeft, 
              child: Text("YESTERDAY", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5))
            ),
            const SizedBox(height: 10),
            
            _buildHistoryItem("Python Debugging Help", "14:20 • 45m session", Icons.code, Colors.orange),
            _buildHistoryItem("Gift Ideas for Mom", "09:15 • 12 items listed", Icons.lightbulb, Colors.purple),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryMint,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {}, // Start new chat
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryMint.withOpacity(0.2) : const Color(0xFF1E2630),
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: AppTheme.primaryMint) : null,
      ),
      child: Text(
        label, 
        style: TextStyle(
          color: isActive ? AppTheme.primaryMint : Colors.grey, 
          fontWeight: FontWeight.bold
        )
      ),
    );
  }

  Widget _buildHistoryItem(String title, String subtitle, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        color: const Color(0xFF1E2630),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}