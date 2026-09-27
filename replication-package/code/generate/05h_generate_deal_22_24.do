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
global TMP   "$ROOT/confidential-data-not-for-publication/Analysis/intermediate_and_other_data"
cap mkdir "$TMP"
cap mkdir "$ROOT/confidential-data-not-for-publication"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global OUT   "$ROOT/confidential-data-not-for-publication/Analysis"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global BUILD "$TMP/a11cd_build"
global EXTCSV "$CONFRAW/pitchbook/later_years_extension/All_VC_Comp_Deal_Investor_2022-2024.csv"
cap mkdir "$BUILD"

insheet using "$CONFRAW/pitchbook/pbmarketmap_v2.csv", names clear
rename mapname marketmap
gen fullname = marketmap + "|" + segment + "|" + subsegment
save "$BUILD/pbmarketmap_v2.dta", replace
count
di as result "DONE stage0 pbmarketmap_v2 (rows above)"

insheet using "$EXTCSV", names clear
rename descriptionx description_inv
rename hqcountryx hqcountry_inv
rename yearfoundedx yearfounded_inv
rename companynamex companyname_inv
rename descriptiony description
rename hqcountryy hqcountry
rename yearfoundedy yearfounded
rename companynamey companyname
keep companyid dealid investorid dealdate dealsize dealtype dealstatus companyname description hqcountry hqcountry_inv
save "$BUILD/ext_22_24_renamed.dta", replace
count
di as result "DONE stage1 ext_22_24_renamed (raw rows above)"

use "$BUILD/ext_22_24_renamed.dta", clear
duplicates drop dealid, force
keep companyid dealid dealdate dealsize dealtype dealstatus companyname description hqcountry
destring dealsize, replace force
drop if dealstatus == "Failed/Cancelled"
gen year = ustrregexs(1) if ustrregexm(dealdate, "(\d\d\d\d)\-\d\d-\d\d")
destring year, replace
drop if year ==.
drop dealdate
keep if  dealtype == "Early Stage VC" | dealtype=="Later Stage VC"

merge m:1 hqcountry using "$RAW/other_data_resource/hand_collected/OECD_list"
drop _merge joinyear
replace OECD = 0 if OECD ==.
replace OECD_b80s=0 if OECD_b80s==.

replace OECD = . if hqcountry == "China" | hqcountry == "United States"
replace OECD_b80s = . if hqcountry == "China" | hqcountry == "United States"

drop if companyid == ""
save "$BUILD/pbdeals_vc_22_24.dta", replace
count
di as result "DONE stage2 pbdeals_vc_22_24 (VC 22-24 deals above)"

insheet using "$CONFRAW/pitchbook/later_years_extension/pbmarketmap_22_24.csv", names clear
rename fullname fullname_raw
save "$BUILD/pbmarketmap_22_24.dta", replace

use "$BUILD/pbmarketmap_v2", clear
drop companyid description
duplicates drop
gen fullname_raw = ustrregexra(fullname,"[^A-Za-z0-9]","")
replace fullname_raw = lower(fullname_raw)
merge 1:m fullname_raw using "$BUILD/pbmarketmap_22_24"
drop if _merge == 1
drop _merge

bysort companyid: gen num_subseg = _n
keep companyid fullname num_subseg
reshape wide fullname, i(companyid) j(num_subseg)
rename fullname* fullname*_
forvalues i=1/13{
	split fullname`i'_, p(|)
}
rename fullname*_1 marketmap*
rename fullname*_2 segment*
rename fullname*_3 subsegment*
rename fullname*_ fullname*
save "$BUILD/company_level_predictions_22_24", replace
count
di as result "DONE stage3 company_level_predictions_22_24 (22-24 companies above)"

use "$CONFRAW/BERT_prediction_resource/company_level_predictions_v2", clear
drop hqcountry
append using "$BUILD/company_level_predictions_22_24"
save "$BUILD/all_company_level_predictions", replace
count
di as result "DONE stage4 all_company_level_predictions (rows above)"

use "$BUILD/all_company_level_predictions", clear
merge 1:m companyid using "$BUILD/pbdeals_vc_22_24"
keep if _merge == 3

keep companyid fullname* hqcountry dealid dealsize dealstatus dealtype year
reshape long fullname,i(dealid) j(subseg)
drop if fullname == ""

merge m:1 hqcountry using "$RAW/other_data_resource/hand_collected/OECD_list"
replace OECD = 0 if OECD ==.
replace OECD_b80s = 0 if OECD_b80s==.
drop joinyear _merge

keep if hqcountry !=""
drop if companyid == ""
drop subseg
save "$BUILD/analysis_22_24.dta", replace
count
di as result "DONE stage5 analysis_22_24 (deal x sector rows above)"

use "$BUILD/ext_22_24_renamed.dta", clear
duplicates drop investorid dealid, force
destring dealsize, replace force
drop if dealstatus == "Failed/Cancelled"
gen year = ustrregexs(1) if ustrregexm(dealdate, "(\d\d\d\d)\-\d\d-\d\d")
destring year, replace
drop if year ==.
drop dealdate
keep if  dealtype == "Early Stage VC" | dealtype=="Later Stage VC"

keep  year companyid hqcountry dealid investorid hqcountry_inv  dealsize   companyname

gen china_inv_t = 0
gen us_inv_t = 0
gen local_inv_t = 0
gen other_inv_t = 0
replace china_inv_t = 1 if hqcountry_inv=="China"
replace us_inv_t = 1 if hqcountry_inv=="United States"
replace local_inv_t = 1 if hqcountry_inv == hqcountry
replace other_inv_t = 1 if hqcountry_inv != "China" & hqcountry_inv != "United States" & hqcountry_inv != hqcountry

bysort dealid: gen count_inv = _N
label var count_inv "Total number of investors"
foreach i of varlist china_inv_t us_inv_t local_inv_t other_inv_t{
	gen `i'_contrib = `i'/count_inv
}

bysort dealid: egen china_inv = max(china_inv_t)
bysort dealid: egen us_inv = max(us_inv_t)
bysort dealid: egen local_inv = max(local_inv_t)
bysort dealid: egen other_inv = max(other_inv_t)

bysort dealid: egen china_inv_s = sum(china_inv_t_contrib)
bysort dealid: egen us_inv_s = sum(us_inv_t_contrib)
bysort dealid: egen local_inv_s = sum(local_inv_t_contrib)
bysort dealid: egen other_inv_s = sum(other_inv_t_contrib)

drop *_t *_contrib investorid hqcountry_inv
duplicates drop dealid, force

gen dealsize_y_us_inv_s = dealsize*us_inv_s
gen dealsize_y_china_inv_s = dealsize*china_inv_s
gen dealsize_y_local_inv_s = dealsize*local_inv_s
gen dealsize_y_other_inv_s = dealsize*other_inv_s
save "$BUILD/investor_origin_22_24.dta", replace
count
di as result "DONE stage6 investor_origin_22_24 (deal-level rows above)"

use "$BUILD/analysis_22_24", clear
drop if hqcountry == "China" | hqcountry == "United States"

merge m:1 dealid using "$BUILD/investor_origin_22_24"
drop if _merge == 2
drop if dealid ==""
drop _merge

gen count =1
collapse (sum) count dealsize china_inv us_inv local_inv other_inv china_inv_s us_inv_s local_inv_s other_inv_s dealsize_y_us_inv_s dealsize_y_china_inv_s dealsize_y_local_inv_s dealsize_y_other_inv_s, by(hqcountry fullname year OECD OECD_b80s)

rename count dealcount_y
rename dealsize dealsize_y
rename us_inv dealcount_y_us_inv
rename local_inv dealcount_y_local_inv
rename china_inv dealcount_y_china_inv
rename other_inv dealcount_y_other_inv

rename us_inv_s dealcount_y_us_inv_s
rename local_inv_s dealcount_y_local_inv_s
rename china_inv_s dealcount_y_china_inv_s
rename other_inv_s dealcount_y_other_inv_s

drop if hqcountry == ""
drop if fullname == ""
save "$BUILD/deal_22_24", replace
count
tab year
di as result "DONE stage7 deal_22_24 -> $BUILD/deal_22_24.dta"
