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
log using "$LOG_DIR/tableA27.log", replace text

eststo clear
use "$intermediate_data_folder/indicator_regression_zscore.dta", clear
eststo A1: reghdfe Z_score_scale yhat_CL_noFEcons_norm if suitability_score_wdi_z !=. & post==1, absorb(hqcode subsegment1) vce(cluster hqcode)
quietly estadd ysumm, mean sd replace
eststo A2: reghdfe Z_score_scale yhat_CL_noFEcons_norm if suitability_score_wdi_z !=. & post==1 & OECD_b80s==0, absorb(hqcode subsegment1) vce(cluster hqcode)
quietly estadd ysumm, mean sd replace

use "$intermediate_data_folder/indicator_regression_gdppc_zscore.dta", clear
eststo B1: reghdfe Z_score_scale yhat_CL_noFEcons_norm if suit_levelgdp_z !=. & post==1, absorb(hqcode subsegment1) vce(cluster hqcode)
quietly estadd ysumm, mean sd replace
eststo B2: reghdfe Z_score_scale yhat_CL_noFEcons_norm if suit_levelgdp_z !=. & post==1 & OECD_b80s==0, absorb(hqcode subsegment1) vce(cluster hqcode)
quietly estadd ysumm, mean sd replace

use "$intermediate_data_folder/indicator_regression_gdpresidual_zscore.dta", clear
eststo C1: reghdfe Z_score_scale yhat_CL_noFEcons_norm if suit_res_levelgdp_z !=. & post==1, absorb(hqcode subsegment1) vce(cluster hqcode)
quietly estadd local fe_c "Yes"
quietly estadd local fe_ms "Yes"
quietly estadd ysumm, mean sd replace
eststo C2: reghdfe Z_score_scale yhat_CL_noFEcons_norm if suit_res_levelgdp_z !=. & post==1 & OECD_b80s==0, absorb(hqcode subsegment1) vce(cluster hqcode)
quietly estadd local fe_c "Yes"
quietly estadd local fe_ms "Yes"
quietly estadd ysumm, mean sd replace

esttab A1 A2 using "$TABLE_DIR/tableA27.csv", se replace csv order(yhat_CL_noFEcons_norm) ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
	nonumbers mtitle("All Countries" "EM Countries") ///
	coeflabel(yhat_CL_noFEcons_norm "Panel A Baseline: Predicted China-Induced Deals Using Appropriateness Z-score") ///
	s(N ymean ysd, label("Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") fmt(0 3 3))

esttab B1 B2 using "$TABLE_DIR/tableA27.csv", se append csv order(yhat_CL_noFEcons_norm) ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
	nomtitle nonumbers ///
	coeflabel(yhat_CL_noFEcons_norm "Panel B From Appropriateness GDP pc: Predicted China-Induced Deals (GDP pc Component Z-score)") ///
	s(N ymean ysd, label("Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") fmt(0 3 3))

esttab C1 C2 using "$TABLE_DIR/tableA27.csv", se append csv order(yhat_CL_noFEcons_norm) ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
	nomtitle nonumbers ///
	coeflabel(yhat_CL_noFEcons_norm "Panel C From Appropriateness Residual: Predicted China-Induced Deals (Residual Component Z-score)") ///
	s(N ymean ysd fe_c fe_ms, ///
	  label("Number of Obs" "Mean of Dep. Var" "SD of Dep. Var" "Country FE" "Macro Sector FE") fmt(0 3 3 0 0))

log close
