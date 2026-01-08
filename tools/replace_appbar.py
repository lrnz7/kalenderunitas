from pathlib import Path
p = Path('lib/screens/calendar_page.dart')
s = p.read_text(encoding='utf-8')
start = s.find('appBar: AppBar(')
if start == -1:
    print('start not found')
    raise SystemExit(1)
body_index = s.find('\n      body:')
if body_index == -1:
    print('body marker not found')
    raise SystemExit(1)
# find end of the appBar block as the substring from start up to just before '\n      body:'
old = s[start:body_index]
print('Old appBar length', len(old))
new = "appBar: AppBar(\n        title: const Text('Kalender'),\n        centerTitle: false,\n        backgroundColor: const Color(0xFF0066CC),\n        elevation: 0,\n        actions: [],\n      ),"
ns = s[:start] + new + s[body_index:]
p.write_text(ns, encoding='utf-8')
print('Replaced appBar block with simple appBar')
