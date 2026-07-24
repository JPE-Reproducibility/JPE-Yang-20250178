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

capture log close
log using "$LOG_DIR/tableA4.log", replace text

local file1 "china_suitability_score_all_corrected.dta"
local file2 "china_suitability_score_all_from_existing_no_trade2.dta"
local file3 "china_suitability_score_all_from_scratch_allassigned.dta"
local file4 "china_suitability_score_all_gpt_assigned.dta"

local _missing = 0
foreach f in `file1' `file2' `file3' `file4' {
	capture confirm file "$suit_output_folder/`f'"
	if _rc != 0 {
		display as error "Table A4: missing $suit_output_folder/`f'"
		local _missing = 1
	}
}

if `_missing' == 0 {
	cd "$suit_output_folder"

	use `"`file1'"', clear
	gen measure_label = "Baseline"
	keep country_2digit relative_to hqcountry *_SuitSc measure_label
	tempfile m1
	save `m1', replace

	use `"`file2'"', clear
	gen measure_label = "Restricted"
	keep country_2digit relative_to hqcountry *_SuitSc measure_label
	tempfile m2
	save `m2', replace

	use `"`file4'"', clear
	gen measure_label = "GPTAssigned"
	keep country_2digit relative_to hqcountry *_SuitSc measure_label
	tempfile m3
	save `m3', replace

	use `"`file3'"', clear
	gen measure_label = "AllAssigned"
	keep country_2digit relative_to hqcountry *_SuitSc measure_label

	append using `m1'
	append using `m2'
	append using `m3'

	rename *_SuitSc Suit_*
	reshape long Suit_, i(country_2digit relative_to hqcountry measure_label) j(sector) string
	rename Suit_ SuitabilityScore
	reshape wide SuitabilityScore, i(country_2digit relative_to hqcountry sector) j(measure_label) string

	corr SuitabilityScoreBaseline SuitabilityScoreRestricted SuitabilityScoreAllAssigned SuitabilityScoreGPTAssigned
	matrix C = r(C)
	matrix rownames C = "Baseline" "Restricted" "All Assigned" "GPT Assigned"
	matrix colnames C = "Baseline" "Restricted" "All Assigned" "GPT Assigned"
	esttab matrix(C, fmt(3)) using "$TABLE_DIR/tableA4.csv", replace csv ///
		title("Correlation Matrix of Appropriateness Measures") label
}

log close
