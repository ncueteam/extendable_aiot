import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import 'dart:async';
class RootPageHead extends StatefulWidget {
  const RootPageHead({super.key});

  @override
  State<RootPageHead> createState() => _RootPageHeadState();
}

class _RootPageHeadState extends State<RootPageHead> {
  late String _currentTime;

  @override
  void initState() {
    
    super.initState();
    _updateTime();
    // Update the time every second
    Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }


  void _updateTime() {
    setState(() {
      final now = DateTime.now();
      _currentTime =
          '${now.year}年${now.month.toString().padLeft(2, '0')}月${now.day.toString().padLeft(2, '0')}日 '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: AppColors.active),
          alignment: Alignment.topLeft,
          onPressed: () {},
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.nav),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "您好！Have a nice day",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Text(_currentTime, style: const TextStyle(color: Colors.blue)),
              SizedBox(height: 16),
              //天氣卡
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wb_cloudy,
                      color: Colors.white,
                      size: 120,
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '32°',
                            style: TextStyle(color: Colors.white, fontSize: 40),
                          ),
                          Text(
                            '今日多雲',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          Text(
                            '彰化市彰化區',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
