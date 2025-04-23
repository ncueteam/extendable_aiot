import 'package:extendable_aiot/components/temp_data.dart';
import 'package:extendable_aiot/services/device_services.dart';
import 'package:extendable_aiot/themes/app_colors.dart';
import 'package:flutter/material.dart';

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
              onChanged: (_) async {
                try {
                  setState(() {
                    widget.tempData.toggle();
                  });

                  DeviceService dv = DeviceService();
                  await dv.saveDevices([widget.tempData]);
                } catch (e) {
                  // Revert the change if save fails
                  setState(() {
                    widget.tempData.toggle();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update device: $e')),
                  );
                }
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
