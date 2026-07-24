#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/../.."
ROOT="$(pwd)"
export JPE_GENERATE_ROOT="$ROOT"

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

FROM=01; TO=09; SKIP_HEAVY=0
while [ $# -gt 0 ]; do
    case "$1" in
        --from)       FROM="$2"; shift 2 ;;
        --to)         TO="$2"; shift 2 ;;
        --skip-heavy) SKIP_HEAVY=1; shift ;;
        *) echo "ERROR: unknown argument '$1' (usage: [--from NN] [--to NN] [--skip-heavy], NN in 01..09)" >&2; exit 1 ;;
    esac
done
case "$FROM$TO" in *[!0-9]*) echo "ERROR: --from/--to must be two-digit step numbers 01..09" >&2; exit 1 ;; esac
[ "$((10#$FROM))" -le "$((10#$TO))" ] || { echo "ERROR: --from ($FROM) exceeds --to ($TO)" >&2; exit 1; }

mkdir -p output/logs/generate
fails=0

in_range () {
    [ "$((10#$1))" -ge "$((10#$FROM))" ] && [ "$((10#$1))" -le "$((10#$TO))" ]
}
run_do () {
    echo ">>> stata:  $1"
    if ! "$STATA_CMD" -e do "$1"; then
        echo "    WARNING: Stata returned nonzero for $1" >&2; fails=$((fails+1))
    fi
    mv -f ./*.log output/logs/generate/ 2>/dev/null || true
}
run_py () {
    echo ">>> python: $1"
    if ! "$PYTHON_CMD" "$1"; then echo "    ERROR: $1 failed" >&2; fails=$((fails+1)); fi
}

if in_range 01; then
run_do code/generate/01_generate_analysis_v2.do
fi

if in_range 02; then
run_py code/generate/02_generate_suitability.py
fi

if in_range 03; then
run_do code/generate/03a_generate_populated_places.do
run_py code/generate/03b_generate_controls.py
run_do code/generate/03c_generate_regression_auxiliary.do
fi

if in_range 04; then
run_do code/generate/04_generate_regression_corrected_120623.do
fi

if in_range 05; then
run_do code/generate/05a_generate_postregression_inputs.do
run_do code/generate/05b_generate_suitability_gdp_component.do
run_do code/generate/05c_generate_regression_alltype_by_cat.do
run_do code/generate/05d_generate_dealcount_alltype_cluster.do
run_do code/generate/05e_generate_pre_period_deals.do
run_do code/generate/05f_generate_similarity_western.do
run_do code/generate/05g_generate_regression_validation_countrypair.do
run_do code/generate/05h_generate_deal_22_24.do
run_do code/generate/05i_generate_regression_00_24_integrated.do
fi

if in_range 06; then
run_py code/generate/06a_generate_patent_citations_from_raw.py
run_py code/generate/06b_generate_patent_layers.py
run_do code/generate/06c_supplement_regression_patents.do
fi

if in_range 07; then
run_py code/generate/07a_generate_patent_cpc_flags.py
run_py code/generate/07b_generate_patent_geolocation_from_raw.py
run_py code/generate/07c_generate_company_geolocation.py
run_do code/generate/07d_generate_analysis_city.do
fi

if in_range 08; then
run_py code/generate/08a_generate_regression_a13_variants.py
if [ "$SKIP_HEAVY" -eq 0 ]; then
    run_do code/generate/08b_generate_regression_figureA11_dropped.do
else
    echo ">>> SKIPPED (heavy): 08b_generate_regression_figureA11_dropped.do"
fi
fi

if in_range 09; then
if [ "$SKIP_HEAVY" -eq 0 ]; then
    run_do code/generate/09_generate_simulated_deals.do
else
    echo ">>> SKIPPED (heavy): 09_generate_simulated_deals.do"
fi
fi

echo
if [ "$fails" -eq 0 ]; then
    echo "generate_all.sh finished (steps $FROM..$TO) with no reported failures. Outputs in confidential-data-not-for-publication/Analysis/."
else
    echo "generate_all.sh finished (steps $FROM..$TO) with $fails reported failure(s); see output/logs/generate/." >&2
    exit 1
fi
