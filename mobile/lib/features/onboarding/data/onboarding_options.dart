/// Common IANA timezones for profile selection.
abstract final class TimezoneOptions {
  static const List<String> values = [
    'UTC',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Toronto',
    'America/Sao_Paulo',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Moscow',
    'Africa/Cairo',
    'Africa/Nairobi',
    'Asia/Dubai',
    'Asia/Kolkata',
    'Asia/Bangkok',
    'Asia/Singapore',
    'Asia/Tokyo',
    'Asia/Seoul',
    'Australia/Sydney',
    'Pacific/Auckland',
  ];
}

/// Supported matching languages.
abstract final class LanguageOptions {
  static const Map<String, String> labels = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt': 'Português',
    'ar': 'العربية',
    'sw': 'Kiswahili',
  };
}
