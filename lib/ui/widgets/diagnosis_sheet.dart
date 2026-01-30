import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiagnosisSheet extends ConsumerWidget {
  final Map<String, dynamic> diagnosis;
  
  const DiagnosisSheet({super.key, required this.diagnosis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parse Diagnosis Data
    final problem = diagnosis['problem'] ?? 'Unknown Issue';
    final severity = diagnosis['severity'] ?? 'Unknown';
    final cost = diagnosis['estimated_cost'] ?? 'N/A';
    final steps = List<String>.from(diagnosis['fix_steps'] ?? []);
    final confidence = diagnosis['confidence'];

    Color severityColor;
    if (severity.toString().toLowerCase() == 'high') {
      severityColor = Colors.redAccent;
    } else if (severity.toString().toLowerCase() == 'medium') {
      severityColor = Colors.orangeAccent;
    } else {
      severityColor = Colors.greenAccent;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.car_repair, size: 32, color: severityColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      problem,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: severityColor),
                      ),
                      child: Text(
                        "Severity: $severity",
                        style: TextStyle(color: severityColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Estimated Cost: $cost",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            "Fix Steps:",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...steps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(step)),
              ],
            ),
          )),
          const SizedBox(height: 24),
          if (confidence == 'low')
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: Colors.amber.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.amber),
               ),
               child: Row(
                 children: [
                   const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                   const SizedBox(width: 12),
                   const Expanded(
                     child: Text("I'm not 100% sure. A photo might help me diagnose this better."),
                   ),
                   TextButton(onPressed: () {
                     ref.read(recordingControllerProvider.notifier).refineWithPhoto();
                     // Close the current sheet so the loading runs? 
                     // Or maybe we want the sheet to stay and update?
                     // For now, let's Pop to show spinner on Home or handle loading in sheet.
                     // The Home Screen handles spinner if isProcessing matches.
                     Navigator.of(context).pop(); 
                   }, child: const Text("Take Photo"))
                 ],
               ),
             ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
