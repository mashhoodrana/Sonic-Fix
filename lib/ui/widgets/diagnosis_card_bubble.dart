import 'package:flutter/material.dart';

class DiagnosisCardBubble extends StatelessWidget {
  final Map<String, dynamic> diagnosis;

  const DiagnosisCardBubble({super.key, required this.diagnosis});

  Color _getSeverityColor(String? severity) {
    if (severity == null) return Colors.grey;
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = diagnosis['severity'] ?? 'Low';
    final severityColor = _getSeverityColor(severity.toString());
    final machine = diagnosis['machine_detected'] ?? 'Unknown Machine';
    final problem = diagnosis['problem'] ?? 'Unknown Issue';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
             topLeft: Radius.circular(20),
             topRight: Radius.circular(20),
             bottomRight: Radius.circular(20),
             bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: severityColor.withOpacity(0.3), width: 1),
          boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2)
              )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Hug content
          children: [
              // Header
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                               borderRadius: BorderRadius.circular(6),
                               child: Image.asset('assets/sonicfix.jpg', width: 24, height: 24, fit: BoxFit.cover),
                          ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                    "SonicFix AI", 
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12
                                    )
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      machine, 
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold
                                      )
                                  ),
                              ],
                          )
                      ),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: severityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: severityColor.withOpacity(0.5))
                          ),
                          child: Text(
                              severity.toString().toUpperCase(), 
                              style: TextStyle(
                                  color: severityColor, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 10
                              )
                          ),
                      )
                  ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
              
              // Diagnosis
              Text("Detected Issue:", style: Theme.of(context).textTheme.labelSmall),
              Text(
                  problem, 
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.w600
                  )
              ),
              const SizedBox(height: 12),

              // Fix Steps
              if (diagnosis['fix_steps'] != null) ...[
                 Text("Recommended Actions:", style: Theme.of(context).textTheme.labelSmall),
                 const SizedBox(height: 4),
                 ... (diagnosis['fix_steps'] as List<dynamic>).take(3).map((step) => 
                    Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text("• ", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                                Expanded(child: Text(step.toString(), style: Theme.of(context).textTheme.bodyMedium)),
                            ],
                        ),
                    )
                 ),
              ],
              
              const SizedBox(height: 12),
              // Footer
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Row(
                              children: [
                                  const Icon(Icons.build_circle_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text("Confidence: ${diagnosis['confidence'] ?? 'Medium'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                          ),
                          Row(
                              children: [
                                  const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                      (diagnosis['estimated_cost'] ?? 'N/A').toString().replaceAll('\$', '').trim(), 
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)
                                  ),
                              ],
                          )
                      ],
                  ),
              )
          ],
        ),
      ),
    );
  }
}
