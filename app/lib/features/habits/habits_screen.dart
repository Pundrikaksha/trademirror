import 'package:flutter/material.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Behavioral Patterns',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.speed, color: Colors.amber),
              title: Text('Overtrading Days'),
              subtitle: Text('Days with trade count exceeding threshold (e.g. >= 15 round trips)'),
              trailing: Text('4 days', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.replay, color: Colors.redAccent),
              title: Text('Revenge Re-entries'),
              subtitle: Text('Re-entering positions within 10 minutes after a losing exit'),
              trailing: Text('40 times', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.event_busy, color: Colors.deepOrange),
              title: Text('Expiry-Day Trades (0-DTE)'),
              subtitle: Text('Share of round trips executed on contract expiry day'),
              trailing: Text('34%', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.timer_outlined, color: Colors.blueAccent),
              title: Text('Hold Asymmetry'),
              subtitle: Text('Ratio of median losing hold time vs median winning hold time'),
              trailing: Text('3.3x', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
