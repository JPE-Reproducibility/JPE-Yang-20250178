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
global RAW "$ROOT/data/raw"
global CONFRAW "$ROOT/confidential-data-not-for-publication/Raw"
global TMP  "$ROOT/confidential-data-not-for-publication/Analysis/intermediate_and_other_data"
cap mkdir "$TMP"
cap mkdir "$ROOT/confidential-data-not-for-publication"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global OUT  "$ROOT/confidential-data-not-for-publication/Analysis"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global crosswalk "$RAW/suitability_resource/country_crosswalk.dta"
global regression_file "$OUT/regression_corrected_120623.dta"
cap mkdir "$TMP"

use "$TMP/suitability_score_all_countries_corrected.dta", clear
rename hqcountry hqcountry_base
drop country_2digit
rename relative_to country_2digit
merge m:1 country_2digit using "$crosswalk"
keep if _merge == 3
drop _merge
drop country_2digit
rename hqcountry relative_to
rename hqcountry_base hqcountry
drop if hqcountry== ""
drop if relative_to == ""
rename *_SuitSc s_s_2_*
reshape long s_s_2_, i(hqcountry relative_to) j(marketmap) string
rename s_s_2_ suitability_score_wdi
preserve
keep hqcountry
rename hqcountry relative_to
duplicates drop
tempfile hq_list
save `hq_list'
restore
merge m:1 relative_to using `hq_list'
keep if _merge == 3
drop _merge
rename hqcountry hqcountry_1
rename relative_to hqcountry_2
gen marketmap_raw = lower(marketmap)
replace marketmap_raw = subinstr(marketmap_raw, "_", "", .)
replace suitability_score_wdi = 3.18- suitability_score_wdi
tempfile suit_long_t
save `suit_long_t'
global suit_long "`suit_long_t'"

use "$CONFRAW/BERT_prediction_resource/patent_countrysector_similarity_2000_2013_100k_new_china.dta", clear

rename (country1 country2) (country_2digit1 country_2digit2)
rename country_2digit1 country_2digit
merge m:1 country_2digit using "$crosswalk"
drop if _merge == 2
drop _merge
rename hqcountry country1
rename country_2digit country1code

rename country_2digit2 country_2digit
merge m:1 country_2digit using "$crosswalk"
drop if _merge == 2
drop _merge
rename hqcountry country2
rename country_2digit country2code
rename sector fullname

gen pair_unsorted = country1code + "_" + country2code
gen pair_sorted   = cond(country1code < country2code, ///
					country1code + "_" + country2code, ///
					country2code + "_" + country1code)
bysort fullname pair_sorted: gen pair_n = _N
tab pair_n

rename country1code c1
rename country2code c2
rename country1 hq1
rename country2 hq2
expand 2
bysort fullname c1 c2: gen byte rev = _n==2
replace c1 = c2[_n-1] if rev
replace c2 = c1[_n-1] if rev
replace hq1 = hq2[_n-1] if rev
replace hq2 = hq1[_n-1] if rev
drop rev
rename (c1 c2 hq1 hq2) (country1code country2code hqcountry_1 hqcountry_2)
drop pair_unsorted pair_sorted pair_n
gen fullname_raw = lower(fullname)
replace fullname_raw = ustrregexra(fullname_raw, "[^A-Za-z0-9]", "")
preserve
use "$OUT/analysis_v2.dta", clear
keep fullname_raw marketmap
duplicates drop
tempfile sector_info
save `sector_info', replace
restore

merge m:1 fullname_raw using `sector_info'
drop if _merge == 2
drop _merge

collapse (mean) mean median top25 top10 top5 top1, by(hqcountry_1 hqcountry_2 marketmap)
gen marketmap_raw = lower(marketmap)
replace marketmap_raw = ustrregexra(marketmap_raw, "[^A-Za-z0-9]", "")
merge 1:1 hqcountry_1 hqcountry_2 marketmap_raw using "$suit_long"
keep if _merge ==3
drop _merge

rename (mean top10) (patent_textual_similarity_mean patent_textual_similarity_10)
keep hqcountry_1 hqcountry_2 patent_textual_similarity_mean patent_textual_similarity_10 marketmap_raw suitability_score_wdi

tempfile reg3
save `reg3', replace

use "$CONFRAW/BERT_prediction_resource/worldwide_pairs_filtered_no_EPO_countries.dta", clear
rename sector fullname
drop if country_1==country_2
rename (country_1 country_2) (country1code country2code)
gen pair_unsorted = country1code + "_" + country2code
gen pair_sorted   = cond(country1code < country2code, ///
					country1code + "_" + country2code, ///
					country2code + "_" + country1code)
bysort fullname pair_sorted: gen pair_n = _N
tab pair_n

rename country1code c1
rename country2code c2

expand 2
bysort fullname c1 c2: gen byte rev = _n==2
replace c1 = c2[_n-1] if rev
replace c2 = c1[_n-1] if rev
drop rev
rename (c1 c2 ) (country1code country2code)
drop pair_unsorted pair_sorted pair_n

rename (country1code country2code) (country_2digit1 country_2digit2)
rename country_2digit1 country_2digit
merge m:1 country_2digit using "$crosswalk"
drop if _merge == 2
drop _merge
rename hqcountry country1
rename country_2digit country1code
rename country_2digit2 country_2digit
merge m:1 country_2digit using "$crosswalk"
drop if _merge == 2
drop _merge
rename hqcountry country2
rename country_2digit country2code
drop if country1=="" | country2==""

replace fullname_raw = ustrregexra(fullname_raw, "[^A-Za-z0-9]", "")
preserve
use "$OUT/analysis_v2.dta", clear
keep fullname fullname_raw marketmap
duplicates drop
tempfile sector_info
save `sector_info', replace
restore
merge m:1 fullname_raw using `sector_info'
drop if _merge == 2
drop _merge
gen marketmap_raw = lower(marketmap)
replace marketmap_raw = ustrregexra(marketmap_raw, "[^A-Za-z0-9]", "")

collapse (sum) count, by(country1code country2code country1 country2  marketmap marketmap_raw)
rename (country1 country2) (hqcountry_1 hqcountry_2)
merge 1:1 hqcountry_1 hqcountry_2 marketmap_raw using "$suit_long"
keep if _merge ==3
drop _merge
gen lnum_families = log(count)
keep  hqcountry_1 hqcountry_2 marketmap_raw suitability_score_wdi lnum_families
tempfile reg4
save `reg4', replace

use `reg3', clear
merge 1:1 hqcountry_1 hqcountry_2 marketmap_raw using `reg4'
drop _merge
erase `reg3'
erase `reg4'

encode hqcountry_1, gen(hqcountry_1_id)
encode hqcountry_2, gen(hqcountry_2_id)
encode marketmap_raw, gen(marketmap_id)

preserve
use "$regression_file", clear
keep hqcountry OECD_b80s
duplicates drop
tempfile country_oecd
save `country_oecd', replace
restore

rename hqcountry_1 hqcountry
merge m:1 hqcountry using `country_oecd'
rename OECD_b80s hqcountry1_OECD_b80s
rename hqcountry hqcountry_1
drop _merge
rename hqcountry_2 hqcountry
merge m:1 hqcountry using `country_oecd'
rename OECD_b80s hqcountry2_OECD_b80s
rename hqcountry hqcountry_2
drop _merge
drop if suitability_score_wdi==.

save "$TMP/regression_validation_countrypair_final.dta", replace
di as result "DONE regression_validation_countrypair_final -> intermediate_and_other_data"
