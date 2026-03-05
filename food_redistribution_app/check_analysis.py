import os
import re

def process_dart_output():
    with open('analyze_output.txt', 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()

    errors = []
    # match patterns like:
    # lib/widgets/role_tile.dart:36:26: Error: Expected a type, but got 'BorderSide.none'.
    pattern = re.compile(r' - (.*):(\d+):(\d+) - (.*)') # Info - message - file:line:col - rule
    pattern2 = re.compile(r'(.*\.dart):(\d+):(\d+): Error: (.*)')
    for line in content.splitlines():
        match = pattern.search(line)
        if match:
             errors.append({
                 'file': match.group(1).strip(),
                 'line': match.group(2).strip(),
                 'msg': match.group(3).strip() + ' - ' + match.group(4).strip()
             })
        else:
             match2 = pattern2.search(line)
             if match2:
                  errors.append({
                       'file': match2.group(1).strip(),
                       'line': match2.group(2).strip(),
                       'msg': match2.group(4).strip()
                  })

    # Let's just dump the top issues if matching fails
    if not errors:
        lines = [l.strip() for l in content.splitlines() if '.dart:' in l]
        print("Found lines with .dart:")
        for l in lines[:20]: print(l)
    else:
        for err in errors[:20]:
            print(f"{err['file']}:{err['line']} -> {err['msg']}")

if __name__ == '__main__':
    process_dart_output()
