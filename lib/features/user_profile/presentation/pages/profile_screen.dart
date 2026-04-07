import 'package:flutter/material.dart';
import '../widgets/profile_header.dart';
import '../widgets/impact_section.dart';
import '../widgets/account_settings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 80),
            ProfileHeader(),
            SizedBox(height: 32),
            ImpactSection(),
            SizedBox(height: 32),
            AccountSettings(),
            SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }
}