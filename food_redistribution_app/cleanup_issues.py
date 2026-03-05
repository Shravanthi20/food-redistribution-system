import os
import re

def process_analysis_output(filename):
    if not os.path.exists(filename):
        print(f"File {filename} not found.")
        return
        
    pattern = re.compile(r'info - (.*?) - (.*?):(\d+):(\d+) - (.*?)$')
    
    with open(filename, 'r', encoding='utf-16', errors='replace') as f:
        content = f.read()

    errors = []
    # try utf-16 lines
    for line in content.splitlines():
         match = pattern.search(line)
         if match:
             errors.append({
                 'msg': match.group(1).strip(),
                 'file': match.group(2).strip(),
                 'line': match.group(3).strip()
             })

    # if fails try utf8
    if not errors:
        with open(filename, 'r', encoding='utf-8', errors='replace') as f:
             content = f.read()
             for line in content.splitlines():
                  match = pattern.search(line)
                  if match:
                      errors.append({
                         'msg': match.group(1).strip(),
                         'file': match.group(2).strip(),
                         'line': match.group(3).strip()
                      })
    
    # Let's count and unique files
    files_with_withOpacity = set()
    for e in errors:
       if "withOpacity" in e['msg']:
           files_with_withOpacity.add(e['file'])

    count = 0
    for file_path in files_with_withOpacity:
        abs_path = os.path.join(os.getcwd(), 'lib', file_path.split('lib\\')[-1]) if 'lib\\' in file_path else os.path.join(os.getcwd(), file_path)
        if not os.path.exists(abs_path):
             continue
        with open(abs_path, 'r', encoding='utf-8') as f:
             data = f.read()
        
        # fix ANY instance of withOpacity(
        new_data = re.sub(r'\.withOpacity\(([^)]*)\)', r'.withValues(alpha: \1)', data)
        # some instances might have multiple parenthesis like withOpacity(0.5 * factor)
        # Using a deeper regex replacement doesn't evaluate matching parenthesis completely but safely parses inner if without closing
        
        if data != new_data:
             with open(abs_path, 'w', encoding='utf-8') as f:
                  f.write(new_data)
                  count += 1
                  
    print(f"Fixed {count} files regarding withOpacity!")

if __name__ == "__main__":
    process_analysis_output('final_analysis.txt')
