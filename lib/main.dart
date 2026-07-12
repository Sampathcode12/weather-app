import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseInitialized = false;
  String? firebaseInitError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint('Firebase initialized successfully');
  } catch (error) {
    firebaseInitError = error.toString();
    debugPrint('Firebase initialization failed: $firebaseInitError');
  }

  runApp(WeatherApp(
    firebaseInitialized: firebaseInitialized,
    firebaseInitError: firebaseInitError,
  ));
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({
    super.key,
    required this.firebaseInitialized,
    this.firebaseInitError,
  });

  final bool firebaseInitialized;
  final String? firebaseInitError;

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  static const bool skipAuthGate = true;

  FirebaseAuth? _auth;
  bool _isSignedIn = false;
  bool _isCheckingAuth = true;
  bool _firebaseInitialized = false;
  String? _firebaseInitError;

  @override
  void initState() {
    super.initState();
    _firebaseInitialized = widget.firebaseInitialized;
    _firebaseInitError = widget.firebaseInitError;
    if (skipAuthGate) {
      _isSignedIn = true;
      _isCheckingAuth = false;
    } else {
      _restoreSession();
    }
  }

  Future<void> _retryFirebaseInit() async {
    if (!mounted) return;
    setState(() {
      _isCheckingAuth = true;
      _firebaseInitialized = false;
      _firebaseInitError = null;
    });

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (mounted) {
        setState(() {
          _firebaseInitialized = true;
          _firebaseInitError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _firebaseInitError = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
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

  Future<void> _handleSignIn(BuildContext ctx) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(ctx);
    if (!_firebaseInitialized) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Firebase is not initialized. Sign in is unavailable.'),
      ));
      return;
    }
    const adminEmail = 'Admin@gmail.com';
    const adminPassword = 'Admin@123';
    final navigator = Navigator.of(ctx);
    messenger.showSnackBar(const SnackBar(content: Text('Signing in as Admin...')));
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      if (mounted) setState(() => _isSignedIn = true);
    } on FirebaseAuthException catch (e) {
      // If automatic sign-in fails, open the sign-in form so user can try manually
      messenger.showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
      final result = await navigator.push<bool>(
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
      if (result == true && mounted) setState(() => _isSignedIn = true);
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in failed, opening form...')),
      );
      final result = await navigator.push<bool>(
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
      if (result == true && mounted) setState(() => _isSignedIn = true);
    }
  }

  Future<void> _handleSignUp(BuildContext ctx) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(ctx);
    if (!_firebaseInitialized) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Firebase is not initialized. Sign up is unavailable.'),
      ));
      return;
    }
    final navigator = Navigator.of(ctx);
    messenger.showSnackBar(const SnackBar(content: Text('Opening Sign Up...')));
    final result = await navigator.push<bool>(
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
    if (result == true && mounted) setState(() => _isSignedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
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
    if (skipAuthGate) {
      return const WeatherHomePage();
    }

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
              color: Color.fromRGBO(255, 255, 255, 0.08),
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
                      if (!_firebaseInitialized)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 82, 82, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _firebaseInitError == null
                                ? 'Warning: Firebase not initialized. Authentication may fail.'
                                : 'Firebase init failed: $_firebaseInitError',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
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
                      Builder(
                        builder: (ctx) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton.icon(
                                onPressed: _firebaseInitialized ? () => _handleSignIn(ctx) : null,
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
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _firebaseInitialized ? () => _handleSignUp(ctx) : null,
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
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: !_firebaseInitialized
          ? FloatingActionButton.extended(
              onPressed: _isCheckingAuth ? null : _retryFirebaseInit,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Firebase init'),
            )
          : null,
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
  String _selectedCity = 'San Francisco, CA';
  DateTime _selectedCityUpdatedAt = DateTime.now();

  List<Widget> get _pages => <Widget>[
        HomeScreen(
          city: _selectedCity,
          updatedAt: _selectedCityUpdatedAt,
          onSearchCity: () => setState(() => _currentIndex = 1),
        ),
        SearchScreen(onLocationSelected: _onLocationSelected),
        const HistoryScreen(),
      ];

  void _onLocationSelected(String city) {
    setState(() {
      _selectedCity = city;
      _selectedCityUpdatedAt = DateTime.now();
      _currentIndex = 0;
    });
  }

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

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(
    text: 'Admin@gmail.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'Admin@123',
  );
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      navigator.pop(true);
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text('Sign in failed')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _loading = false);
        return; // cancelled
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      navigator.pop(true);
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text('Google sign in failed')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter password' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _signInWithEmail,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Sign in with Email'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      navigator.pop(true);
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'email-already-in-use' =>
          'This email is already registered. Please sign in instead.',
        'invalid-email' => 'Enter a valid email address.',
        'weak-password' =>
          'Password is too weak. Use at least 6 characters.',
        'operation-not-allowed' =>
          'Email/password sign-up is not enabled in Firebase.',
        'invalid-api-key' =>
          'Firebase API key is invalid. Check your firebase_options.dart.',
        'network-request-failed' =>
          'Network error. Check your internet connection.',
        _ => e.message ?? e.code,
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Sign up failed: ${e.toString()}'),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      navigator.pop(true);
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'account-exists-with-different-credential' =>
          'An account already exists with a different sign-in method.',
        'invalid-credential' => 'Google sign-in failed. Try again.',
        'user-disabled' => 'This account has been disabled.',
        'operation-not-allowed' => 'Google sign-in is not enabled in Firebase.',
        'network-request-failed' =>
          'Network error. Check your internet connection.',
        _ => e.message ?? e.code,
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Google sign up failed: ${e.toString()}'),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Enter password (6+ chars)'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _signUpWithEmail,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Create account'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _signUpWithGoogle,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Continue with Google'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.city,
    required this.updatedAt,
    required this.onSearchCity,
  });

  final String city;
  final DateTime updatedAt;
  final VoidCallback onSearchCity;

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

  String get _formattedUpdateTime {
    final hour = updatedAt.hour == 0 ? 12 : (updatedAt.hour > 12 ? updatedAt.hour - 12 : updatedAt.hour);
    final minute = updatedAt.minute.toString().padLeft(2, '0');
    final period = updatedAt.hour >= 12 ? 'PM' : 'AM';
    return 'Updated today · $hour:$minute $period';
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
                children: [
                  Text(
                    city,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formattedUpdateTime,
                    style: const TextStyle(fontSize: 14, color: Colors.white60),
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
        _actionButton(context, Icons.gps_fixed, 'Auto GPS', null),
        _actionButton(context, Icons.search, 'Search City', onSearchCity),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
                  border: Border.all(
                    color: Color.fromRGBO(255, 255, 255, 0.08),
                  ),
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

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.onLocationSelected,
  });

  final ValueChanged<String> onLocationSelected;

  static const recentLocations = [
    'New York, USA',
    'London, United Kingdom',
    'Tokyo, Japan',
  ];
  static const suggestions = [
    'Paris, France',
    'Los Angeles, USA',
    'Sydney, Australia',
    'Mumbai, India',
    'Berlin, Germany',
    'Toronto, Canada',
    'Cape Town, South Africa',
    'Seoul, South Korea',
  ];

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isSearching = false;
  String? _searchError;
  List<String> _searchResults = [];
  Timer? _debounce;

  Future<void> _searchLocations() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }

    setState(() {
      _query = query;
      _isSearching = true;
      _searchError = null;
      _searchResults = [];
    });

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': query,
          'format': 'json',
          'limit': '20',
          'addressdetails': '1',
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'weather-app/1.0 (contact: example@example.com)',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Unexpected status code ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      final results = data
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final displayName = item['display_name'] as String?;
            final placeType = item['type'] as String?;
            if (displayName == null) return null;
            return placeType == null
                ? displayName
                : '$displayName (${placeType.toUpperCase()})';
          })
          .whereType<String>()
          .toList();
      setState(() {
        _searchResults = results;
      });
    } catch (error) {
      setState(() {
        _searchError = 'Search failed: ${error.toString()}';
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectLocation(String location) {
    widget.onLocationSelected(location);
  }

  void _onSearchQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _query = value;
      _searchError = null;
    });

    if (value.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _searchLocations();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

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
            'Search City or Country',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Find weather for any city or country quickly',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.1)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white70),
                  onPressed: _searchLocations,
                ),
                hintText: 'Search city or country',
                hintStyle: const TextStyle(color: Colors.white54),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onChanged: _onSearchQueryChanged,
              onSubmitted: (_) => _searchLocations(),
            ),
          ),
          const SizedBox(height: 24),
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _searchError!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          Expanded(
            child: ListView(
              children: [
                if (_query.isEmpty) ...[
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
                    children: SearchScreen.recentLocations
                        .map(
                          (location) => ActionChip(
                            label: Text(
                              location,
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Color.fromRGBO(255, 255, 255, 0.08),
                            onPressed: () => _selectLocation(location),
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
                ],
                ..._searchResults.map(
                  (city) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(255, 255, 255, 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color.fromRGBO(255, 255, 255, 0.08),
                      ),
                    ),
                    child: ListTile(
                      onTap: () => _selectLocation(city),
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
                ),
                if (_query.isNotEmpty && !_isSearching && _searchResults.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(255, 255, 255, 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'No matching locations found.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
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
                    border: Border.all(
                      color: Color.fromRGBO(255, 255, 255, 0.08),
                    ),
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
