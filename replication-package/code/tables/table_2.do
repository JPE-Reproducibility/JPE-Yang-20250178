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

set maxvar 30000

capture log close
log using "$LOG_DIR/table2.log", replace text

eststo clear
use "$data_folder/regression_corrected_120623.dta", clear

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "No"
quietly estadd local fe_em "No"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year#OECD_b80s) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_em "Yes"
quietly estadd local fe_ys "No"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_em "No"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_notoecd if q1_suit==1, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_em "No"
quietly estadd local fe_ys "No"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_notoecd if q1_suit!=1, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_em "No"
quietly estadd local fe_ys "No"
quietly estadd ysumm, mean sd replace

esttab est* using "$TABLE_DIR/table2.csv", se replace csv ///
    order(p2013_CL_countavg_loose_suit p2013_CL_countavg_loose_notoecd) ///
    star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
    mtitle("Full" "Full" "Full" "Bottom Quartile" "Top Three Quartiles") ///
    s(fe_sc fe_cy fe_sy fe_em fe_ys N ymean ysd, ///
      label("Sector x Country FE" "Country x Year FE" "Sector x Year FE" "Sector x Year x EM FE" "Appropriateness x Year FE" "Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") ///
      fmt(0 0 0 0 0 0 3 3)) ///
    coeflabel(p2013_CL_countavg_loose_suit "China-Led x Post x Appropriateness" p2013_CL_countavg_loose_notoecd "China-Led x Post x EM")

log close
