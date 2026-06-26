import 'package:flutter/material.dart';

import '../../assets/app_assets.dart';
import '../widgets/page_panel.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 120),
      child: PagePanel(
        title: 'Mine',
        subtitle: 'Account and service settings.',
        asset: AppAssets.featurePrimary,
      ),
    );
  }
}
