import 'package:flutter/material.dart';

class RootPageHead extends StatefulWidget {
  const RootPageHead({super.key});

  @override
  State<RootPageHead> createState() => _RootPageHeadState();
}

class _RootPageHeadState extends State<RootPageHead> {
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.white,
  //     appBar: AppBar(
  //       title: const Text("您好！", style: TextStyle(color: Colors.black)),
  //       backgroundColor: Colors.white,
  //       elevation: 0,
  //       actions: [
  //         IconButton(
  //           icon: const Icon(Icons.menu, color: Colors.black),
  //           onPressed: () {},
  //         ),
  //       ],
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text('xxxx年xx月xx日', style: TextStyle(color: Colors.grey)),
  //           const SizedBox(height: 10),
  //           // 天氣卡
  //           Container(
  //             padding: const EdgeInsets.all(16),
  //             decoration: BoxDecoration(
  //               color: Colors.blue,
  //               borderRadius: BorderRadius.circular(20),
  //             ),
  //             child: Row(
  //               children: [
  //                 const Icon(Icons.wb_cloudy, color: Colors.white, size: 50),
  //                 const SizedBox(width: 16),
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: const [
  //                     Text(
  //                       '32°',
  //                       style: TextStyle(color: Colors.white, fontSize: 32),
  //                     ),
  //                     Text('今日多雲', style: TextStyle(color: Colors.white)),
  //                     Text('彰化市彰化區', style: TextStyle(color: Colors.white)),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

}
