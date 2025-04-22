import 'package:app_chiseletor/theme/theme_manager.dart';
import 'package:extendable_aiot/components/temp_data.dart';
import 'package:extendable_aiot/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ControlCard extends StatefulWidget {
  final TempData tempData;

  const ControlCard({super.key, required this.tempData});

  @override
  State<ControlCard> createState() => _ControlCardState();
}

class _ControlCardState extends State<ControlCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.tempData.isOn ? Colors.blue : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            widget.tempData.icon,
            color: AppColors.getCardColor(widget.tempData.isOn),
            size: 30,
          ),
          const Spacer(),
          Text(
            widget.tempData.room,
            style: TextStyle(
              color: AppColors.getCardColor(widget.tempData.isOn),
            ),
          ),
          Text(
            widget.tempData.title,
            style: TextStyle(
              color: AppColors.getCardColor(widget.tempData.isOn),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Switch(
              value: widget.tempData.isOn,
              onChanged: (_) {
                setState(() {
                  widget.tempData.toogle();
                });
              },
              activeColor: Colors.white,
              inactiveThumbColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
