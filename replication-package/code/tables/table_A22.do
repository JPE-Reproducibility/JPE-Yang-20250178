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
log using "$LOG_DIR/tableA22.log", replace text

set maxvar 30000

use "$data_folder/regression_corrected_120623.dta", clear

eststo clear
eststo A1: reghdfe dealcount_norm_mean_00_12 post_shock_CL_plus_1_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo A2: reghdfe dealcount_norm_mean_00_12 post_shock_CL_plus_1_suit [aweight = ltotal_pre_deals], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo A3: reghdfe as_dealcount_y post_shock_CL_plus_1_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo A4: reghdfe as_dealsize_y post_shock_CL_plus_1_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo A5: reghdfe lsize_per_deal post_shock_CL_plus_1_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)

eststo B1: reghdfe dealcount_norm_mean_00_12 post_shock_CL_strict_plus_1_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
eststo B2: reghdfe dealcount_norm_mean_00_12 post_shock_CL_strict_plus_1_suit [aweight = ltotal_pre_deals], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
eststo B3: reghdfe as_dealcount_y post_shock_CL_strict_plus_1_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
eststo B4: reghdfe as_dealsize_y post_shock_CL_strict_plus_1_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
eststo B5: reghdfe lsize_per_deal post_shock_CL_strict_plus_1_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace

esttab A1 A2 A3 A4 A5 using "$TABLE_DIR/tableA22.csv", se replace csv ///
	order(post_shock_CL_plus_1_suit) ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
	nomtitle nonumbers ///
	coeflabel(post_shock_CL_plus_1_suit "Panel A: Baseline China-led: China-Led Sector x Sector-Specific Post x Appropriateness")

esttab B1 B2 B3 B4 B5 using "$TABLE_DIR/tableA22.csv", se append csv ///
	order(post_shock_CL_strict_plus_1_suit) ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
	nomtitle nonumbers ///
	coeflabel(post_shock_CL_strict_plus_1_suit "Panel B: Strict China-led: China-Led Sector x Sector-Specific Post x Appropriateness") ///
	s(fe_sc fe_cy fe_sy fe_ys N ymean ysd, ///
	  label("Sector x Country FE" "Country x Year FE" "Sector x Year FE" "Appropriateness x Year FE" "Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") ///
	  fmt(0 0 0 0 0 3 3))

log close
