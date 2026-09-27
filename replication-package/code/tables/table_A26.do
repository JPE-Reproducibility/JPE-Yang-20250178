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
log using "$LOG_DIR/tableA26.log", replace text

set maxvar 30000

use "$data_folder/regression_corrected_120623.dta", clear
merge m:1 hqcountry subsegment1 using "$intermediate_data_folder/suitability_gdp_component_detail.dta"
drop if _merge == 2
drop _merge

gen p2013_CL_suit_z = p2013_china_led_countavg_loose*suitability_score_wdi_z
gen p2013_CL_suit_levelgdp_z = p2013_china_led_countavg_loose*suit_levelgdp_z
gen p2013_CL_suit_res_levelgdp_z = p2013_china_led_countavg_loose*suit_res_levelgdp_z

eststo clear

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_suit_z, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_suit_levelgdp_z p2013_CL_suit_res_levelgdp_z, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace

esttab est* using "$TABLE_DIR/tableA26.csv", se replace csv ///
	order(p2013_CL_countavg_loose_suit p2013_CL_suit_z p2013_CL_suit_levelgdp_z p2013_CL_suit_res_levelgdp_z) ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
	s(fe_sc fe_cy fe_sy fe_ys N ymean ysd, ///
	  label("Sector x Country FE" "Country x Year FE" "Sector x Year FE" "Appropriateness x Year FE" "Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") ///
	  fmt(0 0 0 0 0 3 3)) ///
	coeflabel(p2013_CL_countavg_loose_suit "China-Led x Post x Appropriateness" ///
	          p2013_CL_suit_z "China-Led x Post x Appropriateness Z-score" ///
	          p2013_CL_suit_levelgdp_z "China-Led x Post x Appropriateness Z-score (GDP pc)" ///
	          p2013_CL_suit_res_levelgdp_z "China-Led x Post x Appropriateness Z-score (Residual)")

log close
