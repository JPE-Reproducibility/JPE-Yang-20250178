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
log using "$LOG_DIR/tableA6.log", replace text

capture confirm file "$intermediate_data_folder/regression_corrected_120623_patents.dta"
if _rc {
    di as error "regression_corrected_120623_patents.dta not found in Analysis/intermediate_and_other_data --"
    di as error "run Stage-A step 06 first (06a/06b patent layers + 06c_supplement_regression_patents.do)."
    exit 601
}
use "$intermediate_data_folder/regression_corrected_120623_patents.dta", clear
drop count_predicted_patents has_patent_prediction count_predicted_patents_citation
merge m:1 fullname_raw hqcountry year using "$intermediate_data_folder/patent_count_year_country_new_grantyear"
drop if _merge == 2
drop _merge
bysort fullname_raw : egen has_patent_prediction = max(count_predicted_patents)
replace count_predicted_patents=0 if count_predicted_patents==. & has_patent_prediction!=.

keep year hqcountry suitability_score_wdi suitability_score_wdi_us OECD_b80s subsegment1 hq fullname_raw year  country_2digit has_patent_prediction count_predicted_patents

global patent_suffix "new_100k"

cd "$intermediate_data_folder"
merge m:1 fullname_raw country_2digit year using "citing_china_country_level_$patent_suffix.dta"
drop if _merge == 2
drop _merge  country_cited
replace count_citations_to_china=0 if count_citations_to_china==. & has_patent_prediction!=.

merge m:1 fullname_raw country_2digit year using "citing_us_country_level_$patent_suffix.dta"
drop if _merge == 2
drop _merge  country_cited
replace count_citations_to_us=0 if count_citations_to_us==. & has_patent_prediction!=.

merge m:1 fullname_raw country_2digit year using "citing_world_level_$patent_suffix.dta"
drop if _merge == 2
drop _merge
replace count_citations_to_world=0 if count_citations_to_world==. & has_patent_prediction!=.

collapse (sum)  count_predicted_patents count_citations_to_china count_citations_to_us count_citations_to_world (mean) suitability_score_wdi suitability_score_wdi_us (firstnm)OECD_b80s, by( subsegment1  hqcountry)

foreach var in  count_predicted_patents count_citations_to_china count_citations_to_us count_citations_to_world {
	gen l`var' = log(`var')
}

eststo clear
eststo:reghdfe lcount_citations_to_china suitability_score_wdi  lcount_citations_to_world if OECD_b80s==0, vce(robust) absorb(hqcountry subsegment1)
quietly estadd ysumm, mean sd replace
quietly estadd local fe_hq "Yes"
quietly estadd local fe_mm "Yes"
quietly estadd local citation_control "Yes"

eststo:reghdfe lcount_citations_to_us suitability_score_wdi  lcount_citations_to_world if OECD_b80s==0, vce(robust) absorb(hqcountry subsegment1)
quietly estadd ysumm, mean sd replace
quietly estadd local fe_hq "Yes"
quietly estadd local fe_mm "Yes"
quietly estadd local citation_control "Yes"

esttab est* using "$TABLE_DIR/tableA6.csv", ///
	se replace csv keep(suitability_score_wdi) order(suitability_score_wdi)  ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f)  nobase nocons  ///
	mtitles("EM Country Citations to China"  "EM Country Citations to US") ///
	s(fe_hq fe_mm citation_control N ymean ysd , ///
	label("Country Fixed Effects" "Marcro-Sector Fixed Effects" "Citation to World Control" "Number of Obs"  "Mean of Dep. Var" "SD of Dep. Var" ) ///
	fmt(0 0 0 0 3 3 )) ///
	coeflabel(suitability_score_wdi "Appropriateness" )

log close
