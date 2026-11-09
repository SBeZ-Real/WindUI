import pathlib
import sys
import re
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parents[2]
subprocess.run([sys.executable, str(root / 'tests/fluent/check_api.py')], check=True)
subprocess.run(['luau', str(root / 'tests/fluent/Unit.lua')], check=True)
subprocess.run(['luau-compile', str(root / 'dist/main.lua')], stdout=subprocess.DEVNULL, check=True)
compiled = 0
for path in sorted((root / 'src').rglob('*.lua')) + sorted((root / 'tests/fluent').glob('*.lua')):
    if 'Icons' in path.relative_to(root).parts:
        continue
    subprocess.run(['luau-compile', str(path)], stdout=subprocess.DEVNULL, check=True)
    compiled += 1
print(f'SYNTAX PASS: distribution and {compiled} source/test Lua files', flush=True)
for document in (root / 'docs/fluent').glob('*.md'):
    for snippet in re.findall(r'```lua\n(.*?)```', document.read_text(), re.S):
        with tempfile.NamedTemporaryFile(suffix='.lua', mode='w') as handle:
            handle.write(snippet)
            handle.flush()
            subprocess.run(['luau-compile', handle.name], stdout=subprocess.DEVNULL, check=True)

for scenario in ('Integration.lua', 'Config.lua', 'KeySystem.lua', 'FileStorage.lua', 'Lifecycle.lua'):
    capabilities = (root / 'tests/fluent/FileCapabilities.lua').read_text() if scenario == 'FileStorage.lua' else ''
    source = capabilities + (root / 'tests/fluent/RobloxMock.lua').read_text() + '\nlocal WindUI = (function()\n' + (root / 'dist/main.lua').read_text() + '\nend)()\n' + (root / 'tests/fluent' / scenario).read_text()
    with tempfile.NamedTemporaryFile(suffix='.lua', mode='w', delete=False) as handle:
        handle.write(source)
        path = pathlib.Path(handle.name)
    try:
        subprocess.run(['luau', str(path)], check=True)
    except subprocess.CalledProcessError:
        print(f"FAILED SCENARIO: {scenario}", flush=True)
        raise
    finally:
        path.unlink()
