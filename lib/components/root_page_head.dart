import 'package:flutter/material.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';

class RootPageHead extends StatefulWidget {
  const RootPageHead({super.key});

  @override
  State<RootPageHead> createState() => _RootPageHeadState();
}

class _RootPageHeadState extends State<RootPageHead> {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations? localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations?.hello ?? "Hello",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(),
              Text(
                localizations?.manageSmartHome ??
                    "let's manage your smart home.",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              //天氣卡
              // Container(
              //   padding: const EdgeInsets.all(8),
              //   decoration: BoxDecoration(
              //     color: Colors.blue,
              //     borderRadius: BorderRadius.circular(20),
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       const Icon(Icons.wb_cloudy, color: Colors.white, size: 120),
              //       Container(
              //         padding: EdgeInsets.only(left: 50),
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: const [
              //             Text(
              //               '32°',
              //               style: TextStyle(color: Colors.white, fontSize: 40),
              //             ),
              //             Text(
              //               '今日多雲',
              //               style: TextStyle(color: Colors.white, fontSize: 20),
              //             ),
              //             Text(
              //               '彰化市彰化區',
              //               style: TextStyle(color: Colors.white, fontSize: 20),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }
}
