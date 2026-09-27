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

global suffix "corrected"
global saving_suffix "corrected_120623.dta"
global regression_file "regression_$saving_suffix"

capture log close
log using "$LOG_DIR/tableA9.log", replace text

cd "$data_folder"
use $regression_file, clear

merge m:1 subsegment using "$intermediate_data_folder/china_led_subsegments_avg_loose_dealcount_westernonlyforCN"
drop if _merge == 2
gen china_led_westernonlyforCN = (_merge == 3)
drop _merge

gen p2013_CLwesternonlyforCN_suit = post2013*china_led_westernonlyforCN*suitability_score_wdi

eststo clear
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CLwesternonlyforCN_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace

esttab est* using "$TABLE_DIR/tableA9.csv", se replace csv order(p2013_CL_countavg_loose_suit  p2013_CLwesternonlyforCN_suit) ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
	nomtitle ///
	s(fe_sc fe_cy fe_sy fe_ys N ymean ysd, ///
	label("Sector x Country FE" "Country x Year FE" "Sector x Year FE" "Appropriateness x Year FE" "Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") ///
	fmt(0 0 0 0  0 3 3)) ///
	coeflabel(p2013_CL_countavg_loose_suit "China-Led x Post x Appropriateness" p2013_CLwesternonlyforCN_suit "Western LP China-Led x Post x Appropriateness")

log close
