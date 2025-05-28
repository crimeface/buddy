import 'package:flutter/material.dart';
import 'theme.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Featured Services'),
        backgroundColor: isDark ? Colors.black : BuddyTheme.primaryColor,
        foregroundColor: isDark ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(BuddyTheme.spacingMd),
        child: ListView(
          children: [
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildServiceCard(
                    context,
                    imageUrl:
                        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
                    name: 'Cafe Mocha',
                    type: 'Cafe',
                  ),
                  const SizedBox(width: BuddyTheme.spacingSm),
                  _buildServiceCard(
                    context,
                    imageUrl:
                        'https://images.unsplash.com/photo-1460518451285-97b6aa326961?auto=format&fit=crop&w=400&q=80',
                    name: 'City Library',
                    type: 'Library',
                  ),
                  // Add more service cards here
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String imageUrl,
    required String name,
    required String type,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: BuddyTheme.backgroundSecondaryColor,
        borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(BuddyTheme.borderRadiusMd),
            child: Image.network(
              imageUrl,
              width: 100,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: BuddyTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            type,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: BuddyTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
