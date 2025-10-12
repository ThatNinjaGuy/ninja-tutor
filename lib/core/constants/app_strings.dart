/// User-facing strings and messages used throughout the app
class AppStrings {
  // General
  static const String appName = 'Ninja Tutor';
  static const String appTagline = 'AI Enhanced Learning';
  
  // Auth Screens
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String createAccount = 'Create Account';
  static const String signInToAccount = 'Sign in to your account';
  static const String createYourAccount = 'Create your account';
  static const String alreadyHaveAccount = "Already have an account? Sign in";
  static const String dontHaveAccount = "Don't have an account? Sign up";
  
  // Form Fields
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  
  // Validation Messages
  static const String pleaseEnterEmail = 'Please enter your email';
  static const String pleaseEnterValidEmail = 'Please enter a valid email';
  static const String pleaseEnterPassword = 'Please enter your password';
  static const String pleaseConfirmPassword = 'Please confirm your password';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String pleaseEnterName = 'Please enter your name';
  static const String nameTooShort = 'Name must be at least 2 characters';
  
  // Success Messages
  static const String accountCreatedSuccessfully = 'Account created successfully!';
  static const String profileUpdatedSuccessfully = 'Profile updated successfully!';
  static const String bookAddedToLibrary = 'Book added to your library!';
  static const String bookRemovedFromLibrary = 'Book removed from your library!';
  static const String bookUploaded = 'uploaded successfully!';
  static const String bookmarkAdded = 'Bookmark added';
  static const String highlightModeToggled = 'Highlight mode toggled';
  
  // Error Messages
  static const String loginFailed = 'Login failed';
  static const String registrationFailed = 'Registration failed';
  static const String failedToAddBook = 'Failed to add book';
  static const String failedToRemoveBook = 'Failed to remove book';
  static const String uploadFailed = 'Upload failed';
  static const String errorLoadingBooks = 'Error loading books';
  static const String errorLoadingNotes = 'Error loading notes';
  static const String errorLoadingHighlights = 'Error loading highlights';
  static const String errorLoadingBookmarks = 'Error loading bookmarks';
  static const String errorLoadingQuizzes = 'Error loading quizzes';
  static const String errorLoadingResults = 'Error loading results';
  
  // Loading Messages
  static const String loadingYourLibrary = 'Loading your library...';
  static const String loadingYourBooks = 'Loading your books...';
  static const String loadingBooks = 'Loading books...';
  static const String searchingBooks = 'Searching books...';
  
  // Empty State Messages
  static const String noBooksYet = 'No Books Yet';
  static const String noBooksInLibrary = 'No Books in Your Library';
  static const String noBooks = 'No books in your library';
  static const String noBooksAvailable = 'No Books Available';
  static const String noBooksFound = 'No Books Found';
  static const String noBooksmatchFilters = 'No Books Match Filters';
  static const String noQuizzesAvailable = 'No Quizzes Available';
  static const String noResultsYet = 'No Results Yet';
  static const String noNotesYet = 'No Notes Yet';
  static const String noNotesFound = 'No Notes Found';
  static const String noHighlights = 'No Highlights';
  static const String noBookmarks = 'No Bookmarks';
  
  // Empty State Subtitles
  static const String addFirstBook = 'Add your first book to get started!';
  static const String addBooksFromExplore = 'Add books from the Explore tab to start your reading journey!';
  static const String addBooksFromLibrary = 'Add some books from the Library tab to start reading';
  static const String checkBackLater = 'Check back later for new books!';
  static const String tryAdjustingFilters = 'Try adjusting your search or filters';
  static const String tryDifferentSearch = 'Try a different search term in your library';
  static const String addBooksToGenerateQuizzes = 'Add books to generate practice quizzes';
  static const String addBooksToGenerateCustomQuizzes = 'Add books to generate custom quizzes';
  static const String completeQuizzes = 'Complete some quizzes to see your progress';
  static const String startReadingTakeNotes = 'Start reading and take notes to see them here';
  static const String highlightWhileReading = 'Highlight text while reading to see them here';
  static const String bookmarkWhileReading = 'Bookmark pages while reading to see them here';
  
  // Action Buttons
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String create = 'Create';
  static const String upload = 'Upload';
  static const String generate = 'Generate';
  static const String goToLibrary = 'Go to Library';
  static const String addBook = 'Add Book';
  static const String viewAll = 'View All';
  static const String startQuiz = 'Start Quiz';
  
  // Tab Names
  static const String myBooks = 'My Books';
  static const String exploreBooks = 'Explore Books';
  static const String allNotes = 'All Notes';
  static const String highlights = 'Highlights';
  static const String bookmarks = 'Bookmarks';
  static const String collections = 'Collections';
  static const String available = 'Available';
  static const String myResults = 'My Results';
  
  // Screen Titles
  static const String library = 'Library';
  static const String reading = 'Reading';
  static const String practice = 'Practice';
  static const String notes = 'Notes';
  static const String settings = 'Settings';
  static const String dashboard = 'Dashboard';
  static const String selectBookToRead = 'Select a Book to Read';
  
  // Tooltips
  static const String close = 'Close';
  static const String aiTips = 'AI Tips';
  static const String aiTipsAddFirst = 'AI Tips (Add to library first)';
  static const String quiz = 'Quiz';
  static const String bookmark = 'Bookmark';
  static const String bookmarkAddFirst = 'Bookmark (Add to library first)';
  static const String highlight = 'Highlight';
  static const String highlightAddFirst = 'Highlight (Add to library first)';
  
  // Auth Messages
  static const String pleaseSignIn = 'Please sign in to access your reading library';
  static const String pleaseLogin = 'Please log in to access your library';
  static const String booksWillBeSaved = 'Your books and reading progress will be saved across devices';
  
  // Contextual Messages
  static const String definitionRequested = 'Definition requested for';
  static const String startingQuizForContent = 'Starting quiz for current content';
  static const String collectionsComingSoon = 'Collections feature coming soon!';
  
  // Greeting Messages
  static const String goodMorning = 'Good morning';
  static const String goodAfternoon = 'Good afternoon';
  static const String goodEvening = 'Good evening';
  static const String student = 'Student';
  
  // Progress Section
  static const String yourProgress = 'Your Progress';
  static const String continueReading = 'Continue Reading';
  static const String aiRecommendations = 'AI Recommendations';
  static const String quickActions = 'Quick Actions';
  static const String recentActivity = 'Recent Activity';
}

