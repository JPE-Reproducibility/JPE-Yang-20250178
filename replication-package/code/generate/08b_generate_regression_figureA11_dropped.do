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

forvalues N = 1/4 {

    use "$TMP/china_suitability_score_`N'_indicator_dropped_corrected.dta", clear
    rename Carbon_and_Emissions_Tech_SuitSc Carbon_SuitSc
    rename *_SuitSc SuitSc_*

    rename SuitSc_AI_ML SuitSc1
    rename SuitSc_AgTech SuitSc2
    rename SuitSc_Blockchain SuitSc3
    rename SuitSc_Carbon SuitSc4
    rename SuitSc_DevOps SuitSc5
    rename SuitSc_EdTech SuitSc6
    rename SuitSc_Enterprise_Health SuitSc7
    rename SuitSc_Fintech SuitSc8
    rename SuitSc_FoodTech SuitSc9
    rename SuitSc_InfoSec SuitSc10
    rename SuitSc_Insurtech SuitSc11
    rename SuitSc_IoT SuitSc12
    rename SuitSc_MobilityTech SuitSc13
    rename SuitSc_Retail_HealthTech SuitSc14
    rename SuitSc_Supply_Chain_Tech SuitSc15

    reshape long SuitSc, i(hqcountry seed) j(subsegment1) string

    replace subsegment1 = "AI ML" if subsegment1 == "1"
    replace subsegment1 = "AgTech" if subsegment1 == "2"
    replace subsegment1 = "Blockchain" if subsegment1 == "3"
    replace subsegment1 = "Carbon and Emissions Tech" if subsegment1 == "4"
    replace subsegment1 = "DevOps" if subsegment1 == "5"
    replace subsegment1 = "EdTech" if subsegment1 == "6"
    replace subsegment1 = "Enterprise Health" if subsegment1 == "7"
    replace subsegment1 = "Fintech" if subsegment1 == "8"
    replace subsegment1 = "FoodTech" if subsegment1 == "9"
    replace subsegment1 = "InfoSec" if subsegment1 == "10"
    replace subsegment1 = "Insurtech" if subsegment1 == "11"
    replace subsegment1 = "IoT" if subsegment1 == "12"
    replace subsegment1 = "MobilityTech" if subsegment1 == "13"
    replace subsegment1 = "Retail HealthTech" if subsegment1 == "14"
    replace subsegment1 = "Supply Chain Tech" if subsegment1 == "15"

    replace SuitSc = 5 - SuitSc
    drop relative_to country_2digit
    rename SuitSc suitability_score_wdi

    reshape wide suitability_score_wdi, i(hqcountry subsegment1) j(seed)
    save "$TMP/china_suitability_score_`N'_indicator_dropped_corrected_wide.dta", replace

    use "$OUT/regression_corrected_120623.dta", clear
    keep p2013_CL_countavg_loose_suit china_led_countavg_loose dealcount_norm_mean_00_12 hq subseg subsegment1 subsegment hqcountry year china_led_countavg_strict p2013_CL_countavg_strict_suit

    merge m:1 hqcountry subsegment1 using "$TMP/china_suitability_score_`N'_indicator_dropped_corrected_wide.dta"
    drop if _merge == 2
    drop _merge

    gen post2013 = 1 if year > 2013
    replace post2013 = 0 if post2013 == .
    gen p2013_CL_countavg_loose = china_led_countavg_loose*post2013

    forvalues i = 0/499 {
        gen p2013_CL_countavg_loose_suit_`i' = p2013_CL_countavg_loose*suitability_score_wdi`i'
    }

    gen beta = .
    forvalues i = 0/499 {
        reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit_`i' if year<=2019, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
        replace beta = _b[p2013_CL_countavg_loose_suit_`i'] if _n==`i'+1
    }

    save "$TMP/regression_china_suitability_score_`N'_indicator_dropped_corrected.dta", replace
}
