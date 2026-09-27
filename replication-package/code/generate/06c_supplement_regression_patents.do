version 19
clear all
set more off

local _envroot : environment JPE_GENERATE_ROOT
if "`_envroot'" != "" {
    global ROOT "`_envroot'"
}
else if "$REPLICATION_ROOT" != "" {
    global ROOT "$REPLICATION_ROOT"
}
else {
    global ROOT ""
    local _r "."
    forvalues _i = 1/6 {
        capture confirm file "`_r'/code/auxiliary/paths.do"
        if !_rc {
            global ROOT "`_r'"
            continue, break
        }
        local _r "`_r'/.."
    }
}
if "$ROOT" == "" {
    di as error "Cannot locate the replication package root: no code/auxiliary/paths.do above `c(pwd)'."
    di as error "Run from the package root, or export JPE_GENERATE_ROOT / set global REPLICATION_ROOT."
    exit 601
}
local _pr_pwd "`c(pwd)'"
quietly cd "$ROOT"
global ROOT "`c(pwd)'"
quietly cd "`_pr_pwd'"
global TMP  "$ROOT/confidential-data-not-for-publication/Analysis/intermediate_and_other_data"
global OUT  "$ROOT/confidential-data-not-for-publication/Analysis"

capture confirm file "$OUT/regression_corrected_120623.dta"
if _rc {
    di as error "keystone not found -- run 04_generate_regression_corrected_120623.do first."
    exit 601
}

use "$OUT/regression_corrected_120623.dta", clear

capture drop count_predicted_patents has_patent_prediction count_citations_to_china count_citations_to_us count_citations_to_world count_predicted_patents_citation

merge m:1 fullname_raw hqcountry year using "$TMP/patent_count_year_country.dta"
drop if _merge == 2
drop _merge
bysort fullname_raw : egen has_patent_prediction = max(count_predicted_patents)
replace count_predicted_patents=0 if count_predicted_patents==. & has_patent_prediction!=.

merge m:1 fullname_raw country_2digit year using "$TMP/citing_china_country_level.dta"
drop if _merge == 2
drop _merge  country_cited
replace count_citations_to_china=0 if count_citations_to_china==. & has_patent_prediction!=.

merge m:1 fullname_raw country_2digit year using "$TMP/citing_us_country_level.dta"
drop if _merge == 2
drop _merge  country_cited
replace count_citations_to_us=0 if count_citations_to_us==. & has_patent_prediction!=.

merge m:1 fullname_raw country_2digit year using "$TMP/citing_world_level.dta"
drop if _merge == 2
drop _merge
replace count_citations_to_world=0 if count_citations_to_world==. & has_patent_prediction!=.

merge m:1 fullname_raw hqcountry year using "$TMP/patent_count_year_country_citation_weighted.dta"
drop if _merge == 2
drop _merge
replace count_predicted_patents_citation=0 if count_predicted_patents_citation==. & has_patent_prediction!=.

save "$TMP/regression_corrected_120623_patents.dta", replace
di as result "DONE patent-augmented keystone -> INT/regression_corrected_120623_patents.dta"
