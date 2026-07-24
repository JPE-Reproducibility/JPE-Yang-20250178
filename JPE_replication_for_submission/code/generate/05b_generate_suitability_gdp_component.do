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
global TMP  "$ROOT/confidential-data-not-for-publication/Analysis/intermediate_and_other_data"
cap mkdir "$TMP"
cap mkdir "$ROOT/confidential-data-not-for-publication"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global OUT  "$ROOT/confidential-data-not-for-publication/Analysis"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global regression_file "$OUT/regression_corrected_120623.dta"
cap mkdir "$TMP"

use "$TMP/wdi_gdp_pc_matched.dta", clear
keep hqcountry mean_gdp_pc
keep if hqcountry != ""
merge 1:m hqcountry using "$regression_file", keepusing(subsegment1 suitability_score_wdi)
drop if _merge == 1
drop _merge
duplicates drop hqcountry subsegment1, force
drop if suitability_score_wdi == .

regress suitability_score_wdi mean_gdp_pc if suitability_score_wdi != ., r
predict suitability_gdp_component, xb
label variable suitability_gdp_component "Suitability Explained by GDP pc"
predict suitability_residual_component, residual
label variable suitability_residual_component "Suitability Unexplained by GDP pc (Residual)"

keep hqcountry subsegment1 suitability_gdp_component suitability_residual_component
sum suitability_gdp_component, d
gen suitability_gdp_component_z = (suitability_gdp_component - r(mean))/r(sd)
sum suitability_residual_component, d
gen suitability_residual_component_z = (suitability_residual_component - r(mean))/r(sd)

save "$TMP/suitability_gdp_component.dta", replace
di as result "DONE suitability_gdp_component -> intermediate_and_other_data"
