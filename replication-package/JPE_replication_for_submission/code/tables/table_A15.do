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

capture log close
log using "$LOG_DIR/tableA15.log", replace text

cd "$data_folder"

eststo clear
use regression_$saving_suffix, clear
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "No"
quietly estadd local fe_em "No"
quietly estadd local fe_Int_pen "No"
quietly estadd ysumm, mean sd replace

use regression_$saving_suffix, clear
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year subseg#c.InternetPerct) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "No"
quietly estadd local fe_em "No"
quietly estadd local fe_Int_pen "Internet \%"
quietly estadd ysumm, mean sd replace

use regression_$saving_suffix, clear
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year subseg#c.PhoneUsrP100) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "No"
quietly estadd local fe_em "No"
quietly estadd local fe_Int_pen "Cellular"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year#OECD_b80s subseg#c.InternetPerct) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_em "Yes"
quietly estadd local fe_ys "No"
quietly estadd local fe_Int_pen "Internet \%"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi subseg#c.InternetPerct) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_em "No"
quietly estadd local fe_ys "Yes"
quietly estadd local fe_Int_pen "Internet \%"
quietly estadd ysumm, mean sd replace

esttab est* using "$TABLE_DIR/tableA15.csv", se replace csv   order(p2013_CL_countavg_loose_suit )  ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f)  nobase nocons nomtitles ///
	s(fe_sc fe_cy fe_sy fe_ys fe_Int_pen  N ymean ysd, ///
    label("Sector x Country FE" "Country x Year FE" "Sector x Year FE"   "Appropriateness x Year FE" "Internet Penetration x Sector FE" "Number of Obs"  "Mean of Dep. Var" "SD of Dep. Var") ///
	fmt(0 0 0 0 0 0 3 3)) ///
	coeflabel(p2013_CL_countavg_loose_suit "China-Led Sector x Post x Appropriateness")

log close
