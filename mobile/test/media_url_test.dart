import 'package:flutter_test/flutter_test.dart';
import 'package:pair/core/network/media_url.dart';

void main() {
  test('resolveMediaUrl rewrites localhost storage URLs to app base', () {
    final resolved = resolveMediaUrl(
      'http://localhost/storage/avatars/user/photo.png',
    );

    expect(resolved, isNotNull);
    expect(resolved, contains(':8000/storage/avatars/user/photo.png'));
  });

  test('resolveMediaUrl resolves relative storage paths', () {
    final resolved = resolveMediaUrl('/storage/avatars/user/photo.png');

    expect(resolved, isNotNull);
    expect(resolved, startsWith('http'));
    expect(resolved, endsWith('/storage/avatars/user/photo.png'));
  });

  test('resolveMediaUrl leaves external URLs unchanged', () {
    const url = 'https://cdn.example.com/avatars/user.png';
    expect(resolveMediaUrl(url), url);
  });

  test('resolveMediaUrl returns null for empty input', () {
    expect(resolveMediaUrl(null), isNull);
    expect(resolveMediaUrl(''), isNull);
  });
}
