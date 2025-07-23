import 'package:flutter/material.dart';
import 'package:absensi/pegawai/widgets/choice_card.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Mode Kerja'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChoiceCard(
              title: 'Work from Anywhere',
              imagePath: 'assets/images/img2.jpg',
              onTap: () {
                Navigator.pushNamed(context, '/wfa-login');
              },
            ),
            const SizedBox(height: 20),
            ChoiceCard(
              title: 'Work from Office',
              imagePath: 'assets/images/img1.jpg',
              onTap: () {
                Navigator.pushNamed(context, '/wfo-login');
              },
            ),
          ],
        ),
      ),
    );
  }
}