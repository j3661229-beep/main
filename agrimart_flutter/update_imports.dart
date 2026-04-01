import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true);
  
  for (var entity in files) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (content.contains("'package:flutter_gen/gen_l10n/app_localizations.dart'")) {
        print('Updating ${entity.path}');
        final updated = content.replaceAll(
          "'package:flutter_gen/gen_l10n/app_localizations.dart'",
          "'package:agrimart/l10n/app_localizations.dart'"
        );
        entity.writeAsStringSync(updated);
      }
    }
  }
}
