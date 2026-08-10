import 'package:flutter/material.dart';

import 'animation_detail_screen.dart';
import 'rive_animations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rive Animations')),
      body: ListView.separated(
        itemCount: riveAnimations.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = riveAnimations[index];
          return ListTile(
            leading: const Icon(Icons.animation),
            title: Text(item.title),
            subtitle: item.description == null ? null : Text(item.description!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => AnimationDetailScreen(item: item),
              ),
            ),
          );
        },
      ),
    );
  }
}
