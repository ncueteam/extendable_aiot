import 'package:flutter/material.dart';

class Airconditioner extends StatefulWidget {
  final Map<String, dynamic> roomItem;

  const Airconditioner({super.key, required this.roomItem});

  @override
  State<Airconditioner> createState() => _AirconditionerState();
}

class _AirconditionerState extends State<Airconditioner>
    with SingleTickerProviderStateMixin {
  bool isSwitchOn = true;
  double temperature = 26; // 初始溫度
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 1.0,
      upperBound: 1.05,
    );
    _scaleAnimation = _controller.drive(Tween(begin: 1.0, end: 1.05));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 18) {
      return Colors.blueAccent; // 冷色
    } else if (temp > 26) {
      return Colors.redAccent; // 熱色
    } else {
      return Colors.lightBlue; // 中間色
    }
  }

  void _incrementTemperature() {
    setState(() {
      if (temperature < 35) {
        temperature += 1;
      }
    });
  }

  void _decrementTemperature() {
    setState(() {
      if (temperature > 15) {
        temperature -= 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('中央空調'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 開關區域
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('連接開關', style: TextStyle(fontSize: 18)),
                Switch(
                  value: isSwitchOn,
                  onChanged: (value) {
                    setState(() {
                      isSwitchOn = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 中間圓形控制區，加動畫
          Expanded(
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: screenWidth * 0.6,
                  height: screenWidth * 0.6,
                  decoration: BoxDecoration(
                    color: _getTemperatureColor(temperature),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${temperature.toInt()}°C\n房間溫度',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 加減按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 40,
                onPressed: () {
                  _decrementTemperature();
                },
              ),
              const SizedBox(width: 30),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 40,
                onPressed: () {
                  _incrementTemperature();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 溫度滑桿
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Slider(
              value: temperature,
              min: 15,
              max: 35,
              divisions: 20,
              label: '${temperature.toInt()}°C',
              onChanged: (value) {
                setState(() {
                  temperature = value;
                });
                _controller.forward().then((_) => _controller.reverse());
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
