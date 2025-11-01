import 'package:flutter/material.dart';

/// ScanToUnlockBanner
/// 
/// Modern scan-to-unlock banner for LandingPage.
/// Features a teal/green background (#0FB498), greeting for Rahul,
/// search input for finding COPAs, and the scan-to-unlock button.
class ScanToUnlockBanner extends StatefulWidget {
  const ScanToUnlockBanner({super.key});

  @override
  State<ScanToUnlockBanner> createState() => _ScanToUnlockBannerState();
}

class _ScanToUnlockBannerState extends State<ScanToUnlockBanner> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    // Placeholder function for search functionality
    // TODO: Implement COPA search logic
    debugPrint('Search query: $value');
  }

  void _onScanToUnlockV2() {
    // Navigate to scan screen (same as original)
    Navigator.pushNamed(context, '/scan');
  }

  void _onFilterTapV2() {
    // Placeholder for filter functionality
    // TODO: Implement filter logic
    debugPrint('Filter tapped');
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0FB498), // Teal/green background
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 20,
              right: 24,
              bottom: 20,
              left: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Greeting text (reduced size)
                const Text(
                  'Hello, Rahul!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Find a COPA search field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _onSearch,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Find a COPA',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.tune,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                        onPressed: _onFilterTapV2,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Scan to unlock button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onScanToUnlockV2,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Scan to unlock',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
