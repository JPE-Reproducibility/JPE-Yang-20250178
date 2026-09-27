clear all

if "$REPLICATION_ROOT" == "" {
    local _r "."
    forvalues _i = 1/6 {
        capture confirm file "`_r'/code/auxiliary/paths.do"
        if !_rc {
            global REPLICATION_ROOT "`_r'"
            continue, break
        }
        local _r "`_r'/.."
    }
}
if "$REPLICATION_ROOT" == "" {
    di as error "Cannot locate the replication package root: no code/auxiliary/paths.do above `c(pwd)'."
    di as error "Run from the package root (or any folder inside it), or set the global REPLICATION_ROOT first."
    exit 601
}
include "$REPLICATION_ROOT/code/auxiliary/paths.do"

capture log close
log using "$LOG_DIR/tableA28.log", replace text

eststo clear
use "$intermediate_data_folder/indicator_regression.dta", clear

eststo: reghdfe Z_score_scale yhat_CL_noFEcons_norm if suitability_score_wdi != . & post==1, absorb(hqcode subsegment1) vce(cluster hqcode)
quietly estadd local fe_c  "Yes"
quietly estadd local fe_ms "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe Z_score_scale yhat_CL_noFEcons_norm if suitability_score_wdi != . & post==1 & OECD_b80s==0, absorb(hqcode subsegment1) vce(cluster hqcode)
quietly estadd local fe_c  "Yes"
quietly estadd local fe_ms "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe Z_score_scale yhat_CL_noFEcons_norm if suitability_score_wdi != . & post==1 & relevant_sector==1, absorb(hqcode subsegment1) vce(cluster hqcode)
quietly estadd local fe_c  "Yes"
quietly estadd local fe_ms "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe Z_score_scale yhat_CL_noFEcons_norm if suitability_score_wdi != . & post==1 & relevant_sector==1 & OECD_b80s==0, absorb(hqcode subsegment1) vce(cluster hqcode)
quietly estadd local fe_c  "Yes"
quietly estadd local fe_ms "Yes"
quietly estadd ysumm, mean sd replace

esttab est* using "$TABLE_DIR/tableA28.csv", replace csv order(yhat_CL_noFEcons_norm) ///
    star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
    s(fe_c fe_ms N ymean ysd, ///
      label("Country FE" "Macro Sector FE" "Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") ///
      fmt(0 0 0 3 3)) ///
    coeflabel(yhat_CL_noFEcons_norm "Predicted China-Induced Deals")

log close
