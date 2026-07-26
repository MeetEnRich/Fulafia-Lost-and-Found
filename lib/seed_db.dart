import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lost_and_found/firebase_options.dart';
import 'package:lost_and_found/config/constants.dart';
import 'package:lost_and_found/models/item_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SeedingApp());
}

class SeedingApp extends StatelessWidget {
  const SeedingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const SeedingScreen(),
    );
  }
}

class SeedingScreen extends StatefulWidget {
  const SeedingScreen({super.key});

  @override
  State<SeedingScreen> createState() => _SeedingScreenState();
}

class _SeedingScreenState extends State<SeedingScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSeeding = false;
  bool _isLoggingIn = false;
  String _status = 'You must log in to seed data.';
  int _count = 0;
  User? _currentUser;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _status = 'Logged in as: ${_currentUser!.email}\nReady to seed data.';
    }
  }

  Future<void> _login() async {
    setState(() => _isLoggingIn = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() {
        _currentUser = credential.user;
        _status = 'Logged in as: ${_currentUser!.email}\nReady to seed data.';
      });
    } catch (e) {
      setState(() => _status = 'Login failed: $e');
    } finally {
      setState(() => _isLoggingIn = false);
    }
  }

  final Map<String, List<String>> _imageMap = {
    'Electronics': [
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=500',
      'https://images.unsplash.com/photo-1585060544812-6b45742d762f?q=80&w=500',
      'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?q=80&w=500',
    ],
    'ID Cards & Documents': [
      'https://images.unsplash.com/photo-1590402444681-cd1346765870?q=80&w=500',
    ],
    'Keys': [
      'https://images.unsplash.com/photo-1582139329536-e7284fece509?q=80&w=500',
      'https://images.unsplash.com/photo-1620914972412-25916053335b?q=80&w=500',
    ],
    'Books & Stationery': [
      'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?q=80&w=500',
      'https://images.unsplash.com/photo-1532012197367-6849412a57ce?q=80&w=500',
    ],
    'Bags & Backpacks': [
      'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?q=80&w=500',
      'https://images.unsplash.com/photo-1547949003-9792a18a2601?q=80&w=500',
    ],
    'Clothing & Accessories': [
      'https://images.unsplash.com/photo-1520975916090-3105956dac38?q=80&w=500',
    ],
    'Wallets & Purses': [
      'https://images.unsplash.com/photo-1627123424574-724758594e93?q=80&w=500',
    ],
    'Jewellery & Watches': [
      'https://images.unsplash.com/photo-1524592094714-0f0654e20314?q=80&w=500',
    ],
    'Water Bottles & Containers': [
      'https://images.unsplash.com/photo-1523362628742-0c26015b2524?q=80&w=500',
    ],
    'Eyeglasses': [
      'https://images.unsplash.com/photo-1574258495973-f010dfbb5371?q=80&w=500',
    ],
    'Umbrellas': [
      'https://images.unsplash.com/photo-1531233075252-8797f1cc652a?q=80&w=500',
    ],
    'Other': [
      'https://images.unsplash.com/photo-1586880244406-556ebe35f282?q=80&w=500'
    ]
  };


  Future<void> _startSeeding() async {
    if (_currentUser == null) return;

    setState(() {
      _isSeeding = true;
      _status = 'Connecting to Firestore...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final itemsCollection = firestore.collection('items');

      const seedCount = 30;
      for (int i = 0; i < seedCount; i++) {
        final type = _random.nextBool() ? ItemType.lost : ItemType.found;
        final category = AppConstants.itemCategories[_random.nextInt(AppConstants.itemCategories.length)];
        final location = AppConstants.campusLocations[_random.nextInt(AppConstants.campusLocations.length)];
        final title = _generateTitle(category.name);
        final description = _generateDescription(title, type);
        
        final dateOccurred = DateTime.now().subtract(Duration(days: _random.nextInt(14)));
        final status = _random.nextDouble() > 0.8 ? ItemStatus.resolved : ItemStatus.active;

        final docRef = itemsCollection.doc();
        final images = _imageMap[category.name] ?? [];
        final imageUrl = images.isNotEmpty ? [images[_random.nextInt(images.length)]] : <String>[];

        final item = ItemModel(
          id: docRef.id,
          title: title,
          description: description,
          type: type,
          category: category.name,
          campusLocation: location,
          specificLocation: 'Near the entrance',
          imageUrls: imageUrl,
          dateOccurred: dateOccurred,
          dateReported: DateTime.now(),
          reporterUid: _currentUser!.uid,
          reporterName: 'Seed Test User',
          reporterDepartment: 'Testing',
          status: status,
          searchKeywords: ItemModel.generateKeywords(title, description),
        );

        batch.set(docRef, item.toMap());
        
        print('Prepared item ${i + 1}/$seedCount: $title');
        
        setState(() {
          _count = i + 1;
          _status = 'Preparing items... ($_count/$seedCount)';
        });
      }

      print('Starting batch commit to Firebase...');
      setState(() => _status = 'Uploading to Firebase...');
      await batch.commit();
      print('Batch commit SUCCESS!');

      setState(() {
        _isSeeding = false;
        _status = 'SUCCESS! Seeded $seedCount items to your account.\n\nYou can now stop this app and delete this file.';
      });
    } catch (e) {
      setState(() {
        _isSeeding = false;
        _status = 'ERROR: $e';
      });
    }
  }

  String _generateTitle(String category) {
    switch (category) {
      case 'Electronics':
        return ['iPhone 13', 'Samsung Phone', 'Laptop Charger', 'Earbuds'][_random.nextInt(4)];
      case 'Keys':
        return ['Hostel Keys', 'Gate Key', 'Car Key Fob'][_random.nextInt(3)];
      case 'ID Cards & Documents':
        return ['Student ID Card', 'Registration Slip', 'National ID'][_random.nextInt(3)];
      case 'Books & Stationery':
        return ['Chemistry Textbook', 'Maths Notebook', 'Drawing Board'][_random.nextInt(3)];
      default:
        return '$category Item';
    }
  }

  String _generateDescription(String title, ItemType type) {
    final action = type == ItemType.lost ? 'lost' : 'found';
    return 'I $action my $title earlier today. It is very important to me. Please reach out if you have any information.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Seeder')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storage, size: 64, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                if (_currentUser == null) ...[
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  if (_isLoggingIn)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton.icon(
                      onPressed: _login,
                      icon: const Icon(Icons.login),
                      label: const Text('Log In to Start'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                ] else ...[
                  if (_isSeeding)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton.icon(
                      onPressed: _startSeeding,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Seed 30 Items to My Account'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                ],
                const SizedBox(height: 40),
                const Text(
                  'Note: This will populate your Firestore "items" collection. Use your presentation account to own the data.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
