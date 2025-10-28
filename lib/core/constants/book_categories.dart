/// Centralized book categories for the application
/// Used across library filtering, book upload, and other features
class BookCategories {
  /// Get all available book categories
  /// Includes "All" as the default option for filtering
  static List<String> getAll() => [
    'All',
    'Fiction',
    'Non-Fiction',
    'Biography',
    'Science & Technology',
    'History',
    'Philosophy',
    'Art & Literature',
    'Business',
    'Health & Wellness',
    'Travel',
    'Religion & Spirituality',
    'General'
  ];

  /// Get book categories for selection (without "All" option)
  /// Used in dropdowns where "All" is not applicable
  static List<String> getSelectable() => [
    'General',
    'Fiction',
    'Non-Fiction',
    'Biography',
    'Science & Technology',
    'History',
    'Philosophy',
    'Art & Literature',
    'Business',
    'Health & Wellness',
    'Travel',
    'Religion & Spirituality',
  ];

  /// Get the default category for new books
  static String getDefault() => 'General';
}

