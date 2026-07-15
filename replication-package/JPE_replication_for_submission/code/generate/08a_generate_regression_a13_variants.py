#!/usr/bin/env python3
import os, subprocess, tempfile

ROOT  = os.environ.get("JPE_GENERATE_ROOT") or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEN   = f"{ROOT}/code/generate/04_generate_regression_corrected_120623.do"

STATA = os.environ.get("STATA_CMD")
if not STATA:
    for _c in ("/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se",
               "/Applications/Stata/StataSE.app/Contents/MacOS/stata-se",
               r"C:\Program Files\StataNow19\StataSE-64.exe"):
        if os.path.exists(_c):
            STATA = _c
            break
if not STATA:
    raise SystemExit("Set STATA_CMD to your Stata batch executable.")
BATCH_FLAG = "/e" if os.name == "nt" else "-b"
VARIANTS = ["from_existing_no_trade2", "from_scratch_allassigned",
            "corrected_drop20country", "corrected_drop30country",
            "corrected_drop15indicator", "corrected_drop25indicator"]

src = open(GEN).read()
work = tempfile.mkdtemp(prefix="a13_")
for v in VARIANTS:
    do = (src.replace('global suffix "corrected.dta"',               f'global suffix "{v}.dta"')
             .replace('global saving_suffix "corrected_120623.dta"', f'global saving_suffix "{v}.dta"')
             .replace('save "$OUT/regression_corrected_120623.dta", replace',
                      f'save "$TMP/regression_{v}.dta", replace'))
    if v in ("from_existing_no_trade2", "from_scratch_allassigned"):
        # anchor the two alternative-assignment scores at 10 - distance
        do = do.replace('replace suitability_score_wdi = 2.921 - suitability_score_wdi',
                        'replace suitability_score_wdi = 10 - suitability_score_wdi')
    p = os.path.join(work, f"reg_{v}.do")
    open(p, "w").write(do)

    r = subprocess.run([STATA, BATCH_FLAG, "do", p], cwd=work,
                       env={**os.environ, "JPE_GENERATE_ROOT": str(ROOT)})
    out = f"{ROOT}/confidential-data-not-for-publication/Analysis/intermediate_and_other_data/regression_{v}.dta"
    print(f"{'OK ' if os.path.exists(out) else 'FAIL'} regression_{v}.dta  (stata rc={r.returncode})")

if __name__ == "__main__":
    pass
