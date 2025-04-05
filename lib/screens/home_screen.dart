import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data_model.dart';
import './notifications_screen.dart';
import './settings_screen.dart';
import '../services/auth_service.dart';
import '../services/sensor_service.dart';
import '../screens/login_screen.dart';
import '../screens/user_management_screen.dart';
import '../widgets/fire_detection_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;

  const HomeScreen({super.key, required this.userEmail});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  SensorData? _sensorData;
  bool _isLoading = true;
  bool _isAdmin = false;
  final AuthService _authService = AuthService();
  final SensorService _sensorService = SensorService();
  late StreamSubscription<SensorData> _sensorSubscription;

  // Pour les graphiques
  final List<double> _temperatureData = List<double>.filled(20, 22.0).toList();
  final List<double> _humidityData = List<double>.filled(20, 45.0).toList();
  final List<double> _smokeData = List<double>.filled(20, 0.0).toList();
  final List<double> _co2Data = List<double>.generate(20, (_) => 0.0);

  // Animation controller
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Initialiser l'animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Vérifier si l'utilisateur est admin
    _checkAdminStatus();

    // Initialiser le service de capteurs
    _sensorService.initialize().then((_) {
      // S'abonner aux mises à jour des capteurs
      _sensorSubscription = _sensorService.sensorDataStream.listen(
        _onSensorDataUpdate,
      );

      // Obtenir les données initiales
      _loadSensorData();
    });
  }

  @override
  void dispose() {
    _sensorSubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    bool isAdmin = await _authService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    }
  }

  void _onSensorDataUpdate(SensorData data) {
    setState(() {
      _sensorData = data;
      _isLoading = false;

      // Mettre à jour les données du graphique
      _updateChartData(data);
    });

    // Animer la transition
    _animationController.reset();
    _animationController.forward();
  }

  void _updateChartData(SensorData data) {
    // Mettre à jour les listes de données en supprimant la plus ancienne valeur
    // et en ajoutant la nouvelle à la fin
    _temperatureData.removeAt(0);
    _temperatureData.add(data.temperature);

    _humidityData.removeAt(0);
    _humidityData.add(data.humidity);

    _smokeData.removeAt(0);
    _smokeData.add(data.smoke * 100); // Amplifier pour la visualisation

    _co2Data.removeAt(0);
    _co2Data.add(data.co2);
  }

  Future<void> _loadSensorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = _sensorService.getLastSensorData();
      setState(() {
        _sensorData = data;
        _updateChartData(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des données: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détecteur Incendie'),
        backgroundColor: Colors.deepOrange,
      ),
      drawer: _buildDrawer(context),
      body: FireDetectionBackground(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                )
                : RefreshIndicator(
                  onRefresh: _loadSensorData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserInfoCard(),
                        const SizedBox(height: 20),
                        _buildSensorDataCards(),
                        const SizedBox(height: 20),
                        _buildCharts(),
                        const SizedBox(height: 20),
                        _buildSystemStatusSection(),
                        const SizedBox(height: 20),
                        _buildRecentAlertsSection(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildSensorDataCards() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mesures en temps réel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 187, 183, 183),
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSensorDataCard(
                  title: 'Température',
                  value: '${_sensorData!.temperature} °C',
                  icon: Icons.thermostat,
                  color: Colors.red,
                  animation: _animationController,
                ),
                _buildSensorDataCard(
                  title: 'Humidité',
                  value: '${_sensorData!.humidity} %',
                  icon: Icons.water_drop,
                  color: Colors.blue,
                  animation: _animationController,
                ),
                _buildSensorDataCard(
                  title: 'Fumée',
                  value: '${(_sensorData!.smoke).toStringAsFixed(1)} %',
                  icon: Icons.smoke_free,
                  color: Colors.grey,
                  animation: _animationController,
                ),
                _buildSensorDataCard(
                  title: 'CO2',
                  value: '${(_sensorData!.co2).toStringAsFixed(1)} ppm',
                  icon: Icons.cloud,
                  color: Colors.green,
                  animation: _animationController,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSensorDataCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Animation<double> animation,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.9 + animation.value * 0.1,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Évolution des données',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 187, 183, 183),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTabSelector(),
                const SizedBox(height: 16),
                SizedBox(height: 200, child: _buildLineChart()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _selectedTabIndex = 0;
  final List<String> _tabTitles = ['Température', 'Humidité', 'Fumée', 'CO2'];
  final List<Color> _tabColors = [
    Colors.red,
    Colors.blue,
    Colors.grey,
    Colors.orange,
  ];

  Widget _buildTabSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabTitles.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? _tabColors[index]
                        : _tabColors[index].withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _tabTitles[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : _tabColors[index],
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLineChart() {
    List<double> data;
    String label;
    Color color;
    String unit;

    switch (_selectedTabIndex) {
      case 0:
        data = _temperatureData;
        label = 'Temperature';
        color = Colors.red;
        unit = '°C';
        break;
      case 1:
        data = _humidityData;
        label = 'Humidité';
        color = Colors.blue;
        unit = '%';
        break;
      case 2:
        data = _smokeData;
        label = 'Fumée';
        color = Colors.grey;
        unit = '%';
        break;
      case 3:
        data = _co2Data;
        label = 'CO2';
        color = Colors.green;
        unit = '%';
        break;
      default:
        data = _temperatureData;
        label = 'Temperature';
        color = Colors.red;
        unit = '°C';
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(data.length, (index) {
              return FlSpot(index.toDouble(), data[index]);
            }),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                return LineTooltipItem(
                  '${touchedSpot.y.toStringAsFixed(1)} $unit',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.deepOrange),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isAdmin
                              ? Icons.admin_panel_settings
                              : Icons.local_fire_department,
                          color: const Color.fromARGB(255, 255, 0, 0),
                          size: 50,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Détecteur Incendie',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Accueil'),
            selected: true,
            onTap: () {
              Navigator.pop(context); // Ferme le drawer
            },
          ),
          // Afficher "Gestionnaire des utilisateurs" pour les administrateurs
          if (_isAdmin)
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Gestionnaire des utilisateurs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementScreen(),
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.videocam, color: Colors.deepOrange),
            title: Text('Visualiser le local'),
            onTap: () {
              Navigator.pushNamed(context, '/live-view');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SettingsScreen(
                        email: _authService.getCurrentUserEmail(),
                      ),
                ),
              );
            },
          ),
          // Afficher "Aide" seulement pour les utilisateurs non-administrateurs
          if (!_isAdmin)
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Aide & Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/Aide & Support');
              },
            ),
          // Dans le drawer de HomeScreen, ajouter cet élément pour les administrateurs
          // Après l'élément UserManagementScreen

          // Vérifier si l'utilisateur est admin pour afficher l'option de gestion des commentaires
          if (_isAdmin) // Assurez-vous d'avoir une variable isAdmin dans votre HomeScreen
            ListTile(
              leading: const Icon(Icons.comment),
              title: const Text('Commentaires utilisateurs'),
              onTap: () {
                Navigator.pop(context); // Fermer le drawer
                Navigator.pushNamed(context, '/users-comments');
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              // Logique de déconnexion inchangée
              // Ferme le drawer
              Navigator.pop(context);

              // Afficher une boîte de dialogue pour confirmer la déconnexion
              bool confirmLogout =
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmation'),
                        content: const Text(
                          'Êtes-vous sûr de vouloir vous déconnecter?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Déconnexion',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  ) ??
                  false;

              // Si l'utilisateur confirme la déconnexion
              if (confirmLogout) {
                try {
                  final authService = AuthService();
                  await authService.signOut();

                  // Navigation vers l'écran de connexion et suppression de toutes les routes précédentes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la déconnexion !')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // Dans la classe _HomeScreenState, modifiez la méthode _buildUserInfoCard()
  Widget _buildUserInfoCard() {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(_authService.getCurrentUser()?.uid)
              .get(),
      builder: (context, snapshot) {
        String username = 'Utilisateur';
        if (snapshot.hasData && snapshot.data!.exists) {
          username = snapshot.data!.get('username') ?? 'Utilisateur';
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _isAdmin ? Colors.red : Colors.orange,
                  child: Icon(
                    _isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue, $username',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _isAdmin ? Colors.red : Colors.black,
                        ),
                      ),
                      Text(
                        _authService.getCurrentUserEmail(),
                        style: const TextStyle(
                          color: Color.fromARGB(255, 185, 182, 182),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'État du système',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 187, 183, 183),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSensorStatusItem(
                  icon: Icons.smoke_free,
                  title: 'Détecteur de fumée',
                  isActive: true,
                ),
                const Divider(),
                _buildSensorStatusItem(
                  icon: Icons.thermostat,
                  title: 'Détecteur de chaleur',
                  isActive: true,
                ),
                const Divider(),
                _buildSensorStatusItem(
                  icon: Icons.volume_up,
                  title: 'Alarme sonore',
                  isActive: _sensorData?.isAlarmActive ?? false,
                  status:
                      _sensorData?.isAlarmActive ?? false
                          ? 'Active'
                          : 'En attente',
                  statusColor:
                      _sensorData?.isAlarmActive ?? false
                          ? Colors.red
                          : Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorStatusItem({
    required IconData icon,
    required String title,
    required bool isActive,
    String? status,
    Color? statusColor,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, color: isActive ? Colors.green : Colors.orange),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                status ?? (isActive ? 'Actif' : 'Inactif'),
                style: TextStyle(
                  color:
                      statusColor ?? (isActive ? Colors.green : Colors.orange),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: isActive,
          activeColor: Colors.green,
          onChanged: (value) {
            // Logique pour activer/désactiver le capteur
          },
        ),
      ],
    );
  }

  Widget _buildRecentAlertsSection() {
    // Obtenir la liste des alertes du service
    final alerts = _sensorService.getAlerts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dernières alertes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 187, 183, 183),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                alerts.isEmpty
                    ? _buildEmptyAlertsState()
                    : Column(
                      children:
                          alerts.take(3).map((alert) {
                            IconData icon;
                            Color iconColor;

                            switch (alert.type) {
                              case AlertType.smoke:
                                icon = Icons.smoke_free;
                                iconColor = Colors.red;
                                break;
                              case AlertType.co2:
                                icon = Icons.cloud;
                                iconColor = Colors.orange;
                                break;
                              case AlertType.temperature: // Nouveau cas
                                icon =
                                    Icons
                                        .thermostat; // Icône spécifique pour la température
                                iconColor =
                                    Colors
                                        .red; // Couleur rouge pour indiquer la chaleur
                                break;
                              case AlertType.humidity: // Nouveau cas
                                icon =
                                    Icons
                                        .water_drop; // Icône spécifique pour l'humidité
                                iconColor =
                                    Colors.blue; // Couleur bleue pour l'eau
                                break;
                              case AlertType.test:
                                icon = Icons.check_circle;
                                iconColor = Colors.blue;
                                break;
                              case AlertType.falseAlarm:
                                icon = Icons.warning;
                                iconColor = Colors.amber;
                                break;
                              case AlertType.systemFailure:
                                icon = Icons.error;
                                iconColor = Colors.red;
                                break;
                              case AlertType.info:
                              default:
                                icon = Icons.info;
                                iconColor = Colors.blue;
                                break;
                            }

                            final date = _formatDate(alert.timestamp);

                            return _buildAlertItem(
                              icon: icon,
                              iconColor: iconColor,
                              title: alert.title,
                              status: alert.description,
                              date: date,
                            );
                          }).toList(),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAlertsState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            const Text(
              'Aucune alerte récente',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String status,
    required String date,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.2),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      subtitle: Text(status, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(date, style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        // Navigation vers les détails de l'alerte
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}
