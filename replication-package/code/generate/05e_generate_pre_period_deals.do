clear all
set more off
local _envroot : environment JPE_GENERATE_ROOT
if "`_envroot'" != "" {
    global ROOT "`_envroot'"
}
else if "$REPLICATION_ROOT" != "" {
    global ROOT "$REPLICATION_ROOT"
}
else {
    global ROOT ""
    local _r "."
    forvalues _i = 1/6 {
        capture confirm file "`_r'/code/auxiliary/paths.do"
        if !_rc {
            global ROOT "`_r'"
            continue, break
        }
        local _r "`_r'/.."
    }
}
if "$ROOT" == "" {
    di as error "Cannot locate the replication package root: no code/auxiliary/paths.do above `c(pwd)'."
    di as error "Run from the package root, or export JPE_GENERATE_ROOT / set global REPLICATION_ROOT."
    exit 601
}
local _pr_pwd "`c(pwd)'"
quietly cd "$ROOT"
global ROOT "`c(pwd)'"
quietly cd "`_pr_pwd'"
global RAW "$ROOT/data/raw"
global CONFRAW "$ROOT/confidential-data-not-for-publication/Raw"
global TMP  "$ROOT/confidential-data-not-for-publication/Analysis/intermediate_and_other_data"
cap mkdir "$TMP"
cap mkdir "$ROOT/confidential-data-not-for-publication"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global OUT  "$ROOT/confidential-data-not-for-publication/Analysis"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
cap mkdir "$TMP"

use "$OUT/analysis_v2.dta", clear
gen count = 1
keep if year <= 2013  & year >= 2000
drop subsegment
rename fullname subsegment
merge m:1 subsegment using "$RAW/other_data_resource/hand_collected/policy_constrained_sectors.dta"
keep if _merge == 3
drop _merge
gen policy_constrained = (policy_obstacle == 1)
keep companyid dealid subsegment hqcountry dealsize year marketmap policy_constrained OECD_b80s
encode marketmap, gen(marketmap_id)
gen dealcount = 1
save "$TMP/pre_period_deals.dta", replace
di as result "DONE pre_period_deals -> intermediate_and_other_data"
