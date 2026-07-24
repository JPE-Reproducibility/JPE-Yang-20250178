#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
ROOT="$(pwd)"

if [ -z "${STATA_CMD:-}" ]; then
    for c in stata-se stata-mp stata "/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se" "/c/Program Files/StataNow19/StataSE-64.exe"; do
        if command -v "$c" >/dev/null 2>&1 || [ -x "$c" ]; then STATA_CMD="$c"; break; fi
    done
fi
[ -z "${STATA_CMD:-}" ] && { echo "ERROR: set STATA_CMD" >&2; exit 1; }
if [ -z "${PYTHON_CMD:-}" ]; then
    if command -v python3 >/dev/null 2>&1; then PYTHON_CMD=python3; else PYTHON_CMD=python; fi
fi
export STATA_CMD PYTHON_CMD

SKIP_HEAVY=0; STAGE_A=1; STAGE_B=1
while [ $# -gt 0 ]; do
    case "$1" in
        --skip-heavy)   SKIP_HEAVY=1; shift ;;
        --stage-a-only) STAGE_B=0; shift ;;
        --stage-b-only) STAGE_A=0; shift ;;
        *) echo "ERROR: unknown argument '$1' (usage: [--skip-heavy] [--stage-a-only|--stage-b-only])" >&2; exit 1 ;;
    esac
done

mkdir -p output/logs
fails=0

if [ "$STAGE_A" -eq 1 ]; then
    echo "========== STAGE A: building the analysis datasets from raw =========="
    if [ "$SKIP_HEAVY" -eq 1 ]; then
        bash code/generate/generate_all.sh --skip-heavy || fails=$((fails+1))
    else
        bash code/generate/generate_all.sh || fails=$((fails+1))
    fi
fi

run_do () {
    echo ">>> stata:  $1"
    if ! "$STATA_CMD" -e do "$1"; then
        echo "    WARNING: Stata returned nonzero for $1" >&2; fails=$((fails+1))
    fi
    mv -f ./*.log output/logs/ 2>/dev/null || true
}
run_py () {
    echo ">>> python: $1"
    if ! "$PYTHON_CMD" "$1"; then echo "    ERROR: $1 failed" >&2; fails=$((fails+1)); fi
}
run_do_if () {
    if [ -f "$1" ]; then run_do "$2"; else
        echo ">>> SKIPPED: $2 (missing input $1 — run the corresponding Stage-A step first)"
    fi
}

if [ "$STAGE_B" -eq 1 ]; then
    INT="confidential-data-not-for-publication/Analysis/intermediate_and_other_data"
    echo "========== STAGE B: reproducing every exhibit =========="
    run_py code/tables/table_1.py
    run_do code/tables/table_2.do
    run_do code/tables/table_3.do
    run_do code/tables/table_4.do
    run_do code/tables/table_5.do
    run_do code/tables/table_6.do
    run_do code/tables/table_7.do
    run_do code/tables/table_8.do
    run_py code/tables/table_A1.py
    run_do code/tables/table_A2.do
    run_do code/tables/table_A4.do
    run_do code/tables/table_A5.do
    run_do code/tables/table_A6.do
    run_do code/tables/table_A7.do
    run_do_if "$INT/simulated_deals_all_1_500.dta" code/tables/table_A8.do
    run_do code/tables/table_A9.do
    run_do code/tables/table_A10.do
    run_do code/tables/table_A11.do
    run_do code/tables/table_A12.do
    run_do code/tables/table_A13.do
    run_do code/tables/table_A14.do
    run_do code/tables/table_A15.do
    run_do code/tables/table_A16.do
    run_do code/tables/table_A17.do
    run_do code/tables/table_A18.do
    run_do code/tables/table_A20.do
    run_do code/tables/table_A21.do
    run_do code/tables/table_A22.do
    run_do code/tables/table_A23.do
    run_do code/tables/table_A24.do
    run_do code/tables/table_A25.do
    run_do code/tables/table_A26.do
    run_do code/tables/table_A27.do
    run_do code/tables/table_A28.do
    run_do code/tables/table_A29.do
    run_do code/tables/table_A30.do
    run_py code/figures/figure_1.py
    run_do code/figures/figure_2.do
    run_do code/figures/figure_4.do
    run_py code/figures/figure_A1.py
    run_do code/figures/figure_A2.do
    run_do code/figures/figure_A3.do
    run_py code/figures/figure_A4.py
    run_py code/figures/figure_A5.py
    run_do code/figures/figure_A6.do
    run_py code/figures/figure_A7.py
    run_py code/figures/figure_A8.py
    run_py code/figures/figure_A9.py
    run_py code/figures/figure_A10.py
    run_do_if "$INT/regression_china_suitability_score_1_indicator_dropped_corrected.dta" code/figures/figure_A11.do
    run_do code/figures/figure_A12.do
    run_do code/figures/figure_A13.do
    run_do code/figures/figure_A14.do
    run_do code/figures/figure_A15.do
    run_do code/figures/figure_A16.do
    run_do code/figures/figure_A17.do
    run_do code/figures/figure_3.do
fi

echo
if [ "$fails" -eq 0 ]; then
    echo "run_all.sh finished with no reported failures. Exhibits in output/tables and output/figures."
else
    echo "run_all.sh finished with $fails reported failure(s); see output/logs/." >&2
    exit 1
fi
