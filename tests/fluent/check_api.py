import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]

def strip(source):
    token = re.compile(r'--\[(=*)\[|--|\[(=*)\[|[\'\"]')
    output = []
    position = 0
    while match := token.search(source, position):
        output.append(source[position:match.start()])
        start = match.end()
        marker = match.group()
        if marker == '--':
            end = source.find('\n', start)
            end = len(source) if end < 0 else end
        elif marker[0] in ('\'', '"'):
            end = start
            while end < len(source):
                if source[end] == '\\':
                    end += 2
                elif source[end] == marker:
                    end += 1
                    break
                else:
                    end += 1
        else:
            closing = ']' + (match.group(1) or match.group(2) or '') + ']'
            end = source.find(closing, start)
            end = len(source) if end < 0 else end + len(closing)
        output.append('\n' * source[match.start():end].count('\n'))
        position = end
    output.append(source[position:])
    return ''.join(output)

def inventory(source):
    result = []
    for name, args in re.findall(r'\bfunction\s+([\w.:]+)\s*\(([^)]*)\)', strip(source)):
        result.append([name, re.sub(r'\s+', '', args)])
    return result

def check():
    baseline = json.loads((ROOT / 'tests/fluent/api-baseline.json').read_text())
    count = 0
    for path, definitions in baseline.items():
        current = inventory((ROOT / path).read_text())
        for name, parameters in definitions:
            candidates = [args for key, args in current if key == name]
            assert candidates, f'Missing function {path}: {name}'
            assert any(args == parameters or not parameters or args.startswith(parameters + ',') for args in candidates), f'Changed parameters {path}: {name}'
            count += 1
    print(f'API PASS: {count} existing function declarations retained across {len(baseline)} files')

if __name__ == '__main__':
    check()
