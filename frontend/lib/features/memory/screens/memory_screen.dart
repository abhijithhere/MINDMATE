import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../widgets/memory_pin_card.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  String selectedFilter = "All";
  final List<String> filters = ["All", "Secure", "Personal", "Work", "Health"];
  
  List<dynamic> memories = [];
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
    if (userId != null) {
      _fetchMemories();
    }
  }

  Future<void> _fetchMemories() async {
    setState(() => isLoading = true);
    final data = await ApiService.getMemories(userId!, category: selectedFilter);
    setState(() {
      memories = data;
      isLoading = false;
    });
  }

  void _onFilterChanged(String filter) {
    setState(() => selectedFilter = filter);
    _fetchMemories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: AppTheme.kBackgroundDark,
        title: Row(
          children: [
            const Icon(Icons.psychology, color: AppTheme.kAccentGreen),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Memory Core", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("SYSTEM ACTIVE", style: TextStyle(fontSize: 10, color: AppTheme.kAccentGreen, letterSpacing: 1.5)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // --- SEARCH BAR ---
            const SizedBox(height: 10),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search 4,021 memories...",
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.search, color: AppTheme.kPrimaryTeal),
                suffixIcon: const Icon(Icons.tune, color: Colors.grey),
                filled: true,
                fillColor: AppTheme.kCardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- FILTER CHIPS ---
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = filter == selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (bool selected) => _onFilterChanged(filter),
                      backgroundColor: AppTheme.kCardDark,
                      selectedColor: AppTheme.kPrimaryTeal.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.kPrimaryTeal : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? AppTheme.kPrimaryTeal : Colors.transparent,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // --- MEMORY GRID ---
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryTeal))
                  : memories.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 Columns
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8, // Taller cards
                          ),
                          itemCount: memories.length,
                          itemBuilder: (context, index) {
                            final item = memories[index];
                            return MemoryPinCard(
                              title: item['title'] ?? "Untitled",
                              content: item['summary'] ?? item['content'] ?? "No content",
                              category: item['category'] ?? "General",
                              isSecure: (item['category'] ?? "").toString().toLowerCase() == 'secure',
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      
      // --- FAB ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Open Add Memory Dialog
        },
        backgroundColor: AppTheme.kAccentGreen,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.memory, size: 60, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text("No memories found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}