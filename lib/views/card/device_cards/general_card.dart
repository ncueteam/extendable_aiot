import 'package:extendable_aiot/models/abstract/general_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeneralCard extends StatefulWidget {
  final device;
  final Widget detailedPage;
  final Widget? title;
  final Widget? subtitle;
  final Widget? content;
  const GeneralCard({
    super.key,
    required this.device,
    required this.detailedPage,
    this.content,
    this.title,
    this.subtitle,
  });
  @override
  State<GeneralCard> createState() => _GeneralCardState();
}

class _GeneralCardState extends State<GeneralCard> {
  // 格式化最後更新時間
  String _formatLastUpdated(Timestamp? timestamp) {
    if (timestamp == null) return '未知';
    return timestamp.toDate().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child:
          widget.content ??
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => widget.detailedPage),
              );
            },
            title:
                widget.title ??
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(widget.device.icon, size: 30, color: Colors.blueGrey),
                  ],
                ),
            subtitle:
                widget.subtitle ??
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.device.name),
                    const SizedBox(height: 5),
                    Text(
                      '最後更新: ${_formatLastUpdated(widget.device.lastUpdated)}',
                    ),
                  ],
                ),
            tileColor: Colors.grey[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.all(5),
          ),
    );
  }
}
