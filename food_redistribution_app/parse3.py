import codecs

with codecs.open('analyze3.txt', 'r', 'utf-8', errors='replace') as f:
    lines = f.readlines()

issues = [l.strip() for l in lines if ' - ' in l]

with open('issues.txt', 'w', encoding='utf-8') as out:
    for i in issues:
        out.write(i + '\n')
