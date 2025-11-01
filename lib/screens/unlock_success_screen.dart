import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_bar_with_nav.dart';

/// UnlockSuccessScreen
/// 
/// Light theme feedback screen after successful unlock
/// Uses teal color (#0FB498) as primary color
class UnlockSuccessScreen extends StatefulWidget {
  final String locationName;
  final String lastCleaned;

  const UnlockSuccessScreen({
    super.key,
    required this.locationName,
    required this.lastCleaned,
  });

  @override
  State<UnlockSuccessScreen> createState() => _UnlockSuccessScreenState();
}

class _UnlockSuccessScreenState extends State<UnlockSuccessScreen> {
  String? _selectedRating;

  void _submitFeedback() {
    if (_selectedRating != null) {
      HapticFeedback.mediumImpact();
      // TODO: Submit feedback to backend
      print('Feedback submitted: $_selectedRating for ${widget.locationName}');
      
      // Show confirmation and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thank you for your feedback!'),
          backgroundColor: const Color(0xFF0FB498),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      
      // Navigate back to landing page after short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Smiley face icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    '😊',
                    style: TextStyle(fontSize: 48),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Question text
              const Text(
                'How would you say\nthe cleanliness of the\nrestroom is?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Last cleaned info
              Text(
                'Last cleaned ${widget.lastCleaned}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Rating options
              _buildRatingOption(
                label: 'Clean',
                emoji: '😊',
                value: 'clean',
                color: const Color(0xFF0FB498),
              ),
              
              const SizedBox(height: 16),
              
              _buildRatingOption(
                label: 'Okay',
                emoji: '😐',
                value: 'okay',
                color: Colors.grey[300]!,
              ),
              
              const SizedBox(height: 16),
              
              _buildRatingOption(
                label: 'Needs cleaning',
                emoji: '☹️',
                value: 'needs_cleaning',
                color: Colors.grey[300]!,
              ),
              
              const Spacer(),
              
              // Submit button (only visible when option is selected)
              if (_selectedRating != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0FB498),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Submit Feedback',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingOption({
    required String label,
    required String emoji,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedRating == value;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedRating = value;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isSelected 
                    ? (value == 'clean' ? Colors.white : Colors.black87)
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
