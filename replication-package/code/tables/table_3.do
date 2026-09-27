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
log using "$LOG_DIR/table3.log", replace text

eststo clear
use "$data_folder/regression_corrected_120623.dta", clear

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit [aweight = ltotal_pre_deals], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo: reghdfe as_dealcount_y p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo: reghdfe as_dealsize_y p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo: reghdfe lsize_per_deal p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)

esttab est* using "$INTERMEDIATE_DIR/table3_panelA.csv", se replace csv ///
    order(p2013_CL_countavg_loose_suit) ///
    star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
    nomtitle nonumbers ///
    coeflabel(p2013_CL_countavg_loose_suit "China-Led x Post x Appropriateness")

eststo clear
use "$data_folder/regression_corrected_120623.dta", clear

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_strict_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_strict_suit [aweight = ltotal_pre_deals], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
eststo: reghdfe as_dealcount_y p2013_CL_countavg_strict_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
eststo: reghdfe as_dealsize_y p2013_CL_countavg_strict_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
eststo: reghdfe lsize_per_deal p2013_CL_countavg_strict_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace

esttab est* using "$INTERMEDIATE_DIR/table3_panelB.csv", se replace csv ///
    order(p2013_CL_countavg_strict_suit) ///
    star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
    nomtitle nonumbers ///
    s(fe_sc fe_cy fe_sy fe_ys N ymean ysd, ///
      label("Sector x Country FE" "Country x Year FE" "Sector x Year FE" "Appropriateness x Year FE" "Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") ///
      fmt(0 0 0 0 0 3 3)) ///
    coeflabel(p2013_CL_countavg_strict_suit "China-Led (Strict) x Post x Appropriateness")

tempname fh
file open `fh' using "$TABLE_DIR/table3.csv", write replace text

file write `fh' `","Deal Count","Deal Count","Deal Count","Deal Size","Deal Size""' _n
file write `fh' `","(1)","(2)","(3)","(4)","(5)""' _n
file write `fh' `","Baseline","Weighted","asinh","asinh","log($/deal)""' _n
file write `fh' `""Panel A: Baseline China-led measure",,,,,"' _n

tempname pa
file open `pa' using "$INTERMEDIATE_DIR/table3_panelA.csv", read text
file read `pa' line
while r(eof)==0 {
    file write `fh' `"`line'"' _n
    file read `pa' line
}
file close `pa'

file write `fh' `""Panel B: Strict China-led measure",,,,,"' _n

file open `pa' using "$INTERMEDIATE_DIR/table3_panelB.csv", read text
file read `pa' line
while r(eof)==0 {
    file write `fh' `"`line'"' _n
    file read `pa' line
}
file close `pa'

file close `fh'

erase "$INTERMEDIATE_DIR/table3_panelA.csv"
erase "$INTERMEDIATE_DIR/table3_panelB.csv"

log close
