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
log using "$LOG_DIR/tableA5.log", replace text

capture program drop add_stdbeta
program define add_stdbeta
	args xvar
	quietly sum `e(depvar)' if e(sample)
	local ymean = r(mean)
	local ysd = r(sd)
	quietly estadd scalar ymean = `ymean'
	quietly estadd scalar ysd = `ysd'

	quietly sum `xvar' if e(sample)
	local xmean = r(mean)
	local xsd = r(sd)
	quietly estadd scalar xmean = `xmean'
	quietly estadd scalar xsd = `xsd'

	local stdbeta = .
	if `ysd' < . & `ysd' > 0 & `xsd' < . {
		local stdbeta = _b[`xvar'] * `xsd' / `ysd'
	}
	quietly estadd scalar stdbeta = `stdbeta'
end

use "$intermediate_data_folder/regression_validation_countrypair_final.dta", clear
eststo clear

replace hqcountry1_OECD_b80s = 0 if hqcountry_1=="China"
replace hqcountry2_OECD_b80s = 0 if hqcountry_2=="China"

eststo: reghdfe lnum_families suitability_score_wdi, absorb(hqcountry_1_id#marketmap_id hqcountry_2_id#marketmap_id hqcountry_1_id#hqcountry_2_id) vce(cluster hqcountry_1_id#hqcountry_2_id)
quietly estadd local fe_hq1 "Yes"
quietly estadd local fe_hq2 "Yes"
quietly estadd local fe_hq3 "Yes"
add_stdbeta suitability_score_wdi

eststo: reghdfe patent_textual_similarity_mean suitability_score_wdi, absorb(hqcountry_1_id#marketmap_id hqcountry_2_id#marketmap_id hqcountry_1_id#hqcountry_2_id) vce(cluster hqcountry_1_id#hqcountry_2_id)
quietly estadd local fe_hq1 "Yes"
quietly estadd local fe_hq2 "Yes"
quietly estadd local fe_hq3 "Yes"
add_stdbeta suitability_score_wdi

esttab est* using "$TABLE_DIR/tableA5.csv", ///
	se replace csv keep(suitability_score_wdi) order(suitability_score_wdi)  ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f)  nobase nocons  ///
	mtitles("Log Number of Patent Families" ///
			"Mean Pre-Period Patent Textual Similarity") ///
	s(fe_hq1 fe_hq2 fe_hq3 N xmean xsd ymean ysd stdbeta, ///
	label("Country 1 - Macro Sector FE" "Country 2 - Macro Sector FE" "Country 1 - Country 2 FE" "Number of Obs"  "Mean of Indep. Var" "SD of Indep. Var" "Mean of Dep. Var" "SD of Dep. Var" "Std Beta Coefficient") ///
	fmt(0 0 0 0 3 3 3 3 3)) ///
	coeflabel(suitability_score_wdi "Appropriateness between Country Pairs")

log close
