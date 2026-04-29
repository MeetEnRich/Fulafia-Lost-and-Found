import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // ── App Info ───────────────────────────────────────────────────────────
  static const String appName = 'FULafia Lost & Found';
  static const String appTagline = 'Recover what matters, help others do the same.';
  static const String universityName = 'Federal University of Lafia';
  static const String universityShort = 'FULafia';
  static const String emailDomain = 'fulafia.edu.ng';

  // ── Validation ─────────────────────────────────────────────────────────
  /// Matric number format: XX/XXXXXX/XXXX (e.g., 20/108002/6CEP)
  static final RegExp matricNumberRegex = RegExp(
    r'^\d{2}/\d{4,6}/\w{2,6}$',
  );

  /// University email pattern
  static final RegExp universityEmailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@fulafia\.edu\.ng$',
    caseSensitive: false,
  );

  static const int minPasswordLength = 8;
  static const int maxImagesPerItem = 3;
  static const int maxDescriptionLength = 500;
  static const int maxTitleLength = 100;

  // ── Campus Locations ───────────────────────────────────────────────────
  static const List<String> campusLocations = [
    'Faculty of Agriculture',
    'Faculty of Arts',
    'Faculty of Computing',
    'Faculty of Education',
    'Faculty of Engineering',
    'Faculty of Environmental Design',
    'Faculty of Law',
    'Faculty of Life Sciences',
    'Faculty of Management Science',
    'Faculty of Physical Sciences',
    'Faculty of Social Science',
    'College of Health Sciences',
    'College of Medicine',
    'University Library',
    'ICT Centre',
    'Senate Building',
    'Student Hostels',
    'University Cafeteria',
    'Sports Complex',
    'Lecture Theatres',
    'Student Union Building',
    'Main Gate Area',
    'Car Park',
    'Other',
  ];

  // ── Faculties ──────────────────────────────────────────────────────────
  static const List<String> faculties = [
    'Faculty of Agriculture',
    'Faculty of Arts',
    'Faculty of Computing',
    'Faculty of Education',
    'Faculty of Engineering',
    'Faculty of Environmental Design',
    'Faculty of Law',
    'Faculty of Life Sciences',
    'Faculty of Management Science',
    'Faculty of Physical Sciences',
    'Faculty of Social Science',
    'College of Health Sciences',
    'College of Medicine',
  ];

  // ── Departments (grouped by faculty) ───────────────────────────────────
  static const Map<String, List<String>> departmentsByFaculty = {
    'Faculty of Agriculture': [
      'Agric Economics and Extension',
      'Agronomy',
      'Animal Science',
      'Aquaculture and Fishery',
    ],
    'Faculty of Arts': [
      'Creative and Visual Arts',
      'English',
      'French',
      'History',
      'Theatre and Media Arts',
    ],
    'Faculty of Computing': [
      'Computer Science',
      'Cyber Security',
      'Information Systems',
      'Information Technology',
      'Software Engineering',
    ],
    'Faculty of Education': [
      'Science Education',
      'Special Needs and Rehabilitation Education',
      'Vocational and Technical Education',
      'Arts and Social Science Education',
      'Educational Foundations',
      'Business Education',
      'Physics Education',
    ],
    'Faculty of Engineering': [
      'Civil Engineering',
      'Electrical Engineering',
      'Mechanical Engineering',
    ],
    'Faculty of Environmental Design': [
      'Architecture',
      'Urban and Regional Planning',
    ],
    'Faculty of Law': [
      'Law',
    ],
    'Faculty of Life Sciences': [
      'Biology',
      'Microbiology',
      'Biochemistry',
    ],
    'Faculty of Management Science': [
      'Accounting',
      'Business Administration',
      'Public Administration',
    ],
    'Faculty of Physical Sciences': [
      'Chemistry',
      'Geology',
      'Mathematics',
      'Physics',
      'Statistics',
    ],
    'Faculty of Social Science': [
      'Economics',
      'Mass Communication',
      'Philosophy',
      'Political Science',
      'Sociology',
      'Library and Information Science',
      'Criminology',
      'Psychology',
      'Social Work',
    ],
    'College of Health Sciences': [
      'Medical Laboratory Science',
      'Nursing',
      'Pharmaceutical Science',
      'Radiography',
    ],
    'College of Medicine': [
      'Medicine and Surgery',
      'Basic Clinical Sciences',
      'Basic Medical Sciences',
    ],
  };

  // ── Item Categories ────────────────────────────────────────────────────
  static const List<ItemCategory> itemCategories = [
    ItemCategory(
      name: 'Electronics',
      description: 'Phones, Laptops, Chargers, Earbuds',
      icon: Icons.devices,
    ),
    ItemCategory(
      name: 'ID Cards & Documents',
      description: 'Student ID, Matric Card, Certificates',
      icon: Icons.badge,
    ),
    ItemCategory(
      name: 'Keys',
      description: 'Room Keys, Car Keys, Padlocks',
      icon: Icons.key,
    ),
    ItemCategory(
      name: 'Books & Stationery',
      description: 'Textbooks, Notebooks, Pens',
      icon: Icons.menu_book,
    ),
    ItemCategory(
      name: 'Bags & Backpacks',
      description: 'Backpacks, Handbags, Pouches',
      icon: Icons.backpack,
    ),
    ItemCategory(
      name: 'Clothing & Accessories',
      description: 'Jackets, Caps, Scarves',
      icon: Icons.checkroom,
    ),
    ItemCategory(
      name: 'Wallets & Purses',
      description: 'Wallets, Purses, Card Holders',
      icon: Icons.account_balance_wallet,
    ),
    ItemCategory(
      name: 'Jewellery & Watches',
      description: 'Rings, Necklaces, Watches',
      icon: Icons.watch,
    ),
    ItemCategory(
      name: 'Water Bottles & Containers',
      description: 'Bottles, Flasks, Food Containers',
      icon: Icons.local_drink,
    ),
    ItemCategory(
      name: 'Eyeglasses',
      description: 'Glasses, Sunglasses, Cases',
      icon: Icons.visibility,
    ),
    ItemCategory(
      name: 'Umbrellas',
      description: 'Umbrellas, Raincoats',
      icon: Icons.umbrella,
    ),
    ItemCategory(
      name: 'Other',
      description: 'Anything not listed above',
      icon: Icons.category,
    ),
  ];

  // ── Category names shortcut ────────────────────────────────────────────
  static List<String> get categoryNames =>
      itemCategories.map((c) => c.name).toList();

  // ── User Roles ─────────────────────────────────────────────────────────
  static const String roleStudent = 'student';
  static const String roleStaff = 'staff';
  static const String roleAdmin = 'admin';
}

/// Represents an item category with name, description, and icon.
class ItemCategory {
  final String name;
  final String description;
  final IconData icon;

  const ItemCategory({
    required this.name,
    required this.description,
    required this.icon,
  });
}
