import 'package:flutter/material.dart';

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
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
          const Text(
            "您好！",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text('xxxx年xx月xx日', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_cloudy, color: Colors.white, size: 50),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '32°',
                      style: TextStyle(color: Colors.white, fontSize: 32),
                    ),
                    Text('今日多雲', style: TextStyle(color: Colors.white)),
                    Text('彰化市彰化區', style: TextStyle(color: Colors.white)),
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
