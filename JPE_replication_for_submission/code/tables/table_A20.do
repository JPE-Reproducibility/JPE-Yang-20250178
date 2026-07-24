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
log using "$LOG_DIR/tableA20.log", replace text

set maxvar 30000

use "$data_folder/regression_corrected_120623.dta", clear

eststo clear

eststo: reghdfe same_policy_constraints suitability_score_wdi if OECD_b80s==0 & year == 2019, absorb(hqcountry subsegment) vce(cluster hqcountry)
quietly estadd local fe_c "Yes"
quietly estadd local fe_s "Yes"
quietly estadd local fe_sc "-"
quietly estadd local fe_cy "-"
quietly estadd local fe_sy "-"
estadd ysumm, mean sd replace

gen policy_obstacle_0 = policy_obstacle
replace policy_obstacle_0 = 0 if policy_constraint_EM_countries>0
gen p2013_not_constrained_suit_0 = post2013*(1-policy_obstacle_0)*suitability_score_wdi

gen p2013_not_constrained_suit = post2013*(1-policy_obstacle)*suitability_score_wdi

eststo: ivreghdfe dealcount_norm_mean_00_12 (p2013_CL_countavg_loose_suit = p2013_not_constrained_suit), absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_c "-"
quietly estadd local fe_s "-"
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

eststo: ivreghdfe dealcount_norm_mean_00_12 (p2013_CL_countavg_loose_suit = p2013_not_constrained_suit_0), absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_c "-"
quietly estadd local fe_s "-"
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

esttab est* using "$TABLE_DIR/tableA20.csv", se replace csv ///
	keep(suitability_score_wdi p2013_CL_countavg_loose_suit) ///
	order(suitability_score_wdi p2013_CL_countavg_loose_suit) ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.4f) b(%10.4f) nobase nocons ///
	mtitle("EM Has Similar Policy" "IV Baseline" "No Other EM") ///
	s(fe_c fe_s fe_sc fe_cy fe_sy N ymean ysd, ///
	  label("Country FE" "Sector FE" "Sector x Country FE" "Country x Year FE" "Sector x Year FE" "Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") ///
	  fmt(0 0 0 0 0 0 3 3)) ///
	coeflabel(suitability_score_wdi "Appropriateness" ///
	          p2013_CL_countavg_loose_suit "China-Led Sector (hat) x Post x Appropriateness")

log close
