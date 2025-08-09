import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spor Programı Uygulaması',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Colors.blueAccent,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const CheckProfileScreen();
          }
          return const WelcomeScreen();
        },
      ),
    );
  }
}

class CheckProfileScreen extends StatelessWidget {
  const CheckProfileScreen({super.key});

  Future<bool> _isProfileCompleted() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    return userDoc.exists && (userDoc.data() as Map<String, dynamic>).containsKey('profile_completed');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isProfileCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return const MainWrapper();
        } else {
          return const UserProfileForm();
        }
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.fitness_center,
                size: 120.0,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                'Spor Programı Uygulamasına Hoş Geldiniz',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kişiye özel antrenman programları oluşturarak hedeflerinize ulaşın.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                    );
                  },
                  child: const Text('Başlayın'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Zaten hesabım var',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt başarılı! Şimdi profilinizi oluşturun.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserProfileForm()),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'Şifre çok zayıf.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta zaten kullanımda.';
      } else {
        message = 'Bir hata oluştu: ${e.message}';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      child: const Text('Kayıt Ol'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const CheckProfileScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'Kullanıcı bulunamadı.';
      } else if (e.code == 'wrong-password') {
        message = 'Yanlış şifre.';
      } else {
        message = 'Bir hata oluştu: ${e.message}';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giriş Yap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: const Text('Giriş Yap'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class UserProfileForm extends StatefulWidget {
  const UserProfileForm({super.key});

  @override
  State<UserProfileForm> createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _gender = 'Erkek';
  String _fitnessGoal = 'Kilo Verme';
  String _activityLevel = 'Hafif Aktif';
  String _equipmentAccess = 'Evde (Vücut Ağırlığı)';

  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': _nameController.text,
            'age': int.tryParse(_ageController.text),
            'height': int.tryParse(_heightController.text),
            'weight': int.tryParse(_weightController.text),
            'gender': _gender,
            'fitness_goal': _fitnessGoal,
            'activity_level': _activityLevel,
            'equipment_access': _equipmentAccess,
            'profile_completed': true,
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil başarıyla kaydedildi!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainWrapper()),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil kaydedilirken bir hata oluştu: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilini Oluştur'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Adın'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen adınızı girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Yaşın'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || int.tryParse(value) == null) {
                          return 'Lütfen geçerli bir yaş girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(labelText: 'Boyun (cm)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || int.tryParse(value) == null) {
                          return 'Lütfen geçerli bir boy girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Kilon (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || int.tryParse(value) == null) {
                          return 'Lütfen geçerli bir kilo girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Cinsiyet'),
                      items: ['Erkek', 'Kadın', 'Belirtmek İstemiyor']
                          .map((String value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _gender = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: _fitnessGoal,
                      decoration: const InputDecoration(labelText: 'Fitness Hedefin'),
                      items: ['Kilo Verme', 'Kas Geliştirme', 'Genel Fitness']
                          .map((String value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _fitnessGoal = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: _activityLevel,
                      decoration: const InputDecoration(labelText: 'Aktivite Seviyen'),
                      items: ['Hafif Aktif', 'Orta Aktif', 'İleri Seviye']
                          .map((String value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _activityLevel = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: _equipmentAccess,
                      decoration: const InputDecoration(labelText: 'Ekipman Erişimin'),
                      items: ['Evde (Vücut Ağırlığı)', 'Spor Salonu']
                          .map((String value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _equipmentAccess = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Profili Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    MainWorkoutScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Antrenman',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'İlerleme',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class MainWorkoutScreen extends StatefulWidget {
  const MainWorkoutScreen({super.key});

  @override
  State<MainWorkoutScreen> createState() => _MainWorkoutScreenState();
}

class _MainWorkoutScreenState extends State<MainWorkoutScreen> {
  List<dynamic>? _workoutProgram;
  bool _isLoading = true;
  String? _errorMessage;

  Map<int, List<bool>> _completionStatus = {};

  @override
  void initState() {
    super.initState();
    _fetchAndLoadWorkoutProgram();
  }

  Future<void> _fetchAndLoadWorkoutProgram() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _completionStatus = {};
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists || !(userDoc.data() as Map<String, dynamic>).containsKey('profile_completed')) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserProfileForm()),
        );
        return;
      }

      var userData = userDoc.data() as Map<String, dynamic>;
      String fitnessGoal = userData['fitness_goal'] ?? 'Genel Fitness';
      String activityLevel = userData['activity_level'] ?? 'Orta Aktif';
      String equipmentAccess = userData['equipment_access'] ?? 'Spor Salonu';

      QuerySnapshot programQuery = await FirebaseFirestore.instance
          .collection('workout_programs')
          .where('target', isEqualTo: fitnessGoal)
          .where('level', isEqualTo: activityLevel)
          .where('equipment', isEqualTo: equipmentAccess)
          .limit(1)
          .get();

      if (programQuery.docs.isNotEmpty) {
        _workoutProgram = programQuery.docs.first['days'] as List<dynamic>;
      } else {
        _workoutProgram = [
          {
            "day_name": "Genel Antrenman",
            "exercises": [
              {
                "name": "Şınav",
                "details": "3x10",
                "description": "Göğüs, omuz ve triceps kaslarını çalıştıran temel bir vücut ağırlığı egzersizi.",
                "video_url": "https://www.youtube.com/watch?v=IODxDxX7oi4"
              },
              {
                "name": "Squat",
                "details": "3x12",
                "description": "Bacak ve kalça kaslarını çalıştıran temel bir egzersiz.",
                "video_url": "https://www.youtube.com/watch?v=aclHFWD_pT8"
              }
            ]
          }
        ];
        _errorMessage = 'Seviyenize uygun özel bir program bulunamadı. Genel bir program yüklendi.';
      }
      
      _workoutProgram?.asMap().forEach((dayIndex, dayData) {
        _completionStatus[dayIndex] = List<bool>.filled((dayData['exercises'] as List).length, false);
      });

    } catch (e) {
      _errorMessage = 'Program yüklenirken bir hata oluştu: ${e.toString()}';
      // ignore: avoid_print
      print('Program yükleme hatası: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL açılamadı: $uri')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenman Programım'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAndLoadWorkoutProgram,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blueAccent, size: 60),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.blueAccent, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchAndLoadWorkoutProgram,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: _workoutProgram?.length ?? 0,
                    itemBuilder: (context, dayIndex) {
                      var dayData = _workoutProgram![dayIndex] as Map<String, dynamic>;
                      List<dynamic> exercises = dayData['exercises'] as List<dynamic>;

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ExpansionTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                          title: Text(
                            dayData['day_name'] ?? 'Antrenman Günü',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          children: exercises.asMap().entries.map((entry) {
                            int exerciseIndex = entry.key;
                            var exercise = entry.value as Map<String, dynamic>;
                            bool isCompleted = _completionStatus[dayIndex]?[exerciseIndex] ?? false;

                            return ListTile(
                              leading: Checkbox(
                                value: isCompleted,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    if (_completionStatus[dayIndex] != null) {
                                      _completionStatus[dayIndex]![exerciseIndex] = newValue!;
                                    }
                                  });
                                },
                              ),
                              title: Text(
                                exercise['name'] ?? 'Egzersiz',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                              subtitle: Text(
                                '${exercise['details'] ?? 'Set/Tekrar'} - ${exercise['description'] ?? ''}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.play_circle_outline, color: Colors.red),
                                onPressed: () {
                                  _launchUrl(exercise['video_url'] ?? 'https://www.youtube.com/');
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveWeight() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      double? newWeight = double.tryParse(_weightController.text);
      if (newWeight == null) return;

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('weight_history')
            .add({
          'weight': newWeight,
          'date': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kilo başarıyla kaydedildi!')),
        );
        _weightController.clear();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kilo kaydedilirken bir hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Giriş yapmalısınız.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlerleme Takibi'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          decoration: const InputDecoration(
                            labelText: 'Kilo (kg)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen kilonuzu girin';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Geçerli bir sayı girin';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _saveWeight,
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Kilo Geçmişi:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('weight_history')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Henüz kilo kaydı yok.'));
                  }

                  List<DocumentSnapshot> weights = snapshot.data!.docs;

                  if (weights.length < 2) {
                    return Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'En az iki kilo verisi girerek grafiği görebilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            itemCount: weights.length,
                            itemBuilder: (context, index) {
                              var data = weights[index].data() as Map<String, dynamic>;
                              var timestamp = data['date'] as Timestamp?;
                              DateTime date = timestamp?.toDate() ?? DateTime.now();
                              return ListTile(
                                leading: const Icon(Icons.scale, color: Colors.blueAccent),
                                title: Text('${data['weight']} kg'),
                                subtitle: Text(
                                  'Tarih: ${date.day}/${date.month}/${date.year}',
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  List<FlSpot> spots = weights.reversed.toList().asMap().entries.map((entry) {
                    int index = entry.key;
                    var data = entry.value.data() as Map<String, dynamic>;
                    double weight = (data['weight'] as num).toDouble();
                    return FlSpot(index.toDouble(), weight);
                  }).toList();

                  double minWeight = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
                  double maxWeight = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Text(
                          'Kilo Grafiği',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 250,
                          child: LineChart(
                            LineChartData(
                              minY: minWeight - 2,
                              maxY: maxWeight + 2,
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      if (value.toInt() < weights.length) {
                                        var data = weights.reversed.toList()[value.toInt()].data() as Map<String, dynamic>;
                                        var timestamp = data['date'] as Timestamp?;
                                        DateTime date = timestamp?.toDate() ?? DateTime.now();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            '${date.day}.${date.month}',
                                            style: const TextStyle(fontSize: 10, color: Colors.black),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                  ),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawHorizontalLine: true,
                                verticalInterval: 1,
                                horizontalInterval: 2,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.3),
                                  strokeWidth: 1,
                                ),
                                getDrawingVerticalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.3),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: const Color(0xff37434d), width: 1),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: Colors.blueAccent,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.blueAccent.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Giriş yapmalısınız.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profil verisi bulunamadı.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Center(
                  child: Icon(
                    Icons.account_circle,
                    size: 120,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 20),
                _buildProfileItem(Icons.person, 'Ad', userData['name'] ?? 'N/A'),
                _buildProfileItem(Icons.cake, 'Yaş', userData['age']?.toString() ?? 'N/A'),
                _buildProfileItem(Icons.height, 'Boy', '${userData['height']?.toString() ?? 'N/A'} cm'),
                _buildProfileItem(Icons.monitor_weight, 'Kilo', '${userData['weight']?.toString() ?? 'N/A'} kg'),
                _buildProfileItem(Icons.wc, 'Cinsiyet', userData['gender'] ?? 'N/A'),
                _buildProfileItem(Icons.flag, 'Hedef', userData['fitness_goal'] ?? 'N/A'),
                _buildProfileItem(Icons.fitness_center, 'Seviye', userData['activity_level'] ?? 'N/A'),
                _buildProfileItem(Icons.category, 'Ekipman', userData['equipment_access'] ?? 'N/A'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _gender = 'Erkek';
  String _fitnessGoal = 'Kilo Verme';
  String _activityLevel = 'Hafif Aktif';
  String _equipmentAccess = 'Evde (Vücut Ağırlığı)';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        _nameController.text = userData['name'] ?? '';
        _ageController.text = userData['age']?.toString() ?? '';
        _heightController.text = userData['height']?.toString() ?? '';
        _weightController.text = userData['weight']?.toString() ?? '';
        _gender = userData['gender'] ?? 'Erkek';
        _fitnessGoal = userData['fitness_goal'] ?? 'Kilo Verme';
        
        String fetchedActivityLevel = userData['activity_level'] ?? 'Hafif Aktif';
        if (['Yeni Başlayan', 'Hafif Aktif'].contains(fetchedActivityLevel)) {
          _activityLevel = 'Hafif Aktif';
        } else if (fetchedActivityLevel == 'Orta Aktif') {
          _activityLevel = 'Orta Aktif';
        } else if (fetchedActivityLevel == 'İleri Seviye') {
          _activityLevel = 'İleri Seviye';
        } else {
          _activityLevel = 'Hafif Aktif';
        }

        _equipmentAccess = userData['equipment_access'] ?? 'Evde (Vücut Ağırlığı)';
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'name': _nameController.text,
            'age': int.tryParse(_ageController.text),
            'height': int.tryParse(_heightController.text),
            'weight': int.tryParse(_weightController.text),
            'gender': _gender,
            'fitness_goal': _fitnessGoal,
            'activity_level': _activityLevel,
            'equipment_access': _equipmentAccess,
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil başarıyla güncellendi!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil güncellenirken bir hata oluştu: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Adın'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen adınızı girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Yaşın'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || int.tryParse(value) == null) {
                          return 'Lütfen geçerli bir yaş girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(labelText: 'Boyun (cm)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || int.tryParse(value) == null) {
                          return 'Lütfen geçerli bir boy girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Kilon (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || int.tryParse(value) == null) {
                          return 'Lütfen geçerli bir kilo girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Cinsiyet'),
                      items: ['Erkek', 'Kadın', 'Belirtmek İstemiyor']
                          .map((String value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _gender = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: _fitnessGoal,
                      decoration: const InputDecoration(labelText: 'Fitness Hedefin'),
                      items: ['Kilo Verme', 'Kas Geliştirme', 'Genel Fitness']
                          .map((String value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _fitnessGoal = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: _activityLevel,
                      decoration: const InputDecoration(labelText: 'Aktivite Seviyen'),
                      items: ['Hafif Aktif', 'Orta Aktif', 'İleri Seviye']
                          .map((String value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _activityLevel = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: _equipmentAccess,
                      decoration: const InputDecoration(labelText: 'Ekipman Erişimin'),
                      items: ['Evde (Vücut Ağırlığı)', 'Spor Salonu']
                          .map((String value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _equipmentAccess = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        child: const Text('Profili Güncelle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}