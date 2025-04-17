import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class RootPageHead extends StatefulWidget {
  const RootPageHead({super.key});

  @override
  State<RootPageHead> createState() => _RootPageHeadState();
}

class _RootPageHeadState extends State<RootPageHead> {
  @override
  Widget build(BuildContext context) {
    return Container(
      //height: MediaQuery.of(context).size.height / 3,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.nav),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),

          const SizedBox(height: 10),
          const Text(
            "您好！Have a nice day",
            style: TextStyle(
              color: Colors.black,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          //const SizedBox(height: 10),
          const Text('xxxx年xx月xx日', style: TextStyle(color: Colors.blue)),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wb_cloudy_rounded,
                  color: Colors.white,
                  size: 120,
                ),
                const SizedBox(width: 50),
                Column(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
