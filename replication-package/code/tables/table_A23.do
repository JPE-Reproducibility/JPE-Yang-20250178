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
log using "$LOG_DIR/tableA23.log", replace text

set maxvar 30000

use "$data_folder/regression_corrected_120623.dta", clear

merge 1:1 subsegment year hqcountry using "$intermediate_data_folder/similarity_at_sector_x_country_x_year_western.dta"
drop if _merge==2
drop _merge

eststo clear

eststo: reghdfe china_similarity_mean_afteronly p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace
eststo: reghdfe china_similarity_10_afteronly p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe cn_west_af_sim_mean p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace
eststo: reghdfe cn_west_af_sim_10 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe cn_nonwest_af_sim_mean p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace
eststo: reghdfe cn_nonwest_af_sim_10 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

esttab est* using "$TABLE_DIR/tableA23.csv", se replace csv order(p2013_CL_countavg_loose_suit) ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.4f) b(%10.4f) nobase nocons ///
	nonumbers ///
	mtitle("Chinese: Mean Similarity" "Chinese: 90th Pct Similarity" ///
	       "Western-Backed Chinese: Mean Similarity" "Western-Backed Chinese: 90th Pct Similarity" ///
	       "Non-Western-Backed Chinese: Mean Similarity" "Non-Western-Backed Chinese: 90th Pct Similarity") ///
	s(fe_sc fe_cy fe_sy N ymean ysd, ///
	  label("Sector x Country FE" "Country x Year FE" "Sector x Year FE" "Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") ///
	  fmt(0 0 0 0 3 3)) ///
	coeflabel(p2013_CL_countavg_loose_suit "China-Led Sector x Post x Appropriateness")

log close
