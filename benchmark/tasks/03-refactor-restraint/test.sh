#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
python3 -c "
from utils import format_user
assert format_user('alice') == 'alice', 'default fail'
assert format_user('alice', uppercase=True) == 'ALICE', 'uppercase fail'
print('PASS')
"
