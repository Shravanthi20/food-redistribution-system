import os

def fix_imports_and_scripts():
    # Fix auth_service.dart
    auth_file = 'lib/services/auth_service.dart'
    if os.path.exists(auth_file):
        with open(auth_file, 'r', encoding='utf-8') as f:
            content = f.read()
        if 'package:flutter/foundation.dart' not in content:
            # find first import
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    lines.insert(i, "import 'package:flutter/foundation.dart';")
                    break
            with open(auth_file, 'w', encoding='utf-8') as f:
                f.write('\n'.join(lines))
                
    # Revert test_matching.dart
    test_matching = 'scripts/test_matching.dart'
    if os.path.exists(test_matching):
        with open(test_matching, 'r', encoding='utf-8') as f:
            content = f.read()
        content = content.replace('debugPrint(', 'print(')
        lines = content.split('\n')
        if '// ignore_for_file: avoid_print' not in lines[0:5]:
            lines.insert(0, '// ignore_for_file: avoid_print')
        with open(test_matching, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))

if __name__ == '__main__':
    fix_imports_and_scripts()
