import codecs

with codecs.open('analyze3.txt', 'r', 'utf-8', errors='replace') as f:
    lines = f.readlines()

issues = [l.strip() for l in lines if ' - ' in l and ('use_build_context' in l or 'deprecated_member' in l or 'info -' in l)]

for i in issues:
    print(i)
