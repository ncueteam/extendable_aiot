import 'package:extendable_aiot/l10n/app_localizations.dart';
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
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(localizations?.airCondition ?? 'Air Condition'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              localizations?.livingRoom ?? 'Living room',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              '${temperature.toInt()}°',
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            Text(
              localizations?.celsius ?? 'Celsius',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
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
            _buildSectionTitle(localizations?.mode ?? 'Mode'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionButton(
                  label: localizations?.auto ?? 'Auto',
                  selected: mode == 'Auto',
                  onTap: () {
                    setState(() {
                      mode = 'Auto';
                    });
                  },
                ),
                _buildOptionButton(
                  label: localizations?.cool ?? 'Cool',
                  selected: mode == 'Cool',
                  onTap: () {
                    setState(() {
                      mode = 'Cool';
                    });
                  },
                ),
                _buildOptionButton(
                  label: localizations?.dry ?? 'Dry',
                  selected: mode == 'Dry',
                  onTap: () {
                    setState(() {
                      mode = 'Dry';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildSectionTitle(localizations?.fanSpeed ?? 'Fan speed'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionButton(
                  label: localizations?.low ?? 'Low',
                  selected: fanSpeed == 'Low',
                  onTap: () {
                    setState(() {
                      fanSpeed = 'Low';
                    });
                  },
                ),
                _buildOptionButton(
                  label: localizations?.mid ?? 'Mid',
                  selected: fanSpeed == 'Mid',
                  onTap: () {
                    setState(() {
                      fanSpeed = 'Mid';
                    });
                  },
                ),
                _buildOptionButton(
                  label: localizations?.high ?? 'High',
                  selected: fanSpeed == 'High',
                  onTap: () {
                    setState(() {
                      fanSpeed = 'High';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 60),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    localizations?.power ?? 'Power',
                    style: const TextStyle(fontSize: 18),
                  ),
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
