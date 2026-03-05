import os
import re
import sys

def fix_avoid_print(filepath, line_nums):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    changed = False
    
    # Check if we need to add import
    needs_foundation = False
    for num in line_nums:
        idx = num - 1
        if 0 <= idx < len(lines):
            line = lines[idx]
            if 'print(' in line:
                lines[idx] = re.sub(r'\bprint\(', 'debugPrint(', line)
                changed = True
                needs_foundation = True
    
    if needs_foundation and not filepath.startswith('scripts/'):
        # Add import at the top after other imports or after library decl
        import_stmt = "import 'package:flutter/foundation.dart';\n"
        has_import = any('package:flutter/foundation.dart' in l for l in lines)
        if not has_import:
            # find first import
            insert_idx = 0
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    insert_idx = i
                    break
            lines.insert(insert_idx, import_stmt)
            changed = True
            
    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"Fixed {len(line_nums)} prints in {filepath}")

def process_analyze_output(output_file):
    with open(output_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    prints_by_file = {}
    
    for line in lines:
        if 'avoid_print' in line:
            # match pattern: - lib\middleware\rbac_middleware.dart:114:7 - avoid_print
            path_match = re.search(r'- ([a-zA-Z0-9_\\\.]+):(\d+):\d+ - avoid_print', line)
            if path_match:
                filepath = path_match.group(1).replace('\\', '/')
                line_num = int(path_match.group(2))
                if filepath not in prints_by_file:
                    prints_by_file[filepath] = []
                prints_by_file[filepath].append(line_num)
                
    for filepath, line_nums in prints_by_file.items():
        if os.path.exists(filepath):
            fix_avoid_print(filepath, line_nums)

if __name__ == '__main__':
    process_analyze_output(sys.argv[1])
