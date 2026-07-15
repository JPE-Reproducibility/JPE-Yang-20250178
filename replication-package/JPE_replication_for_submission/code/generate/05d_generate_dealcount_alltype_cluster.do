clear all
set more off
set maxvar 30000
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
global data_version "v2"
cap mkdir "$TMP"

use "$TMP/dealcount_$data_version.dta", clear
keep if year <=2019 & year >= 2015
bysort fullname year: egen dealcount_other = sum(count)

keep fullname year dealcount_china dealcount_us dealcount_other
duplicates drop
collapse (mean) dealcount_china dealcount_us dealcount_other, by(fullname)

gen ChinaPlusUSPlusOther = dealcount_us + dealcount_china + dealcount_other
gen share_china = dealcount_china/ChinaPlusUSPlusOther
gsort -share_china fullname

keep in 1/129
keep fullname share_china
rename share_china share_china_to_world
save "$TMP/china_led_subsegments_avg_loose_dealcount_to_world_$data_version.dta", replace
di as result "DONE (1) china_led_subsegments_avg_loose_dealcount_to_world_$data_version -> intermediate_and_other_data"

use "$CONFRAW/pitchbook/pbdeals.dta", clear
keep companyid dealid dealdate dealsize dealtype dealstatus
drop if dealstatus == "Failed/Cancelled"
gen year = ustrregexrf(dealdate,"\d\d\/\d\d\/","")
destring year, replace
drop if year ==.
keep if year < 2022 & year > 1999
drop dealdate
merge m:1 companyid using "$CONFRAW/pitchbook/pbcompanies.dta"
keep if _merge == 3
keep companyid dealid dealsize dealstatus dealtype year companyname description hqcountry
duplicates drop dealid, force

merge m:1 hqcountry using "$RAW/other_data_resource/hand_collected/OECD_list.dta"
drop _merge joinyear
replace OECD = 0 if OECD ==.
replace OECD_b80s=0 if OECD_b80s==.

drop if hqcountry == "China" | hqcountry == "United States"

merge m:1 companyid using "$CONFRAW/BERT_prediction_resource/company_level_predictions_$data_version.dta"
keep if _merge == 3

keep companyid fullname* hqcountry dealid dealsize dealstatus dealtype year
reshape long fullname,i(dealid) j(subseg)
drop if fullname == ""

merge m:1 hqcountry using "$RAW/other_data_resource/hand_collected/OECD_list.dta"
replace OECD = 0 if OECD ==.
replace OECD_b80s = 0 if OECD_b80s==.
drop joinyear _merge

gen fullname_raw = ustrregexra(fullname,"[^A-Za-z0-9]","")
replace fullname_raw = lower(fullname_raw)
drop if companyid == ""

gen count = 1
rename fullname subsegment
collapse (count) count (sum) dealsize, by(subsegment hqcountry year)
drop if hqcountry == ""

rename count dealcount_alltype
rename dealsize dealsize_alltype

fillin hqcountry subsegment year
replace dealcount_alltype = 0 if _fillin == 1
replace dealsize_alltype = 0 if _fillin == 1
drop _fillin

save "$TMP/dealcount_size_alltype.dta", replace
di as result "DONE (2) dealcount_size_alltype -> intermediate_and_other_data"

use "$TMP/deal_$data_version.dta", clear

fillin hqcountry fullname year
foreach v of varlist dealcount_y dealsize_y dealcount_y_us_inv dealcount_y_local_inv dealcount_y_china_inv dealcount_y_other_inv dealcount_y_us_inv_s dealcount_y_local_inv_s dealcount_y_china_inv_s dealcount_y_other_inv_s dealsize_y_us_inv_s dealsize_y_local_inv_s dealsize_y_china_inv_s dealsize_y_other_inv_s {
	replace `v' = 0 if _fillin == 1
}
keep fullname hqcountry year dealcount_y* dealsize_y* _fillin

merge m:1 hqcountry using "$RAW/other_data_resource/hand_collected/OECD_list.dta"
drop _merge joinyear
replace OECD = 0 if OECD ==.
replace OECD_b80s = 0 if OECD_b80s ==.

merge m:1 fullname year using "$TMP/china_us_dealcount_$data_version.dta"
replace dealcount_china = 0 if _merge == 1
replace dealcount_us = 0 if _merge == 1
drop if _merge == 2
drop _merge
merge m:1 fullname year using "$TMP/china_us_dealsize_$data_version.dta"
replace dealsize_china = 0 if _merge == 1
replace dealsize_us = 0 if _merge == 1
drop if _merge == 2
drop _merge
drop _fillin
drop if fullname == ""

merge m:1 fullname using "$TMP/china_led_subsegments_avg_strict_dealcount_$data_version.dta"
gen china_led_dealcountavg_strict = _merge
drop _merge
replace china_led_dealcountavg_strict = 0 if china_led_dealcountavg_strict == 1
replace china_led_dealcountavg_strict = 1 if china_led_dealcountavg_strict == 3
merge m:1 fullname using "$TMP/china_led_subsegments_avg_loose_dealcount_$data_version.dta"
gen china_led_dealcountavg_loose = _merge
drop _merge
replace china_led_dealcountavg_loose = 0 if china_led_dealcountavg_loose == 1
replace china_led_dealcountavg_loose = 1 if china_led_dealcountavg_loose == 3
drop share_china ChinaPlusUS

rename fullname subsegment
encode hqcountry, gen(hq)
encode subsegment, gen(subseg)

gen suitability_score2 = .

save "$TMP/regression_2000_2021.dta", replace
di as result "DONE (3) regression_2000_2021 -> intermediate_and_other_data"
