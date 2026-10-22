import 'package:flutter/material.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import CSV'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.file_upload_outlined,
                size: 64,
                color: Color(0xFF0F766E),
              ),
              const SizedBox(height: 16),
              Text(
                'Import Tradebook CSV',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Select your broker tradebook export or sample synthetic CSV file to analyze charges and trading habits.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose CSV File'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
