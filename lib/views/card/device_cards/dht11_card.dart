import 'package:extendable_aiot/models/sub_type/mqtt_dht11_model.dart';
import 'package:extendable_aiot/views/sub_pages/mqtt_dht11_details_page.dart';
import 'package:flutter/material.dart';

class Dht11Card extends StatefulWidget {
  final MQTTEnabledDHT11Model device;
  const Dht11Card({super.key, required this.device});

  @override
  State<Dht11Card> createState() => _Dht11CardState();
}

class _Dht11CardState extends State<Dht11Card> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MQTTDht11DetailsPage(sensor: widget.device),
            ),
          );
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.thermostat, size: 30, color: Colors.blueGrey),
            Text(
              widget.device.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              '最後更新: ${widget.device.lastUpdatedTime.toString().split('.')[0]}',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Icon(Icons.thermostat, size: 60, color: Colors.red),
                    Text('溫度: ${widget.device.temperature} °C'),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.water_drop, size: 60, color: Colors.blue),
                    Text('濕度: ${widget.device.humidity} %'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),

        tileColor: Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
