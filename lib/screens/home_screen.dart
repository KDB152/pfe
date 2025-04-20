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
import '../utils/constants.dart';
import 'dart:ui';

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
  Timer? _debounceTimer;

  final List<double> _temperatureData = List.generate(20, (_) => 22.0);
  final List<double> _humidityData = List.generate(20, (_) => 45.0);
  final List<double> _smokeData = List.generate(20, (_) => 0.0);
  final List<double> _co2Data = List.generate(20, (_) => 0.0);

  late final AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkAdminStatus();

    _sensorService.initialize().then((_) {
      _sensorSubscription = _sensorService.sensorDataStream.listen((data) {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(Duration(milliseconds: 500), () {
          _onSensorDataUpdate(data);
        });
      });
      _loadSensorData();
    });
  }

  @override
  void dispose() {
    _sensorSubscription.cancel();
    _debounceTimer?.cancel();
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
    if (_sensorData == null || _hasSignificantChange(_sensorData!, data)) {
      setState(() {
        _sensorData = data;
        _isLoading = false;
        _updateChartData(data);
      });

      _animationController.reset();
      _animationController.forward();
    }
  }

  bool _hasSignificantChange(SensorData oldData, SensorData newData) {
    const double threshold = 0.5;
    return (oldData.temperature - newData.temperature).abs() > threshold ||
        (oldData.humidity - newData.humidity).abs() > threshold ||
        (oldData.smoke - newData.smoke).abs() > threshold ||
        (oldData.co2 - newData.co2).abs() > threshold;
  }

  void _updateChartData(SensorData data) {
    _temperatureData.removeAt(0);
    _temperatureData.add(data.temperature);

    _humidityData.removeAt(0);
    _humidityData.add(data.humidity);

    _smokeData.removeAt(0);
    _smokeData.add(data.smoke * 100);

    _co2Data.removeAt(0);
    _co2Data.add(data.co2);
  }

  Future<void> _loadSensorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _sensorService.getLastSensorData();
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
    final double contentPadding = AppSizes.contentPadding(context);
    final double spacingLarge = AppSizes.height(context, 0.025);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détecteur Incendie',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppSizes.titleFontSize(context),
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD43C38).withOpacity(0.8),
                Color(0xFFFF8A65).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: FireDetectionBackground(
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF8A65),
                    strokeWidth: 3,
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _loadSensorData,
                  color: Color(0xFFFF8A65),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(contentPadding),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUserInfoCard(),
                          SizedBox(height: spacingLarge),
                          _buildSensorDataCards(),
                          SizedBox(height: spacingLarge),
                          _buildCharts(),
                          SizedBox(height: spacingLarge),
                          _buildSystemStatusSection(),
                          SizedBox(height: spacingLarge),
                          _buildRecentAlertsSection(),
                        ],
                      ),
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
            Text(
              'Mesures en temps réel',
              style: TextStyle(
                fontSize: AppSizes.titleFontSize(context) * 0.9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: AppSizes.height(context, 0.015)),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSensorDataCard(
                  title: 'Probabilité d\'Incendie',
                  value: '${(_sensorData!.smoke).toStringAsFixed(1)} %',
                  icon: Icons.local_fire_department_outlined,
                  color: Colors.grey.shade400,
                  animation: _animationController,
                ),
                _buildSensorDataCard(
                  title: 'Température',
                  value: '${_sensorData!.temperature} °C',
                  icon: Icons.thermostat,
                  color: Color(0xFFD43C38),
                  animation: _animationController,
                ),
                _buildSensorDataCard(
                  title: 'Humidité',
                  value: '${_sensorData!.humidity} %',
                  icon: Icons.water_drop,
                  color: Colors.blueAccent,
                  animation: _animationController,
                ),
                _buildSensorDataCard(
                  title: 'Gaz',
                  value: '${(_sensorData!.co2).toStringAsFixed(1)} ppm',
                  icon: Icons.cloud,
                  color: Colors.greenAccent,
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
    // Vérifier si c'est la carte "Probabilité Incendie" pour ajuster la taille
    final bool isProbabiliteIncendie = title == 'Probabilité d\'Incendie';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 36),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign:
                      isProbabiliteIncendie
                          ? TextAlign.center
                          : TextAlign.start,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:
                        isProbabiliteIncendie
                            ? AppSizes.bodyFontSize(context) *
                                0.91 // Plus petit pour "Probabilité Incendie"
                            : AppSizes.bodyFontSize(context),
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
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
                          fontSize: AppSizes.subtitleFontSize(context),
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontFamily: 'Inter',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Évolution des données',
          style: TextStyle(
            fontSize: AppSizes.titleFontSize(context) * 0.9,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: AppSizes.height(context, 0.015)),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
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
          ),
        ),
      ],
    );
  }

  int _selectedTabIndex = 0;
  final List<String> _tabTitles = [
    'Température',
    'Humidité',
    'Gaz',
    'Probabilité d\incendie',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient:
                    isSelected
                        ? LinearGradient(
                          colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
                        )
                        : null,
                color: !isSelected ? Colors.white.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  _tabTitles[index],
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.8),
                    fontWeight:
                        isSelected
                            ? FontWeight.w700
                            : FontWeight.w500, // Corrected parameter
                    fontFamily: 'Inter',
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
        label = 'Température';
        color = Color(0xFFD43C38);
        unit = '°C';
        break;
      case 1:
        data = _humidityData;
        label = 'Humidité';
        color = Colors.blueAccent;
        unit = '%';
        break;
      case 2:
        data = _smokeData;
        label = 'Probabilité d\incendie';
        color = Colors.grey.shade400;
        unit = '%';
        break;
      case 3:
        data = _co2Data;
        label = 'CO2';
        color = Colors.greenAccent;
        unit = 'ppm';
        break;
      default:
        data = _temperatureData;
        label = 'Température';
        color = Color(0xFFD43C38);
        unit = '°C';
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval:
              (data.reduce((a, b) => a > b ? a : b) / 5).ceilToDouble(),
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Inter',
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval:
                  (data.reduce((a, b) => a > b ? a : b) / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Inter',
                  ),
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
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
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
                  TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
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
      backgroundColor: Colors.black.withOpacity(0.9),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Icon(
                    _isAdmin
                        ? Icons.admin_panel_settings
                        : Icons.local_fire_department,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Détecteur Incendie',
                  style: TextStyle(
                    fontSize: AppSizes.titleFontSize(context) * 0.9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home,
            title: 'Accueil',
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          if (_isAdmin)
            _buildDrawerItem(
              icon: Icons.people,
              title: 'Gestion des utilisateurs',
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
          _buildDrawerItem(
            icon: Icons.notifications,
            title: 'Notifications',
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
          _buildDrawerItem(
            icon: Icons.videocam,
            iconColor: Color(0xFFFF8A65),
            title: 'Visualiser le local',
            onTap: () {
              Navigator.pushNamed(context, '/live-view');
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Paramètres',
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
          if (!_isAdmin)
            _buildDrawerItem(
              icon: Icons.help,
              title: 'Aide & Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/Aide & Support');
              },
            ),
          if (_isAdmin)
            _buildDrawerItem(
              icon: Icons.comment,
              title: 'Commentaires utilisateurs',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/users-comments');
              },
            ),
          const Divider(color: Colors.white30),
          _buildDrawerItem(
            icon: Icons.logout,
            iconColor: Color(0xFFD43C38),
            title: 'Déconnexion',
            titleColor: Color(0xFFD43C38),
            onTap: () async {
              Navigator.pop(context);

              bool confirmLogout =
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.black87,
                        title: Text(
                          'Confirmation',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                        content: Text(
                          'Êtes-vous sûr de vouloir vous déconnecter?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Inter',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              'Déconnexion',
                              style: TextStyle(
                                color: Color(0xFFD43C38),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ) ??
                  false;

              if (confirmLogout) {
                try {
                  final authService = AuthService();
                  await authService.signOut();

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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? titleColor,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (selected ? Color(0xFFFF8A65) : Colors.white70),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? (selected ? Color(0xFFFF8A65) : Colors.white70),
          fontFamily: 'Inter',
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: selected,
      onTap: onTap,
    );
  }

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

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          _isAdmin ? Color(0xFFD43C38) : Color(0xFFFF8A65),
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
                              fontWeight: FontWeight.w700,
                              fontSize: AppSizes.subtitleFontSize(context),
                              color:
                                  _isAdmin ? Color(0xFFD43C38) : Colors.white,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            _authService.getCurrentUserEmail(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
        Text(
          'État du système',
          style: TextStyle(
            fontSize: AppSizes.titleFontSize(context) * 0.9,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: AppSizes.height(context, 0.015)),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSensorStatusItem(
                      icon: Icons.smoke_free,
                      title: 'Détecteur de fumée',
                      isActive: true,
                    ),
                    const Divider(color: Colors.white30),
                    _buildSensorStatusItem(
                      icon: Icons.thermostat,
                      title: 'Détecteur de chaleur',
                      isActive: true,
                    ),
                    const Divider(color: Colors.white30),
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
                              ? Color(0xFFD43C38)
                              : Color(0xFFFF8A65),
                    ),
                  ],
                ),
              ),
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
          backgroundColor: Colors.white.withOpacity(0.1),
          child: Icon(
            icon,
            color: isActive ? Colors.greenAccent : Color(0xFFFF8A65),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                status ?? (isActive ? 'Actif' : 'Inactif'),
                style: TextStyle(
                  color:
                      statusColor ??
                      (isActive ? Colors.greenAccent : Color(0xFFFF8A65)),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: isActive,
          activeColor: Colors.greenAccent,
          inactiveThumbColor: Color(0xFFFF8A65),
          onChanged: (value) {
            // Logique pour activer/désactiver le capteur
          },
        ),
      ],
    );
  }

  Widget _buildRecentAlertsSection() {
    final alerts = _sensorService.getAlerts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dernières alertes',
              style: TextStyle(
                fontSize: AppSizes.titleFontSize(context) * 0.9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Inter',
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
              child: Text(
                'Voir tout',
                style: TextStyle(
                  color: Color(0xFFFF8A65),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizes.height(context, 0.015)),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
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
                                    iconColor = Color(0xFFD43C38);
                                    break;
                                  case AlertType.co2:
                                    icon = Icons.cloud;
                                    iconColor = Color(0xFFFF8A65);
                                    break;
                                  case AlertType.temperature:
                                    icon = Icons.thermostat;
                                    iconColor = Color(0xFFD43C38);
                                    break;
                                  case AlertType.humidity:
                                    icon = Icons.water_drop;
                                    iconColor = Colors.blueAccent;
                                    break;
                                  case AlertType.test:
                                    icon = Icons.check_circle;
                                    iconColor = Colors.blueAccent;
                                    break;
                                  case AlertType.falseAlarm:
                                    icon = Icons.warning;
                                    iconColor = Colors.amber;
                                    break;
                                  case AlertType.systemFailure:
                                    icon = Icons.error;
                                    iconColor = Color(0xFFD43C38);
                                    break;
                                  case AlertType.info:
                                  default:
                                    icon = Icons.info;
                                    iconColor = Colors.blueAccent;
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
            Icon(
              Icons.notifications_off,
              size: 40,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune alerte récente',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'Inter',
              ),
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
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
      subtitle: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontFamily: 'Inter',
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            date,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.6)),
        ],
      ),
      onTap: () {
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
