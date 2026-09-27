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

insheet using "$CONFRAW/BERT_prediction_resource/similarity_compiled_western.csv", clear

rename cn_west_afteronly_similarity* cn_west_af_sim*
rename cn_west_af_sim_mea cn_west_af_sim_mean
rename cn_nonwest_afteronly_similarity_ cn_nonwest_af_sim_mean
rename v10 cn_nonwest_af_sim_max
rename v11 cn_nonwest_af_sim_1
rename v12 cn_nonwest_af_sim_5
rename v13 cn_nonwest_af_sim_10
rename v14 cn_nonwest_af_sim_25

rename companyid1 companyid
drop v1
replace fullname = lower(fullname)
replace fullname = ustrregexra(fullname,"[^A-Za-z0-9]","")
rename fullname fullname_raw

save "$TMP/similarity_compiled_western.dta", replace

use "$TMP/similarity_compiled_western.dta", clear
merge 1:m companyid fullname_raw using "$OUT/analysis_v2.dta"
drop if _merge == 2
drop _merge

collapse  (mean) cn_west* cn_nonwest*, by(fullname year hqcountry)
gen subsegment = fullname
save "$TMP/similarity_at_sector_x_country_x_year_western.dta", replace
di as result "DONE similarity_at_sector_x_country_x_year_western -> intermediate_and_other_data"
