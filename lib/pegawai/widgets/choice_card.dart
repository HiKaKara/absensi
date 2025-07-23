import 'package:flutter/material.dart';

class ChoiceCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const ChoiceCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                   return const Icon(Icons.image_not_supported, size: 100);
                },
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}