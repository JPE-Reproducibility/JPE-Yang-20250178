#!/usr/bin/env bash
set -u

N="${1:-10}"
DO="$(cd "$(dirname "$0")" && pwd)/09_generate_simulated_deals.do"
export JPE_GENERATE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if [ -z "${STATA_CMD:-}" ]; then
    for c in stata-se stata-mp stata "/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se" "/Applications/Stata/StataSE.app/Contents/MacOS/stata-se" "/c/Program Files/StataNow19/StataSE-64.exe"; do
        if command -v "$c" >/dev/null 2>&1 || [ -x "$c" ]; then STATA_CMD="$c"; break; fi
    done
fi
[ -z "${STATA_CMD:-}" ] && { echo "ERROR: no Stata found; set STATA_CMD." >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/a8_fleet_XXXX")"
echo "driver: $N worker(s); scratch logs in $WORK"

fail() { echo "ERROR: $1 (see logs in $WORK)" >&2; exit 1; }
check_log() {
    [ -f "$1" ] || fail "missing log $1"
    if grep -qE "^r\([0-9]+\);" "$1"; then fail "Stata error in $1"; fi
}

if [ "${SKIP_PREP:-0}" != "1" ]; then
    echo ">>> prep"
    mkdir -p "$WORK/prep" && cd "$WORK/prep"
    "$STATA_CMD" -e do "$DO" prep
    check_log "$WORK/prep/09_generate_simulated_deals.log"
else
    echo ">>> prep skipped (SKIP_PREP=1; reusing existing prep artifacts)"
fi

if [ "${SKIP_REGCACHE:-0}" != "1" ]; then
    echo ">>> regcache"
    mkdir -p "$WORK/regcache" && cd "$WORK/regcache"
    "$STATA_CMD" -e do "$DO" regcache
    check_log "$WORK/regcache/09_generate_simulated_deals.log"
else
    echo ">>> regcache skipped (SKIP_REGCACHE=1; reusing existing cache)"
fi

echo ">>> simulate x$N"
pids=()
for w in $(seq 1 "$N"); do
    mkdir -p "$WORK/w$w"
    ( cd "$WORK/w$w" && "$STATA_CMD" -e do "$DO" simulate "$w" "$N" ) &
    pids+=($!)
done
rc=0
for p in "${pids[@]}"; do wait "$p" || rc=1; done
for w in $(seq 1 "$N"); do check_log "$WORK/w$w/09_generate_simulated_deals.log"; done
[ "$rc" -ne 0 ] && echo "WARNING: a worker shell returned nonzero (logs were clean; continuing)" >&2

echo ">>> assemble"
mkdir -p "$WORK/assemble" && cd "$WORK/assemble"
"$STATA_CMD" -e do "$DO" assemble
check_log "$WORK/assemble/09_generate_simulated_deals.log"

echo "DONE: simulated_deals_all_1_500.dta assembled (logs kept in $WORK)"
