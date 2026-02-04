import 'dart:async';

/// Mock API Service for testing UI without backend
class MockApiService {
  /// Simulates analyzing audio with realistic delays and responses
  Future<Map<String, dynamic>> analyzeAudio(String audioPath,
      {String? imagePath}) async {
    // Simulate AI processing time - 15 seconds to show all 5 loading messages
    await Future.delayed(const Duration(seconds: 15));

    // Return mock diagnosis data
    return {
      'problem': 'Worn Brake Pads',
      'severity': 'medium',
      'estimated_cost': '\$150 - \$300',
      'confidence': 'high',
      'fix_steps': [
        'Inspect brake pads for wear indicators',
        'Remove wheel and brake caliper',
        'Replace old brake pads with new ones',
        'Lubricate caliper pins',
        'Reassemble and test brake response',
        'Bed in new brake pads with gentle braking'
      ],
      'additional_info':
          'Your brake pads are showing signs of wear. This is a common maintenance item that should be addressed soon to ensure safe braking performance.',
    };
  }

  /// Returns various mock scenarios for testing
  static Map<String, dynamic> getMockScenario(String scenario) {
    switch (scenario) {
      case 'high_severity':
        return {
          'problem': 'Engine Misfire - Cylinder 3',
          'severity': 'high',
          'estimated_cost': '\$800 - \$1,500',
          'confidence': 'high',
          'fix_steps': [
            'Run diagnostic scan to confirm cylinder',
            'Check spark plug condition',
            'Inspect ignition coil',
            'Test fuel injector',
            'Replace faulty component',
            'Clear error codes and test drive'
          ],
        };
      case 'low_severity':
        return {
          'problem': 'Loose Heat Shield',
          'severity': 'low',
          'estimated_cost': '\$50 - \$100',
          'confidence': 'high',
          'fix_steps': [
            'Locate the loose heat shield',
            'Inspect mounting brackets',
            'Tighten or replace mounting hardware',
            'Test drive to verify fix'
          ],
        };
      case 'low_confidence':
        return {
          'problem': 'Possible Transmission Issue',
          'severity': 'medium',
          'estimated_cost': '\$200 - \$800',
          'confidence': 'low',
          'fix_steps': [
            'Check transmission fluid level',
            'Inspect for leaks',
            'Consider professional diagnostic',
            'May need transmission service'
          ],
        };
      default:
        return {
          'problem': 'Worn Brake Pads',
          'severity': 'medium',
          'estimated_cost': '\$150 - \$300',
          'confidence': 'high',
          'fix_steps': [
            'Inspect brake pads for wear',
            'Replace brake pads',
            'Lubricate caliper pins',
            'Test brake response'
          ],
        };
    }
  }
}
