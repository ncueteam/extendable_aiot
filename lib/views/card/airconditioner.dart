import 'package:flutter/material.dart';

class Airconditioner extends StatefulWidget {
  final Map<String, dynamic> roomItem;

  const Airconditioner({super.key, required this.roomItem});

  @override
  State<Airconditioner> createState() => _AirconditionerState();
}

class _AirconditionerState extends State<Airconditioner>
    with SingleTickerProviderStateMixin {
  double temperature = 25.0;
  String mode = 'Auto';
  String fanSpeed = 'Mid';
  bool powerOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back),
        title: const Text('Air Condition'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Living room',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              '${temperature.toInt()}°',
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Celcius',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Slider(
              value: temperature,
              min: 16,
              max: 30,
              divisions: 14,
              onChanged: (value) {
                setState(() {
                  temperature = value;
                });
              },
            ),
            const SizedBox(height: 30),
            _buildSectionTitle('Mode'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  ['Auto', 'Cool', 'Dry'].map((m) {
                    return _buildOptionButton(
                      label: m,
                      selected: mode == m,
                      onTap: () {
                        setState(() {
                          mode = m;
                        });
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 30),
            _buildSectionTitle('Fan speed'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  ['Low', 'Mid', 'High'].map((f) {
                    return _buildOptionButton(
                      label: f,
                      selected: fanSpeed == f,
                      onTap: () {
                        setState(() {
                          fanSpeed = f;
                        });
                      },
                    );
                  }).toList(),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Power', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Switch(
                  value: powerOn,
                  onChanged: (value) {
                    setState(() {
                      powerOn = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 50,
        decoration: BoxDecoration(
          color: selected ? Colors.pink[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.pink : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: selected ? Colors.pink[800] : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
