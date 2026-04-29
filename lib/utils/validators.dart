import 'package:lost_and_found/config/constants.dart';

class Validators {
  Validators._();

  /// Validate a non-empty required field.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate full name (at least two words).
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().split(' ').length < 2) {
      return 'Please enter your first and last name';
    }
    return null;
  }

  /// Validate university email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim();
    if (!trimmed.contains('@')) {
      return 'Please enter a valid email address';
    }
    if (!AppConstants.universityEmailRegex.hasMatch(trimmed)) {
      return 'Please use your @${AppConstants.emailDomain} email';
    }
    return null;
  }

  /// Validate matriculation number.
  static String? matricNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Matriculation number is required';
    }
    if (!AppConstants.matricNumberRegex.hasMatch(value.trim())) {
      return 'Format: XX/XXXXXX/XXXX (e.g., 20/108002/6CEP)';
    }
    return null;
  }

  /// Validate phone number (Nigerian format).
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.length < 10 || cleaned.length > 14) {
      return 'Please enter a valid phone number';
    }
    if (!RegExp(r'^[\d+]+$').hasMatch(cleaned)) {
      return 'Phone number should contain only digits';
    }
    return null;
  }

  /// Validate password strength.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validate password confirmation matches.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate item title.
  static String? itemTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }
    if (value.trim().length > AppConstants.maxTitleLength) {
      return 'Title must be less than ${AppConstants.maxTitleLength} characters';
    }
    return null;
  }

  /// Validate item description.
  static String? itemDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 10) {
      return 'Please provide a more detailed description (at least 10 characters)';
    }
    if (value.trim().length > AppConstants.maxDescriptionLength) {
      return 'Description must be less than ${AppConstants.maxDescriptionLength} characters';
    }
    return null;
  }

  /// Validate claim message.
  static String? claimMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please describe why you believe this item is yours';
    }
    if (value.trim().length < 20) {
      return 'Please provide more detail to help verify your claim (at least 20 characters)';
    }
    return null;
  }

  /// Validate dropdown selection.
  static String? dropdown(String? value, [String fieldName = 'Selection']) {
    if (value == null || value.isEmpty) {
      return 'Please select a $fieldName';
    }
    return null;
  }
}
