import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }

  runApp(const WeatherApp());
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  FirebaseAuth? _auth;
  bool _isSignedIn = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      _auth = FirebaseAuth.instance;
      final currentUser = _auth?.currentUser;
      if (mounted) {
        setState(() {
          _isSignedIn = currentUser != null;
          _isCheckingAuth = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in flow will be connected to Firebase next.')),
    );
  }

  Future<void> _handleSignUp() async {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign up flow will be connected to Firebase next.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather Forecast',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1330),
        textTheme: Typography.whiteMountainView,
      ),
      home: _isSignedIn ? const WeatherHomePage() : _buildSignInGate(),
    );
  }

  Widget _buildSignInGate() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A152F), Color(0xFF0B193E)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: Colors.white.withOpacity(0.08),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in or create an account to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _handleSignIn,
                        icon: const Icon(Icons.login, size: 20),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Sign In'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _handleSignUp,
                        icon: const Icon(Icons.person_add, size: 20),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Sign Up'),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white70),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    SearchScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Color.fromRGBO(0, 0, 0, 0.35),
        surfaceTintColor: Colors.transparent,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const details = [
    {'label': 'Humidity', 'value': '72%', 'icon': Icons.water_drop},
    {'label': 'Wind', 'value': '7 mph', 'icon': Icons.air},
    {'label': 'Pressure', 'value': '1018 hPa', 'icon': Icons.show_chart},
    {'label': 'Visibility', 'value': '10 mi', 'icon': Icons.remove_red_eye},
  ];

  static const forecast = [
    {'day': 'Mon', 'icon': Icons.wb_sunny, 'min': 57, 'max': 71},
    {'day': 'Tue', 'icon': Icons.cloud, 'min': 59, 'max': 69},
    {'day': 'Wed', 'icon': Icons.cloud_queue, 'min': 58, 'max': 66},
    {'day': 'Thu', 'icon': Icons.umbrella, 'min': 55, 'max': 63},
    {'day': 'Fri', 'icon': Icons.wb_sunny, 'min': 61, 'max': 74},
    {'day': 'Sat', 'icon': Icons.cloud, 'min': 60, 'max': 68},
    {'day': 'Sun', 'icon': Icons.wb_sunny, 'min': 62, 'max': 75},
  ];

  String get _formattedDate {
    final now = DateTime.now();
    final weekday = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ][now.weekday - 1];
    return '$weekday · ${now.month}/${now.day}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A152F), Color(0xFF0B193E)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          const SizedBox(height: 6),
          _buildHeader(),
          const SizedBox(height: 20),
          _buildLocationActions(context),
          const SizedBox(height: 24),
          _buildCurrentWeatherCard(),
          const SizedBox(height: 24),
          _buildWeatherDetails(),
          const SizedBox(height: 24),
          _buildForecastSection(),
          const SizedBox(height: 24),
          _buildExtendedForecast(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Location',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'San Francisco, CA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Updated today · 9:45 AM',
                    style: TextStyle(fontSize: 14, color: Colors.white60),
                  ),
                ],
              ),
            ),
            const Icon(Icons.location_on, color: Colors.white70, size: 28),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionButton(context, Icons.gps_fixed, 'Auto GPS'),
        _actionButton(context, Icons.search, 'Search City'),
      ],
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.08)),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0x66FFFFFF), Color(0x14FFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0x33FFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.cloud, size: 42, color: Colors.white),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '68°',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Partly Cloudy',
                      style: TextStyle(fontSize: 20, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _metricTile('High', '72°'),
              const SizedBox(width: 12),
              _metricTile('Low', '59°'),
              const SizedBox(width: 12),
              _metricTile('Feels Like', '67°'),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _formattedDate,
              style: const TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weather Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: details
              .map(
                (detail) => _detailCard(
                  label: detail['label'] as String,
                  value: detail['value'] as String,
                  icon: detail['icon'] as IconData,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _detailCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Color.fromRGBO(255, 255, 255, 0.08),
          border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.09)),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '7-Day Forecast',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: forecast.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final day = forecast[index];
              return Container(
                width: 110,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Color.fromRGBO(255, 255, 255, 0.08),
                  border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.08)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day['day'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Icon(
                      day['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                    Text(
                      '${day['max']}° / ${day['min']}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExtendedForecast() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0x33FFFFFF), Color(0x14FFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extended Forecast',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Based on predictive modeling',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Tomorrow',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '71°',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.wb_sunny, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sunny',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.show_chart, color: Colors.greenAccent, size: 40),
            ],
          ),
          const SizedBox(height: 20),
          const TemperatureTrendChart(),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _TrendLabel(label: '3-Day trend', value: 'Mild'),
              _TrendLabel(label: '7-Day outlook', value: 'Stable'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendLabel extends StatelessWidget {
  const _TrendLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class TemperatureTrendChart extends StatelessWidget {
  const TemperatureTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 0.04),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _TrendPainter())),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(size.width * 0.08, size.height * 0.76),
      Offset(size.width * 0.25, size.height * 0.62),
      Offset(size.width * 0.42, size.height * 0.54),
      Offset(size.width * 0.59, size.height * 0.64),
      Offset(size.width * 0.76, size.height * 0.48),
      Offset(size.width * 0.92, size.height * 0.58),
    ];

    final linePaint = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Color.fromRGBO(173, 216, 230, 0.18)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final dotPaint = Paint()..color = Colors.white;
    final innerDotPaint = Paint()..color = Colors.lightBlueAccent;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 8, dotPaint);
      canvas.drawCircle(point, 4, innerDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  static const recentLocations = ['New York', 'London', 'Tokyo'];
  static const suggestions = ['Paris', 'Los Angeles', 'Sydney', 'Mumbai'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B193E), Color(0xFF091225)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search City',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Find weather for any location quickly',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.1)),
            ),
            child: const TextField(
              style: TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                hintText: 'Search city name',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Recent locations',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: recentLocations
                .map(
                  (location) => Chip(
                    label: Text(
                      location,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Color.fromRGBO(255, 255, 255, 0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          const Text(
            'Suggested cities',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: suggestions
                .map(
                  (city) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(255, 255, 255, 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.08)),
                    ),
                    child: ListTile(
                      title: Text(
                        city,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.keyboard_arrow_right,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const historyItems = [
    {
      'date': 'Jun 30',
      'temp': '70°',
      'condition': 'Sunny',
      'icon': Icons.wb_sunny,
    },
    {
      'date': 'Jun 29',
      'temp': '65°',
      'condition': 'Cloudy',
      'icon': Icons.cloud,
    },
    {
      'date': 'Jun 28',
      'temp': '62°',
      'condition': 'Rain',
      'icon': Icons.umbrella,
    },
    {'date': 'Jun 27', 'temp': '68°', 'condition': 'Windy', 'icon': Icons.air},
    {
      'date': 'Jun 26',
      'temp': '64°',
      'condition': 'Foggy',
      'icon': Icons.remove_red_eye,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B193E), Color(0xFF091225)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weather History',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Review recent conditions and temperature trends',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: historyItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = historyItems[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.07),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 255, 255, 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['date'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['condition'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item['temp'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

