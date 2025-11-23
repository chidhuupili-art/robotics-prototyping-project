import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'providers.dart';
import 'package:showcaseview/showcaseview.dart';

class EndgameScoringPage extends ConsumerWidget {

  const EndgameScoringPage({
    super.key,
  });

  Widget _buildScoringRow({
    required WidgetRef ref,
    required String label,
    required int points,
    required StateProvider<int> provider,
    required IconData icon,
  }) {
    final count = ref.watch(provider);
    final theme = Theme.of(ref.context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 170,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                '$label ($points pts):',
                style: const TextStyle(fontSize: 14),
                maxLines: 1,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle),
          iconSize: 32,
          color: Colors.green,
          onPressed: () {
            ref.read(provider.notifier).state++;
          },
        ),
        SizedBox(
          width: 30,
          child: Text(
            count.toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle),
          iconSize: 32,
          color: Colors.red,
          onPressed: () {
            if (ref.read(provider) > 0) {
              ref.read(provider.notifier).state--;
            }
          },
        ),
      ],
    );
  }

  void _resetEndgameCounters(WidgetRef ref) {
    ref.read(pizza5ftProvider.notifier).state = 0;
    ref.read(pizza10ftProvider.notifier).state = 0;
    ref.read(pizza15ftProvider.notifier).state = 0;
    ref.read(pizza20ftProvider.notifier).state = 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count5ft = ref.watch(pizza5ftProvider);
    final count10ft = ref.watch(pizza10ftProvider);
    final count15ft = ref.watch(pizza15ftProvider);
    final count20ft = ref.watch(pizza20ftProvider);

    final totalEndgameScore = (count5ft * 10) +
        (count10ft * 25) +
        (count15ft * 40) +
        (count20ft * 50);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 0, width: double.infinity),
          // Showcase(
          //   key: pizzaButtonKey,
          //   title: 'Step 4: Endgame Scoring',
          //   description: 'On this page, tap the green + to add launched pizzas.',
          //   child: _buildScoringRow(
          //     ref: ref,
          //     label: '5 ft Pizzas',
          //     points: 10,
          //     provider: pizza5ftProvider,
          //     icon: Icons.local_pizza_outlined,
          //   ),
          // ),
          _buildScoringRow(
            ref: ref,
            label: '10 ft Pizzas',
            points: 25,
            provider: pizza10ftProvider,
            icon: Icons.local_pizza_outlined,
          ),
          _buildScoringRow(
            ref: ref,
            label: '15 ft Pizzas',
            points: 40,
            provider: pizza15ftProvider,
            icon: Icons.local_pizza_outlined,
          ),
          _buildScoringRow(
            ref: ref,
            label: '20+ ft Pizzas',
            points: 50,
            provider: pizza20ftProvider,
            icon: Icons.local_pizza_outlined,
          ),
          const SizedBox(height: 30),
          Text(
            'Total Endgame Score:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            totalEndgameScore.toString(),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => _resetEndgameCounters(ref),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Endgame Scores'),
          ),
        ],
      ),
    );
  }
}