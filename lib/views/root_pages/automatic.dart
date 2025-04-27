import 'package:flutter/material.dart';

class Automatic extends StatefulWidget {
  const Automatic({super.key});

  @override
  State<Automatic> createState() => _AutomaticState();
}

class _AutomaticState extends State<Automatic> {
  bool isArrivingHomeOn = true;
  bool isBedTimeOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Auto Setting'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTopButton(Icons.add, 'Create New'),
                const SizedBox(width: 10),
                _buildTopButton(Icons.auto_awesome, 'AI Suggestion'),
              ],
            ),
            const SizedBox(height: 20),
            _buildAutomationCard(
              title: 'Back Home',
              location: 'living room',
              time: '15:00 - 17:00',
              lights: ['Floor Lamp 1', 'Floor Lamp 2'],
              isOn: isArrivingHomeOn,
              onToggle: (value) {
                setState(() {
                  isArrivingHomeOn = value;
                });
              },
            ),
            const SizedBox(height: 20),
            _buildAutomationCard(
              title: 'Bed Time',
              location: 'Bedroom',
              time: '21:00 - 04:00',
              lights: ['Floor Lamp 1', 'Floor Lamp 2'],
              isOn: isBedTimeOn,
              onToggle: (value) {
                setState(() {
                  isBedTimeOn = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButton(IconData icon, String label) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: Colors.black),
        label: Text(label, style: const TextStyle(color: Colors.black)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAutomationCard({
    required String title,
    required String location,
    required String time,
    required List<String> lights,
    required bool isOn,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Switch(value: isOn, onChanged: onToggle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(time, style: const TextStyle(color: Colors.black)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LightChip extends StatelessWidget {
  final String label;

  const _LightChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), backgroundColor: Colors.grey[200]);
  }
}
