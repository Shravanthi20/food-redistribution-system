import codecs

try:
    with codecs.open('analyze_output.txt', 'r', encoding='utf-16-le') as f:
        text = f.read()
except:
    with open('analyze_output.txt', 'r', encoding='utf-8', errors='replace') as f:
        text = f.read()

lines = text.splitlines()
with open('parsed.txt', 'w', encoding='utf-8') as out:
    for line in lines:
        if ' - ' in line:
            out.write(line.strip() + '\n')
