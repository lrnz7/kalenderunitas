import re
from pathlib import Path
p = Path('lib/screens/calendar_page.dart')
s = p.read_text(encoding='utf-8')
start = s.find('appBar: AppBar(')
end = s.find('\n      body:')
if start==-1 or end==-1:
    print('Could not find markers')
else:
    snippet = s[start:end]
    print('SNIPPET:\n')
    print(snippet)
    pairs = {'(':')','[':']','{':'}'}
    stack=[]
    mismatch_index = None
    for i,ch in enumerate(snippet):
        if ch in pairs:
            stack.append((ch,i))
        elif ch in pairs.values():
            if not stack:
                print(f'Unmatched closer {ch} at {i}')
                mismatch_index = i
                break
            last,idx = stack.pop()
            if pairs[last]!=ch:
                print(f'Mismatched {last} at {idx} with {ch} at {i}')
                mismatch_index = i
                break
    if mismatch_index is not None:
        start_ctx = max(0, mismatch_index-80)
        end_ctx = min(len(snippet), mismatch_index+80)
        print('\nContext around mismatch:\n')
        print(snippet[start_ctx:end_ctx])
    if stack:
        print('\nUnclosed openers:')
        lines = snippet.splitlines(True)
        cum = 0
        for o,i in stack:
            # find line number
            line_no = 1
            col = i
            for idx,ln in enumerate(lines):
                if cum + len(ln) > i:
                    line_no = idx + 1
                    col = i - cum + 1
                    break
                cum += len(ln)
            print(f"{o} at index {i} (line {line_no}, col {col})")
            start = max(0, i-40)
            end = min(len(snippet), i+40)
            print('\n  Context:')
            print(snippet[start:end])
    else:
        print('\nAll matched')
