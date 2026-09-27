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
log using "$LOG_DIR/tableA18.log", replace text

set maxvar 30000

use "$data_folder/regression_corrected_120623.dta", clear

merge m:1 subsegment using "$intermediate_data_folder/EM_subseg_growth_rate.dta", keep(master match) nogen
merge m:1 subsegment using "$intermediate_data_folder/EM_subseg_growth_rate_no_China.dta", keep(master match) nogen

eststo clear

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "No"
quietly estadd local fe_em "No"
quietly estadd local fe_EM_growth_c_y "No"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year hq#year#c.EM_subseg_growth_rate_count) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "No"
quietly estadd local fe_em "No"
quietly estadd local fe_EM_growth_c_y "\#Deals"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year hq#year#c.EM_subseg_growth_rate_dealsize) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "No"
quietly estadd local fe_em "No"
quietly estadd local fe_EM_growth_c_y "Deal Size"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year hq#year#c.EM_subseg_growth_count_noCN) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "No"
quietly estadd local fe_em "No"
quietly estadd local fe_EM_growth_c_y "\#Deals excl. CN"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year#OECD_b80s hq#year#c.EM_subseg_growth_rate_count) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_em "Yes"
quietly estadd local fe_ys "No"
quietly estadd local fe_EM_growth_c_y "\#Deals"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi hq#year#c.EM_subseg_growth_rate_count) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_em "No"
quietly estadd local fe_ys "Yes"
quietly estadd local fe_EM_growth_c_y "\#Deals"
quietly estadd ysumm, mean sd replace

esttab est* using "$TABLE_DIR/tableA18.csv", se replace csv order(p2013_CL_countavg_loose_suit) ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitles ///
	s(fe_sc fe_cy fe_sy fe_em fe_ys fe_EM_growth_c_y N ymean ysd, ///
	  label("Sector x Country Fixed Effects" "Country x Year Fixed Effects" "Sector x Year Fixed Effects" "Sector x Year x EM Fixed Effects" "Appropriateness x Year Fixed Effects" "EM Growth x Country FE x  Year FE" "Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") ///
	  fmt(0 0 0 0 0 0 0 3 3)) ///
	coeflabel(p2013_CL_countavg_loose_suit "China-Led Sector x Post x China Appropriateness")

log close
