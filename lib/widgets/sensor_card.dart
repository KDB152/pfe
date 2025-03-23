import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';

class SensorCard extends StatelessWidget {
  final SensorData sensorData;
  final VoidCallback onRefresh;

  const SensorCard({
    Key? key,
    required this.sensorData,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Données des capteurs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                  tooltip: 'Actualiser les données',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildSensorGrid(),
            const SizedBox(height: 16),
            _buildAlarmStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildSensorItem(
          'Température',
          '${sensorData.temperature.toStringAsFixed(1)} °C',
          Icons.thermostat,
          _getTemperatureColor(sensorData.temperature),
        ),
        _buildSensorItem(
          'Humidité',
          '${sensorData.humidity.toStringAsFixed(1)} %',
          Icons.water_drop,
          Colors.blue,
        ),
        _buildSensorItem(
          'Fumée',
          _getSmokeLevel(sensorData.smoke),
          Icons.air,
          _getSmokeColor(sensorData.smoke),
        ),
        _buildSensorItem(
          'CO2',
          '${sensorData.co2.toStringAsFixed(0)} ppm',
          Icons.cloud,
          _getCO2Color(sensorData.co2),
        ),
      ],
    );
  }

  Widget _buildSensorItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmStatus() {
    final bool isAlarmActive = sensorData.isAlarmActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color:
            isAlarmActive
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isAlarmActive
                  ? Colors.red.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAlarmActive ? Icons.warning_amber : Icons.check_circle,
            color: isAlarmActive ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            isAlarmActive ? 'Alarme active' : 'Système en sécurité',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAlarmActive ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature < 15) {
      return Colors.blue;
    } else if (temperature < 25) {
      return Colors.green;
    } else if (temperature < 35) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getCO2Color(double co2) {
    if (co2 < 800) {
      return Colors.green;
    } else if (co2 < 1000) {
      return Colors.blue;
    } else if (co2 < 1500) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getSmokeLevel(double smoke) {
    if (smoke < 0.1) {
      return 'Normal';
    } else if (smoke < 0.5) {
      return 'Faible';
    } else if (smoke < 1.0) {
      return 'Modéré';
    } else {
      return 'Élevé';
    }
  }

  Color _getSmokeColor(double smoke) {
    if (smoke < 0.1) {
      return Colors.green;
    } else if (smoke < 0.5) {
      return Colors.blue;
    } else if (smoke < 1.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
