#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
python3 -c "
from solution import fizzbuzz
expected_15 = ['1','2','Fizz','4','Buzz','Fizz','7','8','Fizz','Buzz','11','Fizz','13','14','FizzBuzz']
result = fizzbuzz(15)
assert result == expected_15, f'failed: got {result}'
print('PASS')
"
