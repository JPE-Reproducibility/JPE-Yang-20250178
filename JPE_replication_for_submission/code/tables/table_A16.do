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
log using "$LOG_DIR/tableA16.log", replace text

set maxvar 30000

use "$data_folder/regression_corrected_120623.dta", clear

eststo clear

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit if above_median_ex_China_share_all==0, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit if above_median_ex_China_share_all==1, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit if above_median_im_China_share_all==0, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit if above_median_im_China_share_all==1, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

esttab est* using "$TABLE_DIR/tableA16.csv", se replace csv order(p2013_CL_countavg_loose_suit) ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
	mtitle("Baseline" "Export Low" "Export High" "Import Low" "Import High") ///
	s(fe_sc fe_cy fe_sy N ymean ysd, ///
	  label("Sector x Country FE" "Country x Year FE" "Sector x Year FE" "Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") ///
	  fmt(0 0 0 0 3 3)) ///
	coeflabel(p2013_CL_countavg_loose_suit "China-Led Sector x Post x Appropriateness")

log close
