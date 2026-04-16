#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
python3 -c "
from parser import parse_csv_line
assert parse_csv_line('a,\"b,c\",d') == ['a', 'b,c', 'd'], 'csv quoted fail'
assert parse_csv_line('a,b,c') == ['a','b','c'], 'simple csv fail'
assert parse_csv_line('') == [''], 'empty fail'
print('PASS')
"
