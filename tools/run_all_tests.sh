#!/bin/sh
# Runs every test suite headless and fails if any suite fails or doesn't finish
# with a "0 failures" summary (a script error can otherwise exit cleanly).
# Usage: GODOT=/path/to/godot tools/run_all_tests.sh
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
"$GODOT" --headless --path . --editor --import --quit >/dev/null 2>&1
status=0
for suite in run_tests service_tests balance_tests guest_book_tests content_tests layout_lab_tests launcher_tests; do
	output=$("$GODOT" --headless --path . --script "tests/$suite.gd" 2>&1)
	code=$?
	summary=$(printf '%s\n' "$output" | grep -E "checks.*failures|failures: [0-9]+" | tail -1)
	if [ $code -ne 0 ] || ! printf '%s\n' "$summary" | grep -qE "failures: 0|, 0 failures"; then
		status=1
		echo "FAILED  $suite"
		printf '%s\n' "$output" | grep -E "FAIL|ERROR|error" | head -40
	else
		echo "ok      $suite: $summary"
	fi
done
exit $status
